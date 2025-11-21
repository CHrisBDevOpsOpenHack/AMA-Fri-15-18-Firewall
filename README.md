![Header image](https://github.com/DougChisholm/App-Mod-Assist/blob/main/repo-header.png)

# Expense Management System - Modernized

A modern expense management system demonstrating how to modernize legacy desktop applications into cloud-native Azure web applications using GitHub Copilot.

## 🚀 Quick Start

1. **Fork and Clone this repo**
   ```bash
   git clone <your-forked-repo>
   cd AMA-Fri-15-18-Firewall
   ```

2. **Login to Azure**
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

3. **Deploy Infrastructure and Application**
   ```bash
   ./deploy.sh
   ```

That's it! The script will:
- ✅ Create all Azure resources (App Service, SQL Database, Managed Identity)
- ✅ Import the database schema using Azure Deployment Scripts (Azure-native method)
- ✅ Grant managed identity permissions automatically
- ✅ Configure secure authentication
- ✅ Display your application URL

## 📋 What Gets Deployed

- **App Service** (B1 Basic tier) - Hosts the Node.js web application
- **Azure SQL Database** (Basic tier) - Stores expense data
- **Managed Identity** - Provides secure, password-less database authentication
- **Resource Group** - Contains all resources in UK South region

**Estimated Cost**: ~£14/month for development

## 🎯 Features

The modernized application includes:

1. **Add Expense** - Submit new expense claims
2. **Approve Expenses** - Manager view to approve/reject expenses
3. **View Expenses** - Track all expenses with filtering

### Security Features
- ✅ Azure AD-only authentication (MCAPS compliant)
- ✅ No SQL passwords or connection strings with credentials
- ✅ Managed Identity for secure database access
- ✅ HTTPS enforced

### Resilience
- Automatic fallback to dummy data if database is unavailable
- Error messages displayed in UI without exposing code
- Comprehensive error logging

## 📖 Documentation

See [DEPLOYMENT.md](DEPLOYMENT.md) for:
- Detailed deployment instructions
- Manual deployment steps
- Troubleshooting guide
- API documentation
- Development setup

## 🏗️ Architecture

```
┌─────────────┐      HTTPS       ┌──────────────────┐
│   Browser   │ ◄────────────────►│   App Service    │
│             │                   │   (Node.js)      │
└─────────────┘                   └────────┬─────────┘
                                           │
                                           │ Managed
                                           │ Identity
                                           │
                                  ┌────────▼─────────┐
                                  │  Azure SQL DB    │
                                  │  (Entra ID Auth) │
                                  └──────────────────┘
```

## 🛠️ Technology Stack

- **Backend**: Node.js 20 LTS with Express.js
- **Database**: Azure SQL Database
- **Frontend**: HTML5, CSS3, JavaScript
- **Authentication**: Azure Managed Identity
- **Infrastructure**: Bicep (Infrastructure as Code)

## 📦 Repository Structure

```
├── infrastructure/          # Bicep IaC files
│   ├── main.bicep          # Main orchestration
│   ├── app-service.bicep   # App Service definition
│   ├── sql-database.bicep  # SQL Database with security
│   └── managed-identity.bicep
├── src/                    # Application code
│   ├── server.js           # Express.js server
│   ├── db.js              # Database connection with fallback
│   └── public/            # HTML, CSS, JS files
├── Database-Schema/        # SQL schema file
├── deploy.sh              # Infrastructure deployment script
└── deploy-app.sh          # Application deployment script
```

## 🧪 Testing Locally

```bash
cd src
npm install

# Set environment variables
export SQL_CONNECTION_STRING="Server=tcp:..."
export MANAGED_IDENTITY_CLIENT_ID="<client-id>"

# Start server
npm start
```

Visit http://localhost:8080

## 🔍 Monitoring

View application logs:
```bash
az webapp log tail --name <app-name> --resource-group rg-expense-mgmt-dev
```

Check health status:
```
https://<app-name>.azurewebsites.net/api/health
```

## 🤝 Contributing

This is a template repository for demonstrating app modernization. To test:

1. Fork this repo (rename to avoid confusion, e.g., "AMA-FridayTest01")
2. Replace screenshots in `Legacy-Screenshots/`
3. Replace SQL schema in `Database-Schema/`
4. Run GitHub Copilot agent with "modernise my app"

## 📝 Azure Best Practices

Following microsoft.com guidance:

- ✅ Infrastructure as Code (Bicep)
- ✅ Managed Identities (no credential management)
- ✅ Azure AD authentication
- ✅ HTTPS enforcement
- ✅ Principle of least privilege
- ✅ Regional deployment
- ✅ Resource tagging

## ⚠️ Important Notes

- This creates a **development environment** - see DEPLOYMENT.md for production considerations
- Default firewall allows all IPs for easy setup - restrict in production
- Basic tier SKUs are used for cost optimization - scale up for production

## 📄 License

MIT License - See LICENSE file
