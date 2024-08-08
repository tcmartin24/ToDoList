param location string = resourceGroup().location
param environment string = 'dev'
param appName string = 'todolist'

var kvName = 'kv-${appName}-${environment}-${uniqueString(resourceGroup().id)}'
var sqlServerName = 'sql-${appName}-${environment}-${uniqueString(resourceGroup().id)}'
var sqlDBName = '${appName}-db'
param adminUsername string = 'sqladmin'

module randomPassword 'ts:index.ts:randomPassword' = {
  name: 'generateRandomPassword'
  params: {
    command: 'openssl rand -base64 24'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: kvName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: subscription().tenantId
    accessPolicies: []
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

resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'TodoListSqlAdminPassword'
  properties: {
    value: randomPassword.outputs.result
  }
}

resource sqlServer 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: keyVault.getSecret('TodoListSqlAdminPassword')
  }
  tags: {
    app: appName
    environment: environment
  }
  dependsOn: [
    kvSecret
  ]
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
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
    minCapacity: 0.5
    autoPauseDelay: 5
  }
  tags: {
    app: appName
    environment: environment
  }
}

output keyVaultName string = keyVault.name
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name