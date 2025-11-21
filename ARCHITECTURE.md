# Azure Services Architecture Diagram

## Expense Management System - Modern Cloud Architecture

### Base Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Internet / Users                               │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ HTTPS
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Azure App Service (B1 Linux)                       │
│                  ASP.NET Core 8.0 Application                        │
│  • My Expenses   • Add Expense   • Approve   • Chat   • Swagger     │
└───────────────┬─────────────────────────────────────────────────────┘
                │ Uses Managed Identity
                ▼
┌─────────────────────────────────────────────────────────────────────┐
│     User-Assigned Managed Identity (mid-AppModAssist-DD-HH-MM)      │
│  Provides secure, credential-less authentication to Azure services   │
└───────────────┬─────────────────────────────────────────────────────┘
                │ Authenticates
                ▼
┌─────────────────────────────────────────────────────────────────────┐
│              Azure SQL Database (Basic Tier) - Northwind            │
│  • Azure AD-Only Auth  • Managed Identity Access  • TDE Enabled     │
└─────────────────────────────────────────────────────────────────────┘
```

See full documentation in this file for complete architecture details including GenAI services.
