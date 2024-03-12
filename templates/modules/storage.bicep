param resourceLocation string = resourceGroup().location
param tags object = {
}

resource sto 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: substring('labprivatelink${uniqueString(deployment().name)}', 0, 21)
  location: resourceLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
  tags: tags
}

output id string = sto.id
output name string = sto.name
