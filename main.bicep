// Parameters
//////////////////////////////////////////////////
@description('')
@secure()
param adminPassword string

@description('')
param adminUserName string

@description('The name of the Front Door Profile Sku.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

@description('')
param keyVaultName string = ''

@description('')
param keyVaultSecretName string = ''

@description('')
param keyVaultSecretVersion string = ''

@description('')
param rootDomainName string = ''

@description('')
param primaryRegion string = ''

@description('')
param secondaryRegion string = ''

// Variables
//////////////////////////////////////////////////
var applicationHostName = '${applicationName}.${rootDomainName}'
var applicationName = 'webapp'
var appServiceCertificateNamePrimaryRegoin = 'cert-${primaryRegion}-wildcard'
var appServiceCertificateNameSecondaryRegoin = 'cert-${secondaryRegion}-wildcard'
var appServiceNamePrimaryRegion = 'app-${primaryRegion}-${uniqueString(resourceGroup().id)}'
var appServiceNameSecondaryRegion = 'app-${secondaryRegion}-${uniqueString(resourceGroup().id)}'
var appServicePlanNamePrimaryRegion = 'plan-${primaryRegion}-frontdoor'
var appServicePlanNameSecondaryRegion = 'plan-${secondaryRegion}-frontdoor'
var dockerImage = ''
var frontDoorCustomDomainName = 'cdndomain-global-frontdoor'
var frontDoorEndpointName = 'cdnendopint-global-${uniqueString(resourceGroup().id)}'
var frontDoorOriginGroupName = 'cdnorigingroup-global-frontdoor'
var frontDoorOriginHostNamePrimaryRegion = 'app-${primaryRegion}-${uniqueString(resourceGroup().id)}.azurewebsites.net'
var frontDoorOriginHostNameSecondaryRegion = 'app-${secondaryRegion}-${uniqueString(resourceGroup().id)}.azurewebsites.net'
var frontDoorOriginNamePrimaryRegion = 'cdnorigin-${primaryRegion}-frontdoor'
var frontDoorOriginNameSecondaryRegion = 'cdnorigin-${secondaryRegion}-frontdoor'
var frontDoorProfileName = 'cdnprofile-global-frontdoor'
var frontDoorRouteName = 'cdnroute-global-frontdoor'
var frontDoorSecretName = 'cdnsecret-global-frontdoor'
var sqlDatabaseName = 'sqldb-${primaryRegion}-${uniqueString(resourceGroup().id)}'
var sqlServerFailoverGroupName = replace('sqlfg-${primaryRegion}-${uniqueString(resourceGroup().id)}', '-', '')
var sqlServerNamePrimaryRegion = 'sql-${primaryRegion}-${uniqueString(resourceGroup().id)}'
var sqlServerNameSecondaryRegion = 'sql-${secondaryRegion}-${uniqueString(resourceGroup().id)}'

// Existing Resource - Dns Zone
//////////////////////////////////////////////////
resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: rootDomainName
}

// Existing Resource - Key Vault
//////////////////////////////////////////////////
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  resource keyVaultSecret 'secrets' existing = {
    name: keyVaultSecretName
  }
}

// Module - SQL Database
//////////////////////////////////////////////////
module sqlDatabase 'sqlDatabase.bicep' = {
  name: 'sqlDatabaseDeployment'
  params: {
    adminPassword: adminPassword
    adminUserName: adminUserName
    primaryRegion: primaryRegion
    secondaryRegion: secondaryRegion
    sqlDatabaseName: sqlDatabaseName
    sqlServerFailoverGroupName: sqlServerFailoverGroupName
    sqlServerNamePrimaryRegion: sqlServerNamePrimaryRegion
    sqlServerNameSecondaryRegion: sqlServerNameSecondaryRegion
  }
}

// Module - App Service Plan - Primary Region
//////////////////////////////////////////////////
module appServicePlanPrimaryRegion 'appServicePlan.bicep' = {
  name: 'appServicePlanPrimaryRegionDeployment'
  params: {
    appServicePlanName: appServicePlanNamePrimaryRegion
    location: primaryRegion
  }
}

// Module - App Service - Primary Region
//////////////////////////////////////////////////
module appServicePrimaryRegion 'appService.bicep' = {
  name: 'appServicePrimaryRegionDeployment'
  params: {
    adminPassword: adminPassword
    adminUserName: adminUserName    
    appServiceName: appServiceNamePrimaryRegion
    appServicePlanId: appServicePlanPrimaryRegion.outputs.appServicePlanId
    dockerImage: dockerImage
    location: primaryRegion
    sqlDatabaseName: sqlDatabaseName
    sqlServerFQDN: sqlDatabase.outputs.sqlServerFqdn
  }
}

// Module - App Service Dns Zone Records - Primary Region
//////////////////////////////////////////////////
module dnsZoneRecordsPrimaryRegion 'appServiceDnsZoneRecords.bicep' = {
  name: 'appServiceDnsZoneRecordsPrimaryRegionDeployment'
  params: {
    applicationName: applicationName
    appServiceCustomDomainVerificationId: appServicePrimaryRegion.outputs.appServiceCustomDomainVerificationId
    appServiceName: appServiceNamePrimaryRegion
    dnsZoneName: dnsZone.name
  }
}

