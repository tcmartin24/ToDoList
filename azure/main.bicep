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

resource sqlServerFirewallRules 'Microsoft.Sql/servers/firewallRules@2021-11-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output webAppName string = webApp.name
output keyVaultName string = keyVault.name
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output myTestValue string = 'apples_are_red'