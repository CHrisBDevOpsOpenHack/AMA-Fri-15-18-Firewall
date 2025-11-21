# Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Cloud (UK South)                  │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐   │
│  │           Resource Group: rg-expense-mgmt-dev          │   │
│  │                                                        │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │  User-Assigned Managed Identity              │    │   │
│  │  │  mid-AppModAssist-{unique}                   │    │   │
│  │  │                                              │    │   │
│  │  │  • No passwords or secrets                   │    │   │
│  │  │  • Assigned to App Service                   │    │   │
│  │  │  • Database permissions granted              │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                      │                                │   │
│  │                      │ Identity                       │   │
│  │                      ▼                                │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │  App Service (Linux)                          │    │   │
│  │  │  app-expense-mgmt-{unique}                   │    │   │
│  │  │                                              │    │   │
│  │  │  Plan: B1 Basic (Low Cost)                   │    │   │
│  │  │  Runtime: Node.js 20 LTS                     │    │   │
│  │  │  Protocol: HTTPS Only                        │    │   │
│  │  │                                              │    │   │
│  │  │  App: Express.js + REST API                  │    │   │
│  │  │  • Rate Limiting: 100 API/15min              │    │   │
│  │  │  • Error Handling: Dummy data fallback       │    │   │
│  │  │  • 7 API Endpoints                           │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                      │                                │   │
│  │                      │ Managed Identity Auth          │   │
│  │                      ▼                                │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │  Azure SQL Database                          │    │   │
│  │  │  sql-expense-mgmt-{unique}                   │    │   │
│  │  │                                              │    │   │
│  │  │  Database: Northwind                         │    │   │
│  │  │  Tier: Basic (5 DTU)                         │    │   │
│  │  │  Auth: Azure AD Only ✓                       │    │   │
│  │  │                                              │    │   │
│  │  │  Tables:                                     │    │   │
│  │  │  • Users (Employee, Manager)                 │    │   │
│  │  │  • Expenses (with categories)                │    │   │
│  │  │  • ExpenseCategories                         │    │   │
│  │  │  • ExpenseStatus                             │    │   │
│  │  │  • Roles                                     │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                                                        │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

                            ▲
                            │
                    HTTPS (TLS 1.2+)
                            │
                            │
                 ┌──────────┴──────────┐
                 │                     │
            ┌────▼────┐          ┌────▼────┐
            │ Browser │          │ Browser │
            │ (User)  │          │(Manager)│
            └─────────┘          └─────────┘
```

## User Interface Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Routes                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  GET /              →  View All Expenses (index.html)      │
│                        - Filter by date/category/status     │
│                        - Display all expenses in table      │
│                        - Save button (refresh)              │
│                                                             │
│  GET /add           →  Add New Expense (add.html)          │
│                        - Amount input                       │
│                        - Date picker                        │
│                        - Category dropdown                  │
│                        - Description textarea               │
│                        - Submit button                      │
│                                                             │
│  GET /approve       →  Approve Expenses (approve.html)     │
│                        - Pending expenses table             │
│                        - Filter/search                      │
│                        - Checkbox selection                 │
│                        - Approve button                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## API Endpoints

```
┌──────────────────────────────────────────────────────────────┐
│                      REST API                                │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  GET  /api/expenses          →  List all expenses           │
│  GET  /api/expenses/pending  →  List pending approvals      │
│  GET  /api/categories        →  List expense categories     │
│  POST /api/expenses          →  Create new expense          │
│  POST /api/expenses/:id/submit  →  Submit for approval      │
│  POST /api/expenses/:id/approve →  Approve expense          │
│  GET  /api/health            →  Health check                │
│                                                              │
│  Rate Limiting:                                              │
│  • API endpoints: 100 requests per 15 minutes               │
│  • Page views: 500 requests per 15 minutes                  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Database Schema

```
┌──────────────┐        ┌──────────────────┐
│    Roles     │        │      Users       │
├──────────────┤        ├──────────────────┤
│ RoleId (PK)  │◄───────│ UserId (PK)      │
│ RoleName     │        │ UserName         │
│ Description  │        │ Email            │
└──────────────┘        │ RoleId (FK)      │
                        │ ManagerId (FK)   │
                        └──────────────────┘
                                │
                                │
                                │
┌──────────────────┐     ┌──────▼──────────┐     ┌────────────────┐
│ ExpenseStatus    │     │    Expenses     │     │ ExpenseCatego- │
├──────────────────┤     ├─────────────────┤     │      ries      │
│ StatusId (PK)    │◄────│ ExpenseId (PK)  │────►│ CategoryId(PK) │
│ StatusName       │     │ UserId (FK)     │     │ CategoryName   │
│ • Draft          │     │ CategoryId (FK) │     │ • Travel       │
│ • Submitted      │     │ StatusId (FK)   │     │ • Meals        │
│ • Approved       │     │ AmountMinor     │     │ • Supplies     │
│ • Rejected       │     │ Currency (GBP)  │     │ • Accommodatio│
└──────────────────┘     │ ExpenseDate     │     │ • Other        │
                         │ Description     │     └────────────────┘
                         │ SubmittedAt     │
                         │ ReviewedBy (FK) │
                         │ ReviewedAt      │
                         └─────────────────┘
```

