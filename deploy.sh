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

# Configure database using PowerShell script
echo "Configuring database (schema import and managed identity permissions)..."
powershell.exe -ExecutionPolicy Bypass -File configure-database.ps1 \
  -SqlServer "$SQL_SERVER" \
  -DatabaseName "$DATABASE_NAME" \
  -ManagedIdentityName "$MANAGED_IDENTITY_NAME" \
  -SchemaFile "Database-Schema/database_schema.sql" || {
    echo "Warning: Database configuration failed. You may need to configure manually."
    echo "Manual configuration command:"
    echo "powershell.exe -ExecutionPolicy Bypass -File configure-database.ps1 -SqlServer $SQL_SERVER -DatabaseName $DATABASE_NAME -ManagedIdentityName $MANAGED_IDENTITY_NAME -SchemaFile Database-Schema/database_schema.sql"
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
echo "1. Deploy application code:"
echo "   ./deploy-app.sh $APP_SERVICE_NAME $RESOURCE_GROUP"
echo ""
echo "2. Visit your app: $APP_SERVICE_URL"
echo ""
echo "3. View logs:"
echo "   az webapp log tail --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "4. Check health:"
echo "   curl $APP_SERVICE_URL/api/health"
echo ""
echo "=================================="
