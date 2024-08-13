param multiContainerConfigContent string = ''
param location string = resourceGroup().location
param sqlServerLocation string = 'eastus2'  // or any other available region
param environment string = 'dev'
param appName string = 'todolist'
param tenantId string = tenant().tenantId
param objectId string
param acrLoginServer string
param acrUsername string
@secure()
param acrPassword string

var kvName = 'kv-${appName}-${environment}-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var sqlServerName = 'sql-${appName}-${environment}-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var sqlDBName = '${appName}-db'
var adminUsername = 'sqladmin'
var webAppName = '${appName}-${environment}-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var appServicePlanName = 'asp-${appName}-${environment}-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var privateDnsZoneName = 'privatelink.database.windows.net'

resource generatePassword 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'generatePassword'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.0.80'
    retentionInterval: 'PT1H'
    scriptContent: '''
      password=$(openssl rand -base64 24)
      echo "{\"password\":\"$password\"}" > $AZ_SCRIPTS_OUTPUT_PATH
    '''
    cleanupPreference: 'Always'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2021-03-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: acrUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: acrPassword
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'DB_SERVER'
          value: sqlServer.properties.fullyQualifiedDomainName
        }
        {
          name: 'DB_NAME'
          value: sqlDBName
        }
        {
          name: 'DB_USERNAME'
          value: adminUsername
        }
        {
          name: 'DB_PASSWORD'
          value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/TodoListSqlAdminPassword)'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
      ]
      linuxFxVersion: empty(multiContainerConfigContent) ? 'DOCKER|${acrLoginServer}/todo-list-react:latest' : 'COMPOSE|${multiContainerConfigContent}'
      alwaysOn: true
      http20Enabled: true
    }
    httpsOnly: true
  }
  tags: {
    app: appName
    environment: environment
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: kvName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: tenantId
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
  tags: {
    app: appName
    environment: environment
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'TodoListSqlAdminPassword'
  properties: {
    value: generatePassword.properties.outputs.password
  }
}

resource sqlServer 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: sqlServerName
  location: sqlServerLocation
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: generatePassword.properties.outputs.password
    publicNetworkAccess: 'Disabled'
  }
  tags: {
    app: appName
    environment: environment
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  parent: sqlServer
  name: sqlDBName
  location: sqlServerLocation
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
    minCapacity: json('0.5')
    autoPauseDelay: 60
  }
  tags: {
    app: appName
    environment: environment
  }
}

resource appGatewayNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-appgateway'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_GWM'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource webAppNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-webapp'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_AppGateway'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource sqlServerNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-sqlserver'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_WebApp'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '10.0.2.0/24'  // Assuming this is the Web App subnet
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

module appGatewayModule './appGateway.bicep' = {
  name: 'appGatewayDeployment'
  params: {
    location: location
    appName: appName
    environment: environment
    webAppName: webApp.name
    appGatewayNsgId: appGatewayNsg.id
    webAppNsgId: webAppNsg.id
    sqlServerNsgId: sqlServerNsg.id
  }
}

resource sqlServerPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'pe-${sqlServerName}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
    subnet: {
      id: '${appGatewayModule.outputs.vnetId}/subnets/${appGatewayModule.outputs.sqlServerSubnetName}'
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appGatewayModule.outputs.vnetId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: sqlServerPrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource webAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2021-03-01' = {
  parent: webApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: '${appGatewayModule.outputs.vnetId}/subnets/${appGatewayModule.outputs.webAppSubnetName}'
    swiftSupported: true
  }
}

resource existingACR 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: split(acrLoginServer, '.')[0]
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, webApp.id, 'acrpull')
  properties: {
    principalId: webApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalType: 'ServicePrincipal'
  }
  scope: existingACR
}

// Capture resource properties into global variables
var webAppNameVar = base64(webApp.name)
var keyVaultNameVar = base64(keyVault.name)
var sqlServerNameVar = base64(sqlServer.name)
var sqlDatabaseNameVar = base64(sqlDatabase.name)
var sqlServerFqdnVar = base64(sqlServer.properties.fullyQualifiedDomainName)

// Outputs without prefixes
output webAppName string = webAppNameVar
output keyVaultName string = keyVaultNameVar
output sqlServerName string = sqlServerNameVar
output sqlDatabaseName string = sqlDatabaseNameVar
output sqlServerFqdn string = sqlServerFqdnVar
output myTestValue string = 'apples_are_red'