// Parameters
//////////////////////////////////////////////////
@description('The custom host name of the application.')
param applicationHostName string

@description('')
param frontDoorCustomDomainName string

@description('')
param frontDoorEndpointName string

@description('')
param frontDoorOriginGroupName string

@description('')
param frontDoorOriginHostNamePrimaryRegion string

@description('')
param frontDoorOriginHostNameSecondaryRegion string

@description('')
param frontDoorOriginNamePrimaryRegion string

@description('')
param frontDoorOriginNameSecondaryRegion string

@description('')
param frontDoorProfileName string

@description('')
param frontDoorRouteName string

@description('')
param frontDoorSecretName string

@description('')
param frontDoorSkuName string

@description('The Id of the Key Vault secret.')
@secure()
param keyVaultSecretId string

@description('The version of the Key Vault secret.')
param keyVaultSecretVersion string

// Resource - Front Door - Profile
//////////////////////////////////////////////////
resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}

// Resource - Front Door - Endpoint
//////////////////////////////////////////////////
resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: frontDoorEndpointName
  location: 'global'
  properties: {
    // originResponseTimeoutSeconds: 240
    enabledState: 'Enabled'
  }
}

// Resource - Front Door - Origin Group
//////////////////////////////////////////////////
resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoorProfile
  name: frontDoorOriginGroupName
    properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

// Resource - Front Door - Origin - Primary Region
//////////////////////////////////////////////////
resource frontDoorOriginPrimaryRegion 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: frontDoorOriginGroup
  name: frontDoorOriginNamePrimaryRegion
  properties: {
    hostName: frontDoorOriginHostNamePrimaryRegion
    httpPort: 80
    httpsPort: 443
    originHostHeader: frontDoorOriginHostNamePrimaryRegion
    priority: 1
    weight: 1000
  }
}

// Resource - Front Door - Origin - Secondary Region
//////////////////////////////////////////////////
resource frontDoorOriginSecondaryRegion 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: frontDoorOriginGroup
  name: frontDoorOriginNameSecondaryRegion
  properties: {
    hostName: frontDoorOriginHostNameSecondaryRegion
    httpPort: 80
    httpsPort: 443
    originHostHeader: frontDoorOriginHostNameSecondaryRegion
    priority: 1
    weight: 1000
  }
}

// Resource - Front Door - Secret
//////////////////////////////////////////////////
resource frontDoorSecret 'Microsoft.Cdn/profiles/secrets@2023-05-01' = {
  parent: frontDoorProfile
  name: frontDoorSecretName
  properties: {
    parameters: {
      type: 'CustomerCertificate'
      useLatestVersion: (keyVaultSecretVersion == '')
      secretVersion: keyVaultSecretVersion
      secretSource: {
        id: keyVaultSecretId
      }
    }
  }
}

// Resource - Front Door - Custom Domain
//////////////////////////////////////////////////
resource frontDoorCustomDomain 'Microsoft.Cdn/profiles/customDomains@2023-05-01' = {
  parent: frontDoorProfile
  name: frontDoorCustomDomainName
  properties: {
    hostName: applicationHostName
    tlsSettings: {
      certificateType: 'CustomerCertificate'
      minimumTlsVersion: 'TLS12'
      secret: {
        id: frontDoorSecret.id
      }
    }
  }
}

// Resource - Front Door - Route
//////////////////////////////////////////////////
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: frontDoorEndpoint
  name: frontDoorRouteName  
  dependsOn:[
    frontDoorOriginPrimaryRegion
    frontDoorOriginSecondaryRegion
    // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    customDomains: [
      {
        id: frontDoorCustomDomain.id
      }
    ]
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    // queryStringCachingBehavior: 'IgnoreQueryString'
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

// Outputs
//////////////////////////////////////////////////
// output frontDoorCustomDomainVerificationId object = frontDoorCustomDomain.properties
output frontDoorCustomDomainVerificationId string = frontDoorCustomDomain.properties.validationProperties.validationToken
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName

