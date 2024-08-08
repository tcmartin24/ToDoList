param location string = resourceGroup().location
param environment string = 'dev'
param appName string = 'todolist'
param tenantId string = tenant().tenantId
param objectId string

var kvName = 'kv-${appName}-${environment}-${uniqueString(resourceGroup().id)}'
var sqlServerName = 'sql-${appName}-${environment}-${uniqueString(resourceGroup().id)}'
var sqlDBName = '${appName}-db'
var adminUsername = 'sqladmin'

resource generatePassword 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'generatePassword'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.0.80'
    retentionInterval: 'PT1H'
    scriptContent: '''
      password=$(openssl rand -base64 24)
      echo "{\\"password\\":\\"$password\\"}" > $AZ_SCRIPTS_OUTPUT_PATH
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
  location: location
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
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS',
    maxSizeBytes: 1073741824,
    minCapacity: 0.5,
    autoPauseDelay: 60
  }
  tags: {
    app: appName
    environment: environment
  }
}

output keyVaultName string = keyVault.name
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name