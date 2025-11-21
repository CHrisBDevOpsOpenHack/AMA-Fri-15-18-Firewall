#!/bin/bash
set -e

echo "Starting SQL schema import and managed identity configuration..."
echo "SQL Server: $SQL_SERVER"
echo "Database: $DATABASE_NAME"
echo "Managed Identity: $MANAGED_IDENTITY_NAME"

# Install sqlcmd using modern apt method (avoiding deprecated apt-key)
echo "Installing sqlcmd..."
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev

# Add sqlcmd to PATH
export PATH="$PATH:/opt/mssql-tools18/bin"

# Get Azure AD access token - use SQL_RESOURCE_URL from environment
echo "Getting Azure AD access token..."
TOKEN=$(az account get-access-token --resource https://${SQL_RESOURCE_URL}/ --query accessToken -o tsv)

# Wait for SQL server to be ready with retry mechanism
echo "Waiting for SQL server to be ready..."
MAX_RETRIES=10
RETRY_COUNT=0
RETRY_DELAY=15

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if /opt/mssql-tools18/bin/sqlcmd -S $SQL_SERVER -d $DATABASE_NAME -G -P $TOKEN -C -b -Q "SELECT 1" > /dev/null 2>&1; then
    echo "SQL server is ready!"
    break
  fi
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "SQL server not ready yet. Retrying in ${RETRY_DELAY} seconds... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep $RETRY_DELAY
  else
    echo "Error: SQL server failed to become ready after $MAX_RETRIES attempts"
    exit 1
  fi
done

# Test connection
echo "Testing connection to SQL server..."
/opt/mssql-tools18/bin/sqlcmd -S $SQL_SERVER -d $DATABASE_NAME -G -P $TOKEN -C -b -Q "SELECT @@VERSION" || {
  echo "Error: Failed to connect to SQL server"
  exit 1
}

# Create schema SQL file from environment variable
echo "Creating schema SQL file..."
echo "$SCHEMA_CONTENT" > /tmp/schema.sql

# Import schema
echo "Importing database schema..."
/opt/mssql-tools18/bin/sqlcmd -S $SQL_SERVER -d $DATABASE_NAME -G -P $TOKEN -C -b -i /tmp/schema.sql || {
  echo "Error: Failed to import schema"
  exit 1
}
echo "Schema imported successfully!"

# Grant managed identity permissions
echo "Granting managed identity permissions..."
/opt/mssql-tools18/bin/sqlcmd -S $SQL_SERVER -d $DATABASE_NAME -G -P $TOKEN -C -b -Q "
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$MANAGED_IDENTITY_NAME')
BEGIN
    CREATE USER [$MANAGED_IDENTITY_NAME] FROM EXTERNAL PROVIDER;
END

ALTER ROLE db_datareader ADD MEMBER [$MANAGED_IDENTITY_NAME];
ALTER ROLE db_datawriter ADD MEMBER [$MANAGED_IDENTITY_NAME];
ALTER ROLE db_ddladmin ADD MEMBER [$MANAGED_IDENTITY_NAME];
" || {
  echo "Error: Failed to grant permissions"
  exit 1
}
echo "Managed identity permissions granted successfully!"

echo "Database configuration completed successfully!"
