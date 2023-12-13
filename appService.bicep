// Parameters
//////////////////////////////////////////////////
@description('The password of the admin user.')
@secure()
param adminPassword string

@description('The name of the admin user.')
param adminUserName string

@description('The name of the App Service.')
param appServiceName string

@description('The resource Id of the App Service Plan.')
param appServicePlanId string

@description('The name of the App Service Docker Image.')
param dockerImage string

@description('The location of all resources.')
param location string

@description('The name of the Sql Database.')
param sqlDatabaseName string

@description('The Fqdn of the Sql Server.')
param sqlServerFQDN string

// Resource - App Service
//////////////////////////////////////////////////
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  kind: 'container'
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: dockerImage
      netFrameworkVersion: 'v6.0'
      appSettings: [
        {
          name: 'DefaultSqlConnectionSqlConnectionString'
          value: 'Data Source=tcp:${sqlServerFQDN},1433;Initial Catalog=${sqlDatabaseName};User Id=${adminUserName}@${sqlServerFQDN};Password=${adminPassword};'
        }
      ]
    }
  }
}

// Resource - App Service - Config
//////////////////////////////////////////////////
resource appServiceConfig 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appService
  name: 'web'
  properties: {
    ipSecurityRestrictions: [
      {
        ipAddress: 'AzureFrontDoor.Backend'
        action: 'Allow'
        tag: 'ServiceTag'
        priority: 100
        name: 'AllowAzureFrontDoor.Backend'
      }
    ]
  }
}

// Outputs
//////////////////////////////////////////////////
output appServiceCustomDomainVerificationId string = appService.properties.customDomainVerificationId
