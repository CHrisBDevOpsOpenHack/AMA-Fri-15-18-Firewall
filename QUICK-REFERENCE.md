# Quick Reference Guide

## One-Line Deployment

```bash
./deploy.sh
```

That's it! This single command will:
1. Create Azure resource group
2. Deploy all infrastructure (App Service, SQL DB, Managed Identity)
3. Import database schema
4. Configure app settings
5. Display your app URL

## Prerequisites

```bash
az login
az account set --subscription <subscription-id>
```

## Manual Deployment (if script fails)

### Step 1: Infrastructure
```bash
RG="rg-expense-mgmt-dev"
LOCATION="uksouth"
ADMIN_OID=$(az ad signed-in-user show --query id -o tsv)
ADMIN_UPN=$(az ad signed-in-user show --query userPrincipalName -o tsv)

az group create --name $RG --location $LOCATION

az deployment group create \
  --name expense-mgmt-deployment \
  --resource-group $RG \
  --template-file infrastructure/main.bicep \
  --parameters adminObjectId=$ADMIN_OID adminLogin=$ADMIN_UPN
```

### Step 2: Get Outputs
```bash
SQL_SERVER=$(az deployment group show --name expense-mgmt-deployment --resource-group $RG --query properties.outputs.sqlServerFqdn.value -o tsv | cut -d'.' -f1)
DB_NAME=$(az deployment group show --name expense-mgmt-deployment --resource-group $RG --query properties.outputs.databaseName.value -o tsv)
MI_NAME=$(az deployment group show --name expense-mgmt-deployment --resource-group $RG --query properties.outputs.managedIdentityName.value -o tsv)
```

### Step 3: Import Schema
```bash
az sql db query \
  --server $SQL_SERVER \
  --database $DB_NAME \
  --auth-mode ActiveDirectoryIntegrated \
  --query-file Database-Schema/database_schema.sql
```

### Step 4: Grant Managed Identity Access
```bash
az sql db query \
  --server $SQL_SERVER \
  --database $DB_NAME \
  --auth-mode ActiveDirectoryIntegrated \
  --query "CREATE USER [$MI_NAME] FROM EXTERNAL PROVIDER; ALTER ROLE db_datareader ADD MEMBER [$MI_NAME]; ALTER ROLE db_datawriter ADD MEMBER [$MI_NAME];"
```

### Step 5: Deploy Application
```bash
APP_NAME=$(az deployment group show --name expense-mgmt-deployment --resource-group $RG --query properties.outputs.appServiceName.value -o tsv)

cd src
npm install --production
cd ..
zip -r app.zip src -x "src/node_modules/.cache/*"

az webapp deployment source config-zip \
  --src app.zip \
  --name $APP_NAME \
  --resource-group $RG
```

## Troubleshooting

### View Logs
```bash
az webapp log tail --name <app-name> --resource-group rg-expense-mgmt-dev
```

### Check Health
```bash
curl https://<app-name>.azurewebsites.net/api/health
```

### Restart App
```bash
az webapp restart --name <app-name> --resource-group rg-expense-mgmt-dev
```

### Delete Everything
```bash
az group delete --name rg-expense-mgmt-dev --yes
```

## Environment Variables (App Service)

These are automatically set by deploy.sh:
- `SQL_CONNECTION_STRING` - Database connection with managed identity
- `MANAGED_IDENTITY_CLIENT_ID` - Client ID for authentication

## Application URLs

- **Home**: `/` - View all expenses
- **Add**: `/add` - Create new expense
- **Approve**: `/approve` - Approve pending expenses

## API Endpoints

- `GET /api/expenses` - All expenses
- `GET /api/expenses/pending` - Pending approvals
- `GET /api/categories` - Expense categories
- `POST /api/expenses` - Create expense
- `POST /api/expenses/:id/approve` - Approve expense
- `GET /api/health` - Health check

## Cost Estimate

- App Service B1: ~£10/month
- SQL Database Basic: ~£4/month
- **Total: ~£14/month**

## Security Features

✅ Azure AD-only authentication (MCAPS compliant)  
✅ Managed Identity (no passwords)  
✅ HTTPS enforced  
✅ Rate limiting (100 API calls, 500 pages per 15 min)  
✅ SQL injection protection via parameterized queries  
✅ No code exposure in error messages

## Support

- Check logs first
- Review error banner in UI
- Verify managed identity permissions
- Ensure all environment variables are set
