#!/bin/bash

# Enhanced Deployment script with GenAI Services
# This deploys everything including Azure OpenAI and AI Search for the Chat UI

set -e

echo "=================================="
echo "Expense Management System - Full Deployment with GenAI"
echo "=================================="

# First run the base deployment
echo "Running base infrastructure deployment..."
./deploy.sh

# Get the deployment outputs
RESOURCE_GROUP="rg-expense-mgmt-dev"
LOCATION="uksouth"
DEPLOYMENT_NAME=$(az deployment group list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)

APP_SERVICE_NAME=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.appServiceName.value -o tsv)
MANAGED_IDENTITY_PRINCIPAL_ID=$(az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP --query properties.outputs.managedIdentityPrincipalId.value -o tsv)

echo ""
echo "=================================="
echo "Deploying GenAI Services..."
echo "=================================="
echo ""
echo "NOTE: This deployment creates:"
echo "  - Azure OpenAI Service (S0 SKU) in Sweden Central"
echo "  - GPT-4o model deployment"
echo "  - Azure AI Search (S0 SKU) for RAG"
echo ""
echo "Estimated additional cost: ~£190/month"
echo ""

# Create unique names
OPENAI_NAME="oai-expense-mgmt-${RANDOM}"
SEARCH_NAME="srch-expense-mgmt-${RANDOM}"

# TODO: Create genai.bicep with Azure OpenAI and AI Search resources
# TODO: Grant Managed Identity "Cognitive Services OpenAI User" role
# TODO: Grant Managed Identity "Search Service Contributor" role

echo "⚠️  GenAI infrastructure deployment is not yet implemented."
echo ""
echo "To complete this feature, the following files need to be created:"
echo "  1. infrastructure/genai.bicep - Azure OpenAI and AI Search resources"
echo "  2. Enhanced Chat UI with actual AI integration"
echo "  3. Function calling implementation for expense operations"
echo "  4. RAG document indexing for expense policies"
echo ""
echo "Current Status:"
echo "  ✅ Base infrastructure deployed"
echo "  ✅ App Service running ASP.NET Core 8.0"
echo "  ✅ Azure SQL Database with managed identity"
echo "  ✅ Chat UI page with basic functionality"
echo "  ⚠️  Azure OpenAI integration pending"
echo "  ⚠️  AI Search/RAG implementation pending"
echo ""
echo "The Chat page will work with limited functionality showing helpful"
echo "messages about how to use the application."
echo ""
echo "=================================="
