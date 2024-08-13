param location string
param appName string
param environment string
param webAppName string
param appGatewayNsgId string
param webAppNsgId string
param sqlServerNsgId string

var vnetName = 'vnet-${appName}-${environment}'
var appGatewaySubnetName = 'subnet-appgateway'
var webAppSubnetName = 'subnet-webapp'
var sqlServerSubnetName = 'subnet-sqlserver'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: appGatewayNsgId
          }
        }
      }
      {
        name: webAppSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: webAppNsgId
          }
        }
      }
      {
        name: sqlServerSubnetName
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: {
            id: sqlServerNsgId
          }
        }
      }
    ]
  }
}

resource appGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-appgateway-${appName}-${environment}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: 'appgw-${appName}-${environment}'
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGatewayPublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apiBackend'
        properties: {
          backendAddresses: [
            {
              fqdn: '${webAppName}.azurewebsites.net'
            }
          ]
        }
      }
      {
        name: 'reactBackend'
        properties: {
          backendAddresses: [
            {
              fqdn: '${webAppName}.azurewebsites.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apiHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          path: '/api'
        }
      }
      {
        name: 'reactHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'appgw-${appName}-${environment}', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'appgw-${appName}-${environment}', 'appGatewayFrontendPort')
          }
          protocol: 'Http'
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'urlPathMap'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'appgw-${appName}-${environment}', 'reactBackend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'appgw-${appName}-${environment}', 'reactHttpSettings')
          }
          pathRules: [
            {
              name: 'apiRule'
              properties: {
                paths: [
                  '/api/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'appgw-${appName}-${environment}', 'apiBackend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'appgw-${appName}-${environment}', 'apiHttpSettings')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingRule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'appgw-${appName}-${environment}', 'httpListener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', 'appgw-${appName}-${environment}', 'urlPathMap')
          }
        }
      }
    ]
  }
}

output appGatewayId string = appGateway.id
output appGatewayName string = appGateway.name
output vnetId string = vnet.id
output vnetName string = vnet.name
output appGatewaySubnetName string = appGatewaySubnetName
output webAppSubnetName string = webAppSubnetName
output sqlServerSubnetName string = sqlServerSubnetName