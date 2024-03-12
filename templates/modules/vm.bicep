@maxLength(6)
param prefix string
@secure()
param password string
param subnetId string
param userName string
param tags object = {
}

param resourceLocation string = resourceGroup().location

resource pip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'vm-${prefix}-pip'
  location: resourceLocation
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'vm-${prefix}-nic'
  location: resourceLocation
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: prefix
  location: resourceLocation
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: substring('${prefix}${uniqueString(deployment().name)}', 0, 10)
      adminUsername: userName
      adminPassword: password
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}


output id string = vm.id
output name string = vm.name
