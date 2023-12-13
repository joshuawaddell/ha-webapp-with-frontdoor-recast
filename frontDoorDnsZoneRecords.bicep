// Parameters
//////////////////////////////////////////////////
@description('The name of the application.')
param applicationName string

@description('The Front Door custom domain name verification id.')
param frontDoorCustomDomainVerificationId string

@description('The host name of the Front Door Endpoint.')
param frontDoorEndpointHostName string

@description('The name of your Dns zone.')
param dnsZoneName string

// Resource - Dns Zone - Txt Record
//////////////////////////////////////////////////
resource appServiceDnsTxtRecord 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  name: '${dnsZoneName}/_dnsauth.${applicationName}'
  properties: {
    TTL: 3600
    TXTRecords: [
      {
        value: [
          frontDoorCustomDomainVerificationId
        ]
      }
    ]
  }
}

// Resource - Dns Zone -Cname Record
//////////////////////////////////////////////////
resource frontDoorDnsCnameRecord 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: '${dnsZoneName}/${applicationName}'
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: frontDoorEndpointHostName
    }
  }
}
