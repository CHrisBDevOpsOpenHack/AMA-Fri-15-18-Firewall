// User-Assigned Managed Identity for App Service to connect to Azure SQL
// Following prompt-017 requirements: naming format mid-AppModAssist-[Day-Hour-Minute]

param location string = resourceGroup().location
// Note: Using utcNow() ensures unique identity names per deployment as required by prompt-017
// Format: DD-HH-MM (Day-Hour-Minute) - may cause conflicts if multiple deployments in same minute
param timestamp string = utcNow('dd-HH-mm')
param identityName string = 'mid-AppModAssist-${timestamp}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

output managedIdentityId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
output managedIdentityClientId string = managedIdentity.properties.clientId
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