// Module - App Service Certificate - Primary Region
//////////////////////////////////////////////////
module appServiceCertificatePrimaryRegion 'appServiceTls.bicep' = {
  name: 'appServiceCertificatePrimaryRegionDeployment'
  dependsOn: [
    dnsZoneRecordsPrimaryRegion
  ]
  params: {
    applicationHostName: applicationHostName
    appServiceName: appServiceNamePrimaryRegion
    appServicePlanId: appServicePlanPrimaryRegion.outputs.appServicePlanId
    certificateName: appServiceCertificateNamePrimaryRegoin
    keyVaultId: keyVault.id
    keyVaultSecretName: keyVaultSecretName
    location: primaryRegion
  }
}

// Module - App Service Sni Enable - Primary Region
//////////////////////////////////////////////////
module appServiceSniEnablePrimaryRegion 'appServiceSniEnable.bicep' = {
  name: 'appServiceSniEnablePrimaryRegionDeployment'
  params: {
    applicationHostName: applicationHostName
    appServiceName: appServiceNamePrimaryRegion
    certificateThumbprint: appServiceCertificatePrimaryRegion.outputs.certificateThumbprint
  }
}

// Module - App Service Plan - Secondary Region
//////////////////////////////////////////////////
module appServicePlanSecondaryRegion 'appServicePlan.bicep' = {
  name: 'appServicePlanSecondaryRegionDeployment'
  dependsOn: [
    appServiceSniEnablePrimaryRegion
  ]
  params: {
    appServicePlanName: appServicePlanNameSecondaryRegion
    location: secondaryRegion
  }
}

// Module - App Service - Secondary Region
//////////////////////////////////////////////////
module appServiceSecondaryRegion 'appService.bicep' = {
  name: 'appServiceSecondaryRegionDeployment'
  params: {
    adminPassword: adminPassword
    adminUserName: adminUserName  
    appServiceName: appServiceNameSecondaryRegion
    appServicePlanId: appServicePlanSecondaryRegion.outputs.appServicePlanId
    dockerImage: dockerImage
    location: secondaryRegion
    sqlDatabaseName: sqlDatabaseName
    sqlServerFQDN: sqlDatabase.outputs.sqlServerFqdn
  }
}

// Module - App Service Dns Zone Records - Secondary Region
//////////////////////////////////////////////////
module appServiceDnsZoneRecordsSecondaryRegion 'appServiceDnsZoneRecords.bicep' = {
  name: 'appServiceDnsZoneRecordsSecondaryRegionDeployment'
  params: {
    applicationName: applicationName
    appServiceCustomDomainVerificationId: appServiceSecondaryRegion.outputs.appServiceCustomDomainVerificationId
    appServiceName: appServiceNameSecondaryRegion
    dnsZoneName: dnsZone.name
  }
}

// Module - App Service Certificate - Secondary Region
//////////////////////////////////////////////////
module appServiceCertificateSecondaryRegion 'appServiceTls.bicep' = {
  name: 'appServiceCertificateSecondaryRegionDeployment'
  dependsOn: [
    appServiceDnsZoneRecordsSecondaryRegion
  ]
  params: {
    applicationHostName: applicationHostName
    appServiceName: appServiceNameSecondaryRegion
    appServicePlanId: appServicePlanSecondaryRegion.outputs.appServicePlanId
    certificateName: appServiceCertificateNameSecondaryRegoin
    keyVaultId: keyVault.id
    keyVaultSecretName: keyVaultSecretName
    location: secondaryRegion
  }
}

// Module - App Service Sni Enable - Secondary Region
//////////////////////////////////////////////////
module appServiceSniEnableSecondaryRegion 'appServiceSniEnable.bicep' = {
  name: 'appServiceSniEnableSecondaryRegionDeployment'
  params: {
    applicationHostName: applicationHostName
    appServiceName: appServiceNameSecondaryRegion
    certificateThumbprint: appServiceCertificateSecondaryRegion.outputs.certificateThumbprint
  }
}

// Module - Front Door
//////////////////////////////////////////////////
module frontDoor 'frontdoor.bicep' = {
  name: 'frontDoorDeployment'
  dependsOn: [
    appServiceSniEnableSecondaryRegion
  ]
  params: {
    applicationHostName: applicationHostName
    frontDoorCustomDomainName: frontDoorCustomDomainName
    frontDoorEndpointName: frontDoorEndpointName
    frontDoorOriginGroupName: frontDoorOriginGroupName
    frontDoorOriginHostNamePrimaryRegion: frontDoorOriginHostNamePrimaryRegion
    frontDoorOriginHostNameSecondaryRegion: frontDoorOriginHostNameSecondaryRegion
    frontDoorOriginNamePrimaryRegion: frontDoorOriginNamePrimaryRegion
    frontDoorOriginNameSecondaryRegion: frontDoorOriginNameSecondaryRegion
    frontDoorProfileName: frontDoorProfileName
    frontDoorRouteName: frontDoorRouteName
    frontDoorSecretName: frontDoorSecretName
    frontDoorSkuName: frontDoorSkuName
    keyVaultSecretId: keyVault::keyVaultSecret.id
    keyVaultSecretVersion: keyVaultSecretVersion
  }
}

// Module - Front Door Dns Zone Records
//////////////////////////////////////////////////
module frontDoorDnsZoneRecords 'frontDoorDnsZoneRecords.bicep' = {
  name: 'frontDoorDnsZoneRecordsDeployment'
  params: {
    applicationName: applicationName
    dnsZoneName: dnsZone.name
    frontDoorCustomDomainVerificationId: frontDoor.outputs.frontDoorCustomDomainVerificationId
    frontDoorEndpointHostName: frontDoor.outputs.frontDoorEndpointHostName
  }
}
