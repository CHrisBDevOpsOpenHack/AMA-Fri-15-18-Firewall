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

# Configure database using PowerShell script if available
if command -v powershell.exe &> /dev/null && [ -f "configure-database.ps1" ]; then
    echo "Configuring database using PowerShell script..."
    powershell.exe -ExecutionPolicy Bypass -File configure-database.ps1 \
      -SqlServer "$SQL_SERVER" \
      -DatabaseName "$DATABASE_NAME" \
      -ManagedIdentityName "$MANAGED_IDENTITY_NAME" \
      -SchemaFile "Database-Schema/database_schema.sql" || {
        echo "Warning: PowerShell database configuration failed. Trying Python method..."
    }
fi

# Try Python-based SQL configuration (cross-platform)
echo "Installing Python dependencies..."
pip3 install --quiet pyodbc azure-identity 2>/dev/null || echo "Warning: Failed to install Python packages"

echo "Configuring database and managed identity permissions..."
# Update script.sql with the managed identity name
sed -i.bak "s/MANAGED-IDENTITY-NAME/$MANAGED_IDENTITY_NAME/g" script.sql && rm -f script.sql.bak

# Run Python script to grant permissions
python3 run-sql.py "$SQL_SERVER" "$DATABASE_NAME" "Database-Schema/database_schema.sql" || {
    echo "Warning: Database schema import failed."
}

# Grant managed identity permissions
python3 run-sql.py "$SQL_SERVER" "$DATABASE_NAME" "script.sql" || {
    echo "Warning: Managed identity permission grant failed."
}

# Restore the template
git checkout script.sql 2>/dev/null || true

# Configure App Service settings
echo "Configuring App Service settings..."
az webapp config appsettings set \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "SQL_CONNECTION_STRING=$CONNECTION_STRING" \
    "MANAGED_IDENTITY_CLIENT_ID=$MANAGED_IDENTITY_CLIENT_ID"

# Build and deploy the C# application
echo "Building C# application..."
cd src-csharp
dotnet publish -c Release -o ../publish

echo "Creating deployment package..."
cd ../publish
zip -r ../app.zip . -x "*.pdb" > /dev/null
cd ..

echo "Deploying application to Azure..."
az webapp deploy \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_NAME \
  --src-path ./app.zip \
  --type zip

echo ""
echo "=================================="
echo "Deployment Successful!"
echo "=================================="
echo ""
echo "Application URL: $APP_SERVICE_URL"
echo "  - Main page: $APP_SERVICE_URL/"
echo "  - API Docs: $APP_SERVICE_URL/swagger"
echo "  - Health Check: $APP_SERVICE_URL/api/health"
echo ""
echo "View logs:"
echo "  az webapp log tail --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "=================================="
