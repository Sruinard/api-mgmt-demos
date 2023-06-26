param uniqueness string = 'z9pqqf'

resource apimgmt 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: 'api-mgmt-team-apim-${uniqueness}'
  location: 'westeurope'
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: 'johndoe@microsoft.com'
    publisherName: 'John Doe'
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'api-mgmt-team-logs-${uniqueness}'
  location: 'westeurope'
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'api-mgmt-team-insights-${uniqueness}'
  location: 'westeurope'
  kind: 'web'  
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

resource portalstorage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'apimgmtportal${replace(uniqueness,'-','')}'
  location: resourceGroup().location
  kind: 'BlockBlobStorage'
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    accessTier: 'Cool'
    supportsHttpsTrafficOnly: true      
    minimumTlsVersion: 'TLS1_2'
 
 }
}
