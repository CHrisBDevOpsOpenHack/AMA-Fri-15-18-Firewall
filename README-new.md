# Expense Management System - Modernized

A modern expense management system demonstrating cloud-native application modernization using ASP.NET Core, Azure App Service, Azure SQL Database, and Azure AI.

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and authenticated
- .NET 8.0 SDK (for local development)
- Python 3.x with pip (for database configuration)

### Deploy Everything

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
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
- ✅ Import the database schema
- ✅ Grant managed identity permissions automatically
- ✅ Build and deploy the ASP.NET Core application
- ✅ Display your application URL

## 📋 What Gets Deployed

### Base Deployment (deploy.sh)
- **App Service** (B1 Basic tier, Linux) - Hosts the ASP.NET Core 8.0 application
- **Azure SQL Database** (Basic tier) - Stores expense data with Northwind schema
- **Managed Identity** - Provides secure, password-less database authentication
- **Resource Group** - Contains all resources in UK South region

**Estimated Cost**: ~£15/month for development

### With GenAI Services (deploy-with-chat.sh) - Coming Soon
- All base resources above
- **Azure OpenAI** (S0, Sweden Central) - GPT-4o model for AI chat
- **Azure AI Search** (S0) - For RAG (Retrieval-Augmented Generation)

**Estimated Cost**: ~£205/month

## 🎯 Features

The modernized application includes:

### Core Functionality
1. **View Expenses** - Track all expenses with filtering by status
2. **Add Expense** - Submit new expense claims with categories
3. **Approve Expenses** - Manager view to approve/reject expenses
4. **Chat Assistant** - AI-powered chat interface (basic version included, full AI coming with GenAI deployment)

### Modern UI
- Clean, responsive Bootstrap 5 design
- Real-time updates without page refreshes
- Mobile-friendly interface
- Icon-based navigation

### API Layer
- RESTful APIs with full Swagger documentation
- Available at `/swagger` endpoint
- Endpoints for all CRUD operations:
  - `GET /api/expenses` - List all expenses
  - `GET /api/expenses/pending` - Get pending expenses
  - `POST /api/expenses` - Create new expense
  - `POST /api/expenses/{id}/submit` - Submit for approval
  - `POST /api/expenses/{id}/approve` - Approve expense
  - `POST /api/expenses/{id}/reject` - Reject expense
  - `GET /api/categories` - List expense categories
  - `GET /api/health` - Health check

### Security Features
- ✅ Azure AD-only authentication (MCAPS compliant)
- ✅ No SQL passwords or connection strings with credentials
- ✅ Managed Identity for secure database access
- ✅ HTTPS enforced
- ✅ TLS 1.2 minimum
- ✅ Parameterized queries (SQL injection prevention)

### Resilience
- Automatic fallback to dummy data if database is unavailable
- Error messages displayed in UI without exposing code details
- Comprehensive error logging
- Health check endpoint for monitoring

## 🏗️ Technology Stack

- **Backend**: ASP.NET Core 8.0 with Razor Pages
- **Frontend**: HTML5, CSS3, JavaScript, Bootstrap 5, Bootstrap Icons
- **Database**: Azure SQL Database
- **Authentication**: Azure Managed Identity
- **Infrastructure**: Bicep (Infrastructure as Code)
- **APIs**: RESTful with Swagger/OpenAPI documentation

## 📦 Repository Structure

```
├── infrastructure/              # Bicep IaC files
│   ├── main.bicep              # Main orchestration
│   ├── app-service.bicep       # App Service + Plan (B1 Linux, .NET 8)
│   ├── sql-database.bicep      # SQL Database with security
│   └── managed-identity.bicep  # User-assigned managed identity
├── src-csharp/                 # ASP.NET Core application
│   ├── Controllers/            # API controllers
│   ├── Models/                 # Data models
│   ├── Pages/                  # Razor Pages
│   ├── Services/               # Business logic (Database service)
│   └── wwwroot/                # Static assets
├── Database-Schema/            # SQL schema file
├── app.zip                     # Deployment package
├── deploy.sh                   # Infrastructure + app deployment script
├── deploy-with-chat.sh         # GenAI services deployment (coming soon)
├── run-sql.py                  # Python script for SQL configuration
└── README.md                   # This file
```

## 🧪 Testing Locally

```bash
cd src-csharp
dotnet restore
dotnet build

# Set environment variables
export SQL_CONNECTION_STRING="Server=tcp:your-server.database.windows.net,1433;Initial Catalog=Northwind;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=Active Directory Managed Identity;"
export MANAGED_IDENTITY_CLIENT_ID="<your-managed-identity-client-id>"

# Start server
dotnet run
```

Visit:
- Application: http://localhost:5000
- Swagger UI: http://localhost:5000/swagger

## 🔍 Monitoring

View application logs:
```bash
az webapp log tail --name <app-name> --resource-group rg-expense-mgmt-dev
```

Check health status:
```bash
curl https://<app-name>.azurewebsites.net/api/health
```

## 📖 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architecture diagrams and component descriptions
- [DEPLOYMENT.md](DEPLOYMENT.md) - Manual deployment steps and troubleshooting
- API Documentation - Available at `https://<your-app>.azurewebsites.net/swagger`

## 🔐 Security & Compliance

Following Azure and Microsoft best practices:

- ✅ Infrastructure as Code (Bicep)
- ✅ Managed Identities (no credential management)
- ✅ Azure AD authentication (Microsoft Entra)
- ✅ HTTPS enforcement (TLS 1.2+)
- ✅ Principle of least privilege (db_datareader, db_datawriter roles)
- ✅ Regional deployment (UK South)
- ✅ Azure Policy compliance
- ✅ Transparent Data Encryption (TDE enabled by default)
- ✅ Network security (firewall rules for Azure services)
- ✅ Parameterized queries (SQL injection prevention)

## 🎨 Modernization Journey

This application demonstrates migration from:
- **Desktop → Web**: Legacy desktop app to modern web application
- **Node.js → .NET**: Modernized to ASP.NET Core 8.0
- **Manual → IaC**: Infrastructure as Code with Bicep
- **Passwords → Managed Identity**: Secure, credential-less authentication
- **Monolith → API**: RESTful API architecture with Swagger docs
- **Static → Dynamic**: Real-time updates with JavaScript

## ⚠️ Important Notes

- This creates a **development environment** - see DEPLOYMENT.md for production considerations
- Basic tier SKUs are used for cost optimization - scale up for production
- The Chat UI has basic functionality; full AI capabilities require GenAI deployment

## 🤝 Contributing

This is a demonstration repository for app modernization with GitHub Copilot. To customize:

1. Fork this repository
2. Update Database-Schema with your schema
3. Update Legacy-Screenshots with your app screenshots
4. Run the deployment

## 📄 License

MIT License - See LICENSE file

## 🆘 Troubleshooting

Common issues and solutions:

1. **Deploy script fails**: Ensure you're logged into Azure CLI and have appropriate permissions
2. **Database connection fails**: Check managed identity permissions and firewall rules
3. **App doesn't start**: Check App Service logs for detailed error messages
4. **Python script fails**: Ensure pyodbc and azure-identity are installed

For more help, see [DEPLOYMENT.md](DEPLOYMENT.md)

---

**Built with ❤️ using ASP.NET Core, Azure, and GitHub Copilot**
