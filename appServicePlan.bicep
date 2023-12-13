// Parameters
//////////////////////////////////////////////////
@description('The name of the App Service Plan.')
param appServicePlanName string

@description('The location of all resources.')
param location string

// Resource - App Service Plan
//////////////////////////////////////////////////
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'P1v3'
  }
  properties: {
    reserved: true
  }
}

// Outputs
//////////////////////////////////////////////////
output appServicePlanId string = appServicePlan.id
