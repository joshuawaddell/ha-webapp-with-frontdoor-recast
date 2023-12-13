// Parameters
//////////////////////////////////////////////////
@description('The custom host name of the application.')
param applicationHostName string

@description('The name of the App Service.')
param appServiceName string

@description('The thumbprint of the certificate.')
param certificateThumbprint string

// Resource - App Service - Sni Enable
//////////////////////////////////////////////////
resource appServiceSniEnable 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: '${appServiceName}/${applicationHostName}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: certificateThumbprint
  }
}
