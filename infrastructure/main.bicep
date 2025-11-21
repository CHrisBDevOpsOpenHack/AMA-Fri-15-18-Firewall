// Main deployment file for Expense Management System
// Orchestrates all infrastructure components

targetScope = 'resourceGroup'

param location string = 'uksouth'
param adminObjectId string
param adminLogin string

// Load the database schema file content
var schemaContent = loadTextContent('../Database-Schema/database_schema.sql')

// Deploy managed identity first
module managedIdentity 'managed-identity.bicep' = {
  name: 'managedIdentityDeployment'
  params: {
    location: location
  }
}

// Deploy App Service with managed identity
module appService 'app-service.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    managedIdentityId: managedIdentity.outputs.managedIdentityId
  }
}

// Deploy SQL Database with managed identity access
module sqlDatabase 'sql-database.bicep' = {
  name: 'sqlDatabaseDeployment'
  params: {
    location: location
    managedIdentityClientId: managedIdentity.outputs.managedIdentityClientId
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    adminObjectId: adminObjectId
    adminLogin: adminLogin
    schemaScriptContent: schemaContent
  }
}

output appServiceName string = appService.outputs.appServiceName
output appServiceUrl string = appService.outputs.appServiceUrl
output sqlServerFqdn string = sqlDatabase.outputs.sqlServerFqdn
output databaseName string = sqlDatabase.outputs.databaseName
output connectionString string = sqlDatabase.outputs.connectionString
output managedIdentityClientId string = managedIdentity.outputs.managedIdentityClientId
output managedIdentityName string = managedIdentity.outputs.managedIdentityName
