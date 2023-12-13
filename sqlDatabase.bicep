// Parameters
//////////////////////////////////////////////////
@description('The password of the admin user.')
@secure()
param adminPassword string

@description('The name of the admin user.')
param adminUserName string

@description('The location of the primary region.')
param primaryRegion string

@description('The location of the secondary region.')
param secondaryRegion string

@description('The name of the Sql Database.')
param sqlDatabaseName string

@description('')
param sqlServerFailoverGroupName string

@description('The name of the Sql Server in the primary region.')
param sqlServerNamePrimaryRegion string

@description('The name of the Sql Server in the primary region.')
param sqlServerNameSecondaryRegion string

// Resource - Sql Server - Primary Region
//////////////////////////////////////////////////
resource sqlServerPrimaryRegion 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerNamePrimaryRegion
  location: primaryRegion
  properties: {
    administratorLogin: adminUserName
    administratorLoginPassword: adminPassword
    publicNetworkAccess: 'Enabled' 
  }
}

// Resource - Sql Server - Firewall Rules - Primary Region
//////////////////////////////////////////////////
resource sqlServerFirewallRulesPrimaryRegion 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServerPrimaryRegion
  name: 'AllowAzureServices'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
  }
}

// Resource - Sql Server - Secondary Region
//////////////////////////////////////////////////
resource sqlServerSecondaryRegion 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerNameSecondaryRegion
  location: secondaryRegion
  properties: {
    administratorLogin: adminUserName
    administratorLoginPassword: adminPassword
    publicNetworkAccess: 'Enabled'
  }
}

// Resource - Sql Server - Firewall Rules - Secondary Region
//////////////////////////////////////////////////
resource sqlServerFirewallRulesSecondaryRegion 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServerSecondaryRegion
  name: 'AllowAzureServices'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
  }
}

// Resource - Sql Database
//////////////////////////////////////////////////
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServerPrimaryRegion
  name: sqlDatabaseName
  location: primaryRegion
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
}

// Resource - Sql Database - Failover Group
//////////////////////////////////////////////////
resource sqlServerFailoverGroup 'Microsoft.Sql/servers/failoverGroups@2022-05-01-preview' = {
  parent: sqlServerPrimaryRegion
  name: sqlServerFailoverGroupName
  properties: {
    partnerServers: [
      {
        id: sqlServerSecondaryRegion.id
      }
    ]
    readWriteEndpoint: {
      failoverPolicy: 'Automatic'
      failoverWithDataLossGracePeriodMinutes: 60
    }
    readOnlyEndpoint: {
      failoverPolicy: 'Disabled'
    }
    databases: [
      sqlDatabase.id
    ]
  }
}

// Outputs
//////////////////////////////////////////////////
output sqlServerFqdn string = sqlServerPrimaryRegion.properties.fullyQualifiedDomainName