## Deployment Flow

```
┌────────────────────────────────────────────────────────────────┐
│                    Deployment Process                          │
└────────────────────────────────────────────────────────────────┘

    ./deploy.sh
        │
        ├─► 1. Get Azure AD User Info
        │      (Current user becomes SQL admin)
        │
        ├─► 2. Create Resource Group
        │      rg-expense-mgmt-dev (UK South)
        │
        ├─► 3. Deploy Bicep Template (main.bicep)
        │      │
        │      ├─► managed-identity.bicep
        │      │   • User-Assigned MI created (mid-AppModAssist-DD-HH-MM)
        │      │
        │      ├─► app-service.bicep
        │      │   • App Service Plan (B1)
        │      │   • App Service with MI
        │      │
        │      └─► sql-database.bicep
        │          • SQL Server (AD auth only)
        │          • Database (Northwind)
        │          • Firewall rules
        │          • **Azure Deployment Script** (Azure-native method)
        │            ├─► Install sqlcmd in container
        │            ├─► Get Azure AD token
        │            ├─► Import database schema automatically
        │            └─► Grant MI database permissions
        │
        ├─► 4. Configure App Service Settings
        │      • SQL_CONNECTION_STRING
        │      • MANAGED_IDENTITY_CLIENT_ID
        │
        └─► 5. Display Deployment Info
            • App Service URL
            • SQL Server FQDN
            • Database Name
            • Next steps


    ./deploy-app.sh <app-name>
        │
        ├─► 1. Install Dependencies
        │      npm install --production
        │
        ├─► 2. Create ZIP Package
        │      app.zip (all src files)
        │
        ├─► 3. Deploy to App Service
        │      az webapp deployment source config-zip
        │
        └─► 4. Application Ready!
            Visit: https://<app-name>.azurewebsites.net
```

## Security Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Security Layers                         │
└────────────────────────────────────────────────────────────┘

1. Network Security
   ├─► HTTPS Enforced (TLS 1.2 minimum)
   ├─► SQL Firewall (Azure services only)
   └─► FTPS Disabled

2. Authentication & Authorization
   ├─► Azure AD-Only Authentication (MCAPS Compliant)
   ├─► Managed Identity (No passwords)
   └─► No SQL Authentication (Disabled)

3. Application Security
   ├─► Rate Limiting (express-rate-limit)
   │   • API: 100 requests per 15 min
   │   • Pages: 500 requests per 15 min
   ├─► Parameterized Queries (SQL injection prevention)
   ├─► Error Handling (No code exposure)
   └─► Input Validation

4. Data Security
   ├─► Encrypted at Rest (Azure SQL)
   ├─► Encrypted in Transit (HTTPS)
   └─► Amounts stored as integers (avoid float issues)

5. Code Security
   ├─► No hardcoded credentials
   ├─► Environment variables for config
   ├─► CodeQL passed (0 vulnerabilities)
   └─► Dependencies checked (0 vulnerabilities)
```

## Cost Breakdown

```
┌─────────────────────────────────────────────────────┐
│          Monthly Cost Estimate (UK South)           │
├─────────────────────────────────────────────────────┤
│                                                     │
│  App Service Plan B1 (Basic)      £10.00/month     │
│  • 1 vCore                                          │
│  • 1.75 GB RAM                                      │
│  • 10 GB storage                                    │
│                                                     │
│  SQL Database Basic (5 DTU)        £4.00/month     │
│  • 2 GB storage                                     │
│  • Azure AD auth only                               │
│                                                     │
│  Managed Identity                  FREE             │
│                                                     │
│  Data Transfer (minimal)          ~£0.00/month     │
│                                                     │
├─────────────────────────────────────────────────────┤
│  TOTAL MONTHLY COST:              ~£14.00/month    │
└─────────────────────────────────────────────────────┘

Note: Actual costs may vary based on usage.
For production, consider upgrading to higher SKUs.
```

## File Structure

```
AMA-Fri-15-18-Firewall/
│
├── infrastructure/              # Bicep IaC files
│   ├── main.bicep              # Orchestration
│   ├── app-service.bicep       # App Service + Plan
│   ├── sql-database.bicep      # SQL Server + DB
│   └── managed-identity.bicep  # User-Assigned MI
│
├── src/                        # Application code
│   ├── package.json            # Dependencies
│   ├── server.js               # Express.js server
│   ├── db.js                   # Database layer
│   └── public/                 # Frontend files
│       ├── style.css           # Common styles
│       ├── index.html          # View expenses
│       ├── add.html            # Add expense
│       └── approve.html        # Approve expenses
│
├── Database-Schema/
│   └── database_schema.sql     # SQL schema + data
│
├── Legacy-Screenshots/         # Reference UI
│   ├── exp1.png               # Add expense screen
│   ├── exp2.png               # Approve screen
│   └── exp3.png               # View expenses screen
│
├── deploy.sh                  # Infrastructure deployment
├── deploy-app.sh              # Application deployment
│
├── README.md                  # User guide
├── DEPLOYMENT.md              # Detailed deployment
├── QUICK-REFERENCE.md         # Command reference
├── PROJECT-SUMMARY.md         # Project overview
└── .gitignore                 # Git exclusions
```
