targetScope='subscription'

param userName string
@secure()
param password string

param expirationDate string= utcNow('yyyy-MM-dd')
param resourceLocation string = deployment().location


var tagsCustomerA = {
  environment: 'demo'
  lab: 'external-access'
  'lab-purpose': 'customer A'
}
var tagsCustomerB = {
  environment: 'demo'
  lab: 'external-access'
  'lab-purpose': 'customer B'
}


resource rgCustomerA 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'labprivatelink-${deployment().name}-customerA-rg'
  location: resourceLocation
  tags: {
    AutoDelete: 'true'
    ExpirationDate: expirationDate
  }
}

resource rgCustomerB 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'labprivatelink-${deployment().name}-customerB-rg'
  location: resourceLocation
  tags: {
    AutoDelete: 'true'
    ExpirationDate: expirationDate
  }
}

module customerA './modules/fullcustomer.bicep' = {
  name: '${deployment().name}-customerA'
  scope: rgCustomerA
  params: {
    userName: userName
    password: password
    tags: tagsCustomerA
    addressSpace: '10.0.0.0/24'
  }
}

module customerB './modules/fullcustomer.bicep' = {
  name: '${deployment().name}-customerB'
  scope: rgCustomerB
  params: {
    userName: userName
    password: password
    tags: tagsCustomerB
    noStorage: true
    noDnsResolver: false
    addressSpace: '10.1.0.0/24'
    customerAStorageName: '${customerA.outputs.storageName}.blob.core.windows.net'
  }
}

output rgName string = rgCustomerB.name
output vms array = customerB.outputs.vms
output storageName string = customerA.outputs.storageName
