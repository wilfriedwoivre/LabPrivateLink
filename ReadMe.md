# Lab Private Link

Use this repository to build a specific environment to test Private Link setup on an Azure environments

Don't forget to clean your resources after your tests.

Available template :

| Name | Description |
| -- | -- |
| Basic config | NsLookup from Virtual Machine to resolve Private endpoint for Azure Storage |
| External Access | Simulate access from other compute hosted on Azure or not |
| External Access DNS | Simulate failure from other compute hosted on Azure with usage of specific Private DNS Zone |
| DNS Resolver | Use a solution based of Azure DNS Resolver to solve the previous case |
