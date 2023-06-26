// multiline string doesnt support interpolation
param uniqueness string = 'z9pqqf'

// var backend_policy_value = ' <policies> <inbound> <set-backend-service id="apim-generated-policy" backend-id="WebApp_api-app-api-python-graph-${uniqueness}" /> <base /> </inbound> <backend> <base /> </backend> <outbound> <base /> </outbound> <on-error> <base /> </on-error> </policies> '
var webshopPolicy = '<policies> <inbound> <base /> <cors> <allowed-origins> <origin>*</origin> </allowed-origins> <allowed-methods preflight-result-max-age="300"> <method>GET</method> <method>POST</method> </allowed-methods> <allowed-headers> <header>*</header> </allowed-headers> <expose-headers> <header>*</header> </expose-headers> </cors> <set-backend-service base-url="https://api-app-api-python-${uniqueness}-webshop.azurewebsites.net" /> </inbound> <backend> <base /> </backend> <outbound> <base /> </outbound> <on-error> <base /> </on-error> </policies>'



resource apimgmt 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: 'api-mgmt-team-apim-${uniqueness}'
}  

resource appinsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'api-app-insights-${uniqueness}'
  scope: resourceGroup('api-mgmt-demos-appteam')
}

resource apilogger 'Microsoft.ApiManagement/service/loggers@2021-01-01-preview' = {  
  name: '${apimgmt.name}/api-app-insights-${uniqueness}'
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      'instrumentationKey': appinsights.properties.InstrumentationKey
    }    
    isBuffered: true
    resourceId: appinsights.id
  }
}

resource apiversions 'Microsoft.ApiManagement/service/apiVersionSets@2021-04-01-preview' = {
  name: '${apimgmt.name}/versions'
  properties: {
    displayName: 'NodeAPI EXAMPLES API'
    versioningScheme: 'Segment'
  }
}

resource api1 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: '${apimgmt.name}/nodeAPI-v1'
  properties: {
    apiVersionDescription: 'V1'
    apiVersion: 'V1'
    displayName: 'Node API V1'
    apiType: 'http'
    description: 'Example nodeJS API'
    isCurrent: true
    format: 'openapi-link'
    value: 'https://api-app-api-node-REST-${uniqueness}.azurewebsites.net/spec/api-v1.yml'
    path: 'nodeAPI/v1'
    apiVersionSetId: apiversions.id
  }
}

resource api2 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: '${apimgmt.name}/nodeAPI-v2'
  properties: {
    apiVersionDescription: 'V2'
    apiVersion: 'V2'
    displayName: 'Node API V2'
    apiType: 'http'
    description: 'Example nodeJS API'
    isCurrent: true
    format: 'openapi-link'
    value: 'https://api-app-api-node-REST-${uniqueness}.azurewebsites.net/spec/api-v2.yml'
    path: 'nodeAPI/v2'
    apiVersionSetId: apiversions.id
  }
}


resource webshopAPI 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: '${apimgmt.name}/webshop'
  properties: {
    displayName: 'webshop'
    apiType: 'http'
    description: 'webshop api'
    isCurrent: true
    format: 'openapi-link'
    value: 'https://api-app-api-python-${uniqueness}-webshop.azurewebsites.net/openapi.json'
    path: 'webshop'
    subscriptionRequired: false 
  }
}

resource webshop_policy 'Microsoft.ApiManagement/service/apis/policies@2021-01-01-preview' = {
  name: '${webshopAPI.name}/policy'
  properties: {
    value: webshopPolicy
  }
}


resource webshopDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2021-04-01-preview' = {
  name: '${webshopAPI.name}/applicationinsights'
  properties: {
    loggerId: apilogger.id
    logClientIp: true
    httpCorrelationProtocol: 'W3C'
  }
}

// resource graphqlapi 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
//   name: '${apimgmt.name}/GraphQLAPI'
//   properties: {
//     apiType: 'http'
//     description: 'Example GraphQL API'
//     isCurrent: true
//     path: ''
//     protocols: [
//       'https'
//     ]
//     displayName: 'graphQLAPI'
//     serviceUrl: apimgmt.properties.gatewayUrl
//     subscriptionRequired: false 
//   }
// }


// resource operations_get 'Microsoft.ApiManagement/service/apis/operations@2019-01-01' = {
//   name: '${graphqlapi.name}/graphqloperations_get'
//   properties: {
//     displayName: 'graphql_get'
//     method: 'GET'
//     urlTemplate: '/*'
//     templateParameters: []
//     responses: []
//   }
// }

// resource operations_post 'Microsoft.ApiManagement/service/apis/operations@2019-01-01' = {
//   name: '${graphqlapi.name}/graphqloperations_post'
//   properties: {
//     displayName: 'graphql_post'
//     method: 'POST'
//     urlTemplate: '/*'
//     responses: []
//     templateParameters: []
//   }
// }

// resource backend_policy 'Microsoft.ApiManagement/service/apis/policies@2021-01-01-preview' = {
//   name: '${graphqlapi.name}/policy'
//   properties: {
//     value: backend_policy_value
//   }
// }















// resource diagnosticsetting 'Microsoft.ApiManagement/service/apis/diagnostics@2021-01-01-preview' = {
//   name: '${api1.name}/diagsetting'
//   properties: {
//     loggerId: apilogger.id
//   }
// }
