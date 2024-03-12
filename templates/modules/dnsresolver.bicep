param resourceLocation string = resourceGroup().location
param virtualNetworkId string
param subnets array
param storageDomainName string
param tags object = {}

resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: '${deployment().name}-dns-resolver'
  location: resourceLocation
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource inbountEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: resolver
  location: resourceLocation
  name: '${deployment().name}-inbound-endpoint'
  properties: {
    ipConfigurations: [
      {
        subnet: {
          id: subnets[0].id
        }
      }
    ]
  }
}

resource outbound 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: resolver
  location: resourceLocation
  name: '${deployment().name}-outbound-endpoint'
  properties: {
    subnet: {
      id: subnets[1].id
    }
  }
}

resource ruleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: '${deployment().name}-ruleset'
  tags: tags
  location: resourceLocation
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outbound.id
      }
    ]
  }
}

resource rule 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  parent: ruleset
  name: '${deployment().name}-google-rule'
  properties: {
    domainName: '${storageDomainName}.'
    targetDnsServers: [
      {
        ipAddress: '8.8.8.8'
      }
    ]
  }
}

resource vnetLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  parent: ruleset
  name: '${deployment().name}-vnet-link'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}
