# Expense Management System - Modernized Azure Application

A modern expense management system deployed on Azure using App Service, Azure SQL Database, and Managed Identity authentication. This application replaces legacy desktop expense tracking with a cloud-native web application.

## Features

- 📝 **Add Expenses**: Submit new expense claims with amount, date, category, and description
- ✅ **Approve Expenses**: Managers can review and approve pending expenses
- 📊 **View Expenses**: Track all expenses with filtering by status, category, and date
- 🔐 **Secure Authentication**: Azure AD-only authentication with Managed Identity
- 💾 **Resilient Design**: Automatic fallback to dummy data if database is unavailable
- 🎨 **Classic UI**: Maintains familiar interface from legacy system

## Architecture

### Azure Resources
- **App Service**: B1 Basic tier (Linux, Node.js 20 LTS)
- **Azure SQL Database**: Basic tier with Entra ID authentication
- **User-Assigned Managed Identity**: Secure database access without credentials
- **Resource Group**: All resources in UK South region

### Technology Stack
- **Backend**: Node.js with Express.js
- **Database**: Azure SQL Database (T-SQL)
- **Authentication**: Azure Managed Identity
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **IaC**: Bicep for infrastructure as code

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- Azure subscription with appropriate permissions
- Git

## Quick Start Deployment

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd AMA-Fri-15-18-Firewall
```

### 2. Deploy Infrastructure
The deployment script will:
- Create resource group
- Deploy App Service with Managed Identity
- Deploy Azure SQL Database with Entra ID authentication
- Import database schema
- Configure application settings

```bash
./deploy.sh
```

**Note**: The script will automatically use your Azure AD credentials for SQL admin access.

### 3. Deploy Application Code
```bash
cd src
npm install
```

Create a deployment package:
```bash
cd src
zip -r ../app.zip . -x "node_modules/*"
```

Deploy to App Service (replace variables with output from deploy.sh):
```bash
az webapp deployment source config-zip \
  --src app.zip \
  --name <APP_SERVICE_NAME> \
  --resource-group rg-expense-mgmt-dev
```

### 4. Access Your Application
Visit the URL provided in the deployment output (e.g., `https://app-expense-mgmt-xyz.azurewebsites.net`)

## Infrastructure Details

### Security & Compliance
- ✅ **Azure AD-Only Authentication**: Complies with MCAPS governance policy [SFI-ID4.2.2]
- ✅ **No SQL Authentication**: SQL logins disabled entirely
- ✅ **Managed Identity**: No connection strings with passwords
- ✅ **HTTPS Only**: All traffic encrypted with TLS 1.2+
- ✅ **Azure Service Access**: Firewall configured for Azure internal traffic

### Database Schema
The system uses a normalized schema with:
- **Users**: Employee and Manager roles
- **Expenses**: Tracks amounts in pence to avoid floating-point issues
- **ExpenseCategories**: Travel, Meals, Supplies, Accommodation, Other
- **ExpenseStatus**: Draft, Submitted, Approved, Rejected

## Manual Deployment Steps

If the automated script fails, follow these manual steps:

### 1. Set Variables
```bash
RG="rg-expense-mgmt-dev"
LOCATION="uksouth"
ADMIN_OID=$(az ad signed-in-user show --query id -o tsv)
ADMIN_UPN=$(az ad signed-in-user show --query userPrincipalName -o tsv)
```

### 2. Create Resource Group
```bash
az group create --name $RG --location $LOCATION
```

### 3. Deploy Bicep Template
```bash
az deployment group create \
  --name expense-mgmt-deployment \
  --resource-group $RG \
  --template-file infrastructure/main.bicep \
  --parameters adminObjectId=$ADMIN_OID adminLogin=$ADMIN_UPN
```

### 4. Import Database Schema
```bash
SQL_SERVER_NAME=<from-bicep-output>
az sql db query \
  --server $SQL_SERVER_NAME \
  --database Northwind \
  --auth-mode ActiveDirectoryIntegrated \
  --query-file Database-Schema/database_schema.sql
```

### 5. Grant Managed Identity Permissions
```bash
MI_NAME=<from-bicep-output>
az sql db query \
  --server $SQL_SERVER_NAME \
  --database Northwind \
  --auth-mode ActiveDirectoryIntegrated \
  --query "CREATE USER [$MI_NAME] FROM EXTERNAL PROVIDER; ALTER ROLE db_datareader ADD MEMBER [$MI_NAME]; ALTER ROLE db_datawriter ADD MEMBER [$MI_NAME];"
```

## Error Handling

The application includes comprehensive error handling:

### Database Connection Errors
- **Error Banner**: Displays at top of page with detailed error message
- **Location Reference**: Shows which file and function encountered the error
- **Dummy Data Fallback**: Application remains functional with sample data
- **No Code Exposure**: Error messages never reveal application code

### Example Error Display
```
⚠️ Database Connection Error
SQL_CONNECTION_STRING environment variable not set
Location: db.js:initializeConnection
```

## Development

### Local Development
```bash
cd src
npm install
npm run dev
```

Set environment variables:
```bash
export SQL_CONNECTION_STRING="Server=tcp:...;Database=...;"
export MANAGED_IDENTITY_CLIENT_ID="<client-id>"
```

### API Endpoints
- `GET /api/expenses` - List all expenses
- `GET /api/expenses/pending` - List pending expenses for approval
- `GET /api/categories` - List expense categories
- `POST /api/expenses` - Create new expense
- `POST /api/expenses/:id/submit` - Submit expense for approval
- `POST /api/expenses/:id/approve` - Approve expense
- `GET /api/health` - Health check endpoint

## Monitoring & Troubleshooting

### Check Application Logs
```bash
az webapp log tail --name <APP_SERVICE_NAME> --resource-group rg-expense-mgmt-dev
```

### Test Database Connection
```bash
az sql db show-connection-string \
  --server <SQL_SERVER_NAME> \
  --name Northwind \
  --client ado.net
```

### Verify Managed Identity
```bash
az webapp identity show \
  --name <APP_SERVICE_NAME> \
  --resource-group rg-expense-mgmt-dev
```

## Cost Optimization

Current configuration uses lowest-cost development SKUs:
- **App Service**: B1 Basic (~£10/month)
- **Azure SQL Database**: Basic tier (~£4/month)
- **Total Estimated Cost**: ~£14/month

## Azure Best Practices Applied

Following guidance from microsoft.com:

1. ✅ **Managed Identities**: No credential management required
2. ✅ **Azure AD Authentication**: Centralized identity management
3. ✅ **Infrastructure as Code**: Bicep templates for repeatability
4. ✅ **HTTPS Only**: Secure communication enforced
5. ✅ **Minimal Privileges**: Managed Identity has only required database permissions
6. ✅ **Regional Deployment**: All resources in single region (UK South)
7. ✅ **Tag Management**: Resources tagged for cost tracking
8. ✅ **Network Security**: Firewall rules for Azure services only

## Troubleshooting

### Issue: Database connection fails
**Solution**: Verify managed identity has been granted database access. Run the grant SQL commands manually.

### Issue: Schema import fails
**Solution**: Import manually using Azure Data Studio or SQL Server Management Studio with Azure AD authentication.

### Issue: App Service shows "Service Unavailable"
**Solution**: Check application logs and ensure environment variables are set correctly.

## Support

For issues or questions:
1. Check application logs in Azure Portal
2. Review error banner messages in the UI
3. Verify all Azure resources are deployed correctly
4. Ensure managed identity permissions are configured

## License

MIT License - See LICENSE file for details.
