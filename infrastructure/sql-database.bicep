// Azure SQL Database for Expense Management System
// Following prompt-002 requirements with Azure AD-only authentication and security compliance

param location string = 'uksouth'
param sqlServerName string = 'sql-expense-mgmt-${uniqueString(resourceGroup().id)}'
param databaseName string = 'Northwind'
param managedIdentityClientId string
param managedIdentityName string
param adminObjectId string
param adminLogin string
param schemaScriptContent string

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      login: adminLogin
      sid: adminObjectId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
  }
}

// Firewall rule to allow Azure services
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Firewall rule for client deployment IP
// Note: This IP can be parameterized for flexibility across different deployment locations
// For production, consider using Private Endpoints instead of public IP firewall rules
resource allowClientIp 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowClientDeploymentIP'
  properties: {
    startIpAddress: '81.133.169.79'
    endIpAddress: '81.133.169.79'
  }
}

// Managed Identity for Deployment Script
resource deploymentScriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'mid-SqlDeployment-${uniqueString(resourceGroup().id)}'
  location: location
}

// Grant the deployment script identity access to the SQL server
resource sqlAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sqlServer.id, deploymentScriptIdentity.id, 'SQL DB Contributor')
  scope: sqlServer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec') // SQL DB Contributor
    principalId: deploymentScriptIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deployment Script to import schema and grant managed identity permissions
// Using Azure Native Methods as required by prompt-002
resource schemaImportScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'import-sql-schema'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${deploymentScriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.52.0'
    retentionInterval: 'PT1H'
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    environmentVariables: [
      {
        name: 'SQL_SERVER'
        value: sqlServer.properties.fullyQualifiedDomainName
      }
      {
        name: 'DATABASE_NAME'
        value: databaseName
      }
      {
        name: 'MANAGED_IDENTITY_NAME'
        value: managedIdentityName
      }
      {
        name: 'SCHEMA_CONTENT'
        secureValue: schemaScriptContent
      }
      {
        name: 'SQL_RESOURCE_URL'
        value: environment().suffixes.sqlServerHostname
      }
    ]
    scriptContent: loadTextContent('schema-import.sh')
  }
  dependsOn: [
    sqlDatabase
    allowAzureServices
    sqlAdminRole
  ]
}

output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output databaseName string = sqlDatabase.name
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=Active Directory Managed Identity;User Id=${managedIdentityClientId};'
