// User-Assigned Managed Identity for App Service to connect to Azure SQL
// Following prompt-017 requirements

param location string = resourceGroup().location
param identityName string = 'mid-AppModAssist-${uniqueString(resourceGroup().id)}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

output managedIdentityId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
output managedIdentityClientId string = managedIdentity.properties.clientId
