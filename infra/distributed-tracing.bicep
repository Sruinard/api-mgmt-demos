param uniqueness string = 'z9pqqf'
param location string = resourceGroup().location

resource appserviceplan 'Microsoft.Web/serverfarms@2021-01-15' existing =  {
  name: 'api-app-asp-${uniqueness}'
}


resource appinsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'api-app-insights-${uniqueness}'
}

resource webshop 'Microsoft.Web/sites@2021-02-01' = {
  name: 'api-app-api-python-${uniqueness}-webshop'
  location: 'westeurope'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appserviceplan.id
    httpsOnly: true    
    siteConfig: {
      cors: {
        allowedOrigins: [
          '*'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appinsights.properties.InstrumentationKey
        }
        {
          name: 'APPINSIGHTS_CONNECTION_STRING'
          value: appinsights.properties.ConnectionString
        }
        {
          name: 'PAYMENTS_ENDPOINT'
          value: 'https://${payments.properties.defaultHostName}/'
        }
        {
          name: 'SHIPMENTS_ENDPOINT'
          value: 'https://${shipping.properties.defaultHostName}/'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
      ]
      
      linuxFxVersion: 'python|3.7'
      alwaysOn: false
      
    }
    clientAffinityEnabled: false    
  }  
}

resource payments 'Microsoft.Web/sites@2021-02-01' = {
  name: 'api-app-api-python-${uniqueness}-payments'
  location: 'westeurope'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appserviceplan.id
    httpsOnly: true    
    siteConfig: {
      cors: {
        allowedOrigins: [
          '*'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appinsights.properties.InstrumentationKey
        }
        {
          name: 'APPINSIGHTS_CONNECTION_STRING'
          value: appinsights.properties.ConnectionString
        }
        {
          name: 'SHIPPING_ENDPOINT'
          value: 'https://${shipping.properties.defaultHostName}/'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
      ]
      
      linuxFxVersion: 'python|3.7'
      alwaysOn: false
      
    }
    clientAffinityEnabled: false    
  }  
}

resource shipping 'Microsoft.Web/sites@2021-02-01' = {
  name: 'api-app-api-python-${uniqueness}-shipping'
  location: 'westeurope'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appserviceplan.id
    httpsOnly: true    
    siteConfig: {
      cors: {
        allowedOrigins: [
          '*'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appinsights.properties.InstrumentationKey
        }
        {
          name: 'APPINSIGHTS_CONNECTION_STRING'
          value: appinsights.properties.ConnectionString
        }
        {
          name: 'ACCOUNT_URI'
          value: cosmos_account.properties.documentEndpoint
        }        
        {
          name: 'ACCOUNT_KEY'
          value: listKeys(cosmos_account.id, cosmos_account.apiVersion).primaryMasterKey
        }     
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
      ]
      
      linuxFxVersion: 'python|3.7'
      alwaysOn: false
      
    }
    clientAffinityEnabled: false    
  }  
}


// ####################
// #####  COSMOS  #####
// ####################

resource cosmos_account 'Microsoft.DocumentDB/databaseAccounts@2021-07-01-preview' = {
  name: 'we-cosmos-distributed-tracing'
  location: location
  properties: {
    createMode: 'Default'
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        'locationName': location
        'failoverPriority': 0
        'isZoneRedundant':false
      }
    ]
  }
}

resource cosmos_db 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-04-15' = {
  name: '${cosmos_account.name}/webshop'
  location: location
  properties: {
    resource: {
      id: 'webshop'
    }
    options: {
      throughput: 400
    }
  }
}

resource cosmosdb_container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  name: '${cosmos_db.name}/orders'
  location: location
  properties: {
    resource: {
      id: 'orders'
      partitionKey:{
        kind: 'Hash'
        paths: [
          '/item_id'
        ]
        version: 1
      }
    }
  }
}

var identityName = 'distracingblob'
var roleDefinitionId = resourceId('microsoft.authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var roleAssignmentName = guid(mi.name, roleDefinitionId, resourceGroup().id)

resource mi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource miRoleAssign 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: mi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}



resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'blobtracing${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  dependsOn: [
    miRoleAssign
  ]
  kind: 'StorageV2'
}

var ScriptToExecute = 'az storage blob service-properties update --account-name ${stg.name} --static-website --404-document "404.html" --index-document "form.html"'
resource dScriptWp 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${stg.name}-enable-static-webapp'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${mi.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.28.0'
    storageAccountSettings: {
      storageAccountName: stg.name
      storageAccountKey: stg.listKeys().keys[0].value
    }
    scriptContent: ScriptToExecute
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    timeout: 'PT5M'
  }
}
