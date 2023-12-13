// Parameters
//////////////////////////////////////////////////
@description('The custom host name of the application.')
param applicationHostName string

@description('The name of the App Service.')
param appServiceName string

@description('The resource Id of the App Service Plan.')
param appServicePlanId string

@description('The name of the certificate.')
param certificateName string

@description('The resource Id of the Key Vault.')
param keyVaultId string

@description('The name of the Key Vault secret.')
param keyVaultSecretName string

@description('The location of all resources.')
param location string

// Resource - App Service
//////////////////////////////////////////////////
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Resource - App Service - Custom Domain
//////////////////////////////////////////////////
resource appServiceCustomDomain 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  parent: appService
  name: applicationHostName
    properties: {
    hostNameType: 'Verified'
    sslState: 'Disabled'
    customHostNameDnsRecordType: 'CName'
    siteName: appService.name
  }
}

// Resource - App Service - Certificate
//////////////////////////////////////////////////
resource appServiceCertificate 'Microsoft.Web/certificates@2022-03-01' = {
  name: certificateName
  location: location
  properties: {
    keyVaultId: keyVaultId
    keyVaultSecretName: keyVaultSecretName
    // password: certificatePassword
    serverFarmId: appServicePlanId
  }
}

// Outputs
//////////////////////////////////////////////////
output certificateThumbprint string = appServiceCertificate.properties.thumbprint
