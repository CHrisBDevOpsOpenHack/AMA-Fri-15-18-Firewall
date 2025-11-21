#!/bin/bash

# Script to package and deploy application to Azure App Service

set -e

echo "=================================="
echo "Application Deployment Script"
echo "=================================="

if [ -z "$1" ]; then
  echo "Usage: ./deploy-app.sh <APP_SERVICE_NAME> [RESOURCE_GROUP]"
  echo "Example: ./deploy-app.sh app-expense-mgmt-abc123 rg-expense-mgmt-dev"
  exit 1
fi

APP_SERVICE_NAME=$1
RESOURCE_GROUP=${2:-"rg-expense-mgmt-dev"}

echo "App Service: $APP_SERVICE_NAME"
echo "Resource Group: $RESOURCE_GROUP"
echo ""

# Navigate to src directory
cd src

# Install dependencies
echo "Installing dependencies..."
npm install --production

# Create deployment package
echo "Creating deployment package..."
rm -f ../app.zip
zip -r ../app.zip . -x "*.git*" -x "*node_modules/.cache*"

cd ..

# Deploy to Azure
echo "Deploying to Azure App Service..."
az webapp deployment source config-zip \
  --src app.zip \
  --name $APP_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP

echo ""
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo "Your app should be available at:"
echo "https://${APP_SERVICE_NAME}.azurewebsites.net"
echo ""
echo "View logs: az webapp log tail --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo "=================================="
