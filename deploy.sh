#!/bin/bash

# Deployment script for Expense Management System Infrastructure
# Following prompt-006 requirements for one-line deployment

set -e

echo "=================================="
echo "Expense Management System Deployment"
echo "=================================="

# Variables
RESOURCE_GROUP="rg-expense-mgmt-dev"
LOCATION="uksouth"
DEPLOYMENT_NAME="expense-mgmt-deployment-$(date +%Y%m%d-%H%M%S)"

# Get current user information for SQL admin
echo "Getting current user information..."
ADMIN_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
ADMIN_LOGIN=$(az ad signed-in-user show --query userPrincipalName -o tsv)

echo "Admin Object ID: $ADMIN_OBJECT_ID"
echo "Admin Login: $ADMIN_LOGIN"

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy infrastructure
echo "Deploying infrastructure..."
az deployment group create \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --template-file infrastructure/main.bicep \
  --parameters adminObjectId=$ADMIN_OBJECT_ID adminLogin=$ADMIN_LOGIN

# Get outputs
echo "Retrieving deployment outputs..."
SQL_SERVER=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.sqlServerFqdn.value -o tsv)
DATABASE_NAME=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.databaseName.value -o tsv)
APP_SERVICE_NAME=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.appServiceName.value -o tsv)
APP_SERVICE_URL=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.appServiceUrl.value -o tsv)
CONNECTION_STRING=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.connectionString.value -o tsv)
MANAGED_IDENTITY_CLIENT_ID=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.managedIdentityClientId.value -o tsv)
MANAGED_IDENTITY_NAME=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.managedIdentityName.value -o tsv)

echo ""
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "App Service: $APP_SERVICE_NAME"
echo "App Service URL: $APP_SERVICE_URL"
echo "SQL Server: $SQL_SERVER"
echo "Database: $DATABASE_NAME"
echo "Managed Identity: $MANAGED_IDENTITY_NAME"
echo ""

# Import database schema
echo "Importing database schema..."
SQL_SERVER_NAME=$(echo $SQL_SERVER | cut -d'.' -f1)

# Wait for SQL server to be ready
echo "Waiting for SQL server to be ready..."
sleep 30

# Execute the schema import
echo "Executing SQL schema..."
az sql db query \
  --server $SQL_SERVER_NAME \
  --database $DATABASE_NAME \
  --auth-mode ActiveDirectoryIntegrated \
  --query-file Database-Schema/database_schema.sql || {
    echo "Warning: Schema import failed. You may need to import manually."
    echo "Command: az sql db query --server $SQL_SERVER_NAME --database $DATABASE_NAME --auth-mode ActiveDirectoryIntegrated --query-file Database-Schema/database_schema.sql"
  }

# Grant managed identity access to database
echo "Granting managed identity access to database..."
GRANT_SQL="CREATE USER [${MANAGED_IDENTITY_NAME}] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [${MANAGED_IDENTITY_NAME}];
ALTER ROLE db_datawriter ADD MEMBER [${MANAGED_IDENTITY_NAME}];
ALTER ROLE db_ddladmin ADD MEMBER [${MANAGED_IDENTITY_NAME}];"

echo "$GRANT_SQL" | az sql db query \
  --server $SQL_SERVER_NAME \
  --database $DATABASE_NAME \
  --auth-mode ActiveDirectoryIntegrated || {
    echo "Warning: Managed identity permission grant failed. You may need to grant manually."
    echo "SQL Command:"
    echo "$GRANT_SQL"
  }

# Configure App Service settings
echo "Configuring App Service settings..."
az webapp config appsettings set \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "SQL_CONNECTION_STRING=$CONNECTION_STRING" \
    "MANAGED_IDENTITY_CLIENT_ID=$MANAGED_IDENTITY_CLIENT_ID"

echo ""
echo "=================================="
echo "Next Steps:"
echo "=================================="
echo "1. Deploy application code: cd src && npm install && npm run build"
echo "2. Deploy to App Service: az webapp deployment source config-zip --src app.zip --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo "3. Visit your app: $APP_SERVICE_URL"
echo ""
echo "Connection String saved to App Service configuration."
echo "=================================="
