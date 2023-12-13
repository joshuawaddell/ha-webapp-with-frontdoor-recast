// Parameters
//////////////////////////////////////////////////
@description('The name of the application.')
param applicationName string

@description('The App Service custom domain name verification id.')
param appServiceCustomDomainVerificationId string

@description('The name of the App Service.')
param appServiceName string

@description('The name of your Dns zone.')
param dnsZoneName string

// Resource - Dns Zone - Txt Record
//////////////////////////////////////////////////
resource appServiceDnsTxtRecord 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  name: '${dnsZoneName}/asuid.${applicationName}'
  properties: {
    TTL: 3600
    TXTRecords: [
      {
        value: [
          appServiceCustomDomainVerificationId
        ]
      }
    ]
  }
}

// Resource - Dns Zone -Cname Record
//////////////////////////////////////////////////
resource appServiceDnsCnameRecord 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: '${dnsZoneName}/${applicationName}'
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: '${appServiceName}.azurewebsites.net'
    }
  }
}
