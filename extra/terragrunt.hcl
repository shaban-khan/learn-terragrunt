include {
  path = find_in_parent_folders()
}

dependency "subscription" {
  config_path = "../itaudev-connectivity-infradev-001"

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "show"]
  mock_outputs = {
    subscription_id = "90497414-153e-48f2-a3d3-7087c01353f0"
  }
}

# When using this terragrunt config, terragrunt will generate the file "provider.tf" with the aws provider block before
# calling to terraform. Note that this will overwrite the `provider.tf` file if it already exists.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents = <<EOF
provider "azurerm" {
  alias           = "sub_provider"
  subscription_id = "${dependency.subscription.outputs.subscription_id}"
  features {}
}
EOF
}

 locals {
   this_module_name = "${basename(get_terragrunt_dir())}"
   # Load environment-level variables from files in parents folders
   env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"))
   # Extract common variables for reuse
   location = local.env_vars.locals.location
   env_name    = local.env_vars.locals.env_name
   mghead   = local.env_vars.locals.mghead
   provider_version = "3.52.0"
   env          = "infradev"

  resource_groups = {
    resource_group_hub = {
        location    = local.location
        name        = "rg-hub-${local.location}-${local.env}-001"
    }
    resource_group_shared = {
        location    = local.location
        name        = "rg-shared-${local.location}-${local.env}-001"
    }
    resource_group_transit = {
        location    = local.location
        name        = "rg-transit-${local.location}-${local.env}-001"
    }
  }

  network_security_groups = {  
    nsg_hub_001 = {
        location            = local.location
        name                = "nsg-hub-${local.location}-${local.env}-001"
        resource_group_name = local.resource_groups.resource_group_hub.name
        security_rules      = []
    }
    nsg_hub_002 = {
        location            = local.location
        name                = "nsg-hub-${local.location}-${local.env}-002"
        resource_group_name = local.resource_groups.resource_group_hub.name
        security_rules      = []
    }
    nsg_hub_003 = {
        location            = local.location
        name                = "nsg-hub-${local.location}-${local.env}-003"
        resource_group_name = local.resource_groups.resource_group_hub.name
        security_rules      = []
    }
    nsg_shared = {
        location            = local.location
        name                = "nsg-shared-${local.env}-001"
        resource_group_name = local.resource_groups.resource_group_shared.name
        security_rules      = []
    }
    nsg_egress = {
        location            = local.location
        name                = "nsg-egress-${local.env}-001"
        resource_group_name = local.resource_groups.resource_group_transit.name
        security_rules      = []
    }
    nsg_ingress = {
        location            = local.location
        name                = "nsg-ingress-${local.env}-001"
        resource_group_name = local.resource_groups.resource_group_transit.name
        security_rules      = []
    }
    nsg_shared_transit = {
        location            = local.location
        name                = "nsg-shared-${local.env}-001"
        resource_group_name = local.resource_groups.resource_group_transit.name
        security_rules      = []
    }
  }

  virtual_networks = {
    vnet1 = {
        address_space       = ["10.1.48.0/24","10.128.50.0/25"]
        location            = local.location
        name                = "vnet-hub-${local.location}-${local.env}-001"
        resource_group_name = local.resource_groups.resource_group_hub.name
     }
     vnet_shared = {
        address_space       = ["10.1.0.0/20"]
        location            = local.location
        name                = "vnet-shared-${local.location}-${local.env}-001"
        resource_group_name = local.resource_groups.resource_group_shared.name
    }
    vnet_transit = {
        address_space       = ["10.128.63.0/24","10.128.60.0/25"]
        location            = local.location
        name                = "vnet-transit-${local.location}-${local.env}-001"
        resource_group_name = local.resource_groups.resource_group_transit.name
        dns_servers         = ["10.128.62.4"]
    }
  }

  subnets = {
     snet_untrust = {
        address_prefixes                          = ["10.1.48.0/27"]
        name                                      = "snet-hub-untrust-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_hub.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet1.name
        delegation           = []
    }
    snet_mgmt = {
        address_prefixes                          = ["10.128.50.0/26"]
        name                                      = "snet-hub-mgmt-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_hub.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet1.name
        delegation           = []
    }
    snet_trust = {
        address_prefixes                          = ["10.1.48.64/27"]
        name                                      = "snet-hub-trust-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_hub.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet1.name
        delegation           = []
    }
    snet_dns = {
        address_prefixes                          = ["10.1.48.96/27"]
        name                                      = "snet-hub-dns-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_hub.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet1.name
        delegation = [{
            name        = "Microsoft.Network.dnsResolvers"
            service_delegation = [{
                actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
                name    = "Microsoft.Network/dnsResolvers"
            }]
        }]
    }
    snet_bastion = {
        address_prefixes                          = ["10.1.48.128/26"]
        name                                      = "AzureBastionSubnet"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_hub.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet1.name
        delegation           = []
    }
    snet_shared = {
        address_prefixes                          = ["10.1.0.0/21"]
        name                                      = "snet-shared-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_shared.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_shared.name
        delegation                                = []
    }
    snet_bastion_transit = {
        address_prefixes                          = ["10.128.60.0/26"]
        name                                      = "AzureBastionSubnet"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        delegation           = []
    }
    snet_mgmt_transit = {
        address_prefixes                          = ["10.128.60.64/27"]
        name                                      = "snet-mgmt-transit-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        delegation           = []
    } 
    snet_egress_transit_001 = {
        address_prefixes                          = ["10.128.63.0/26"]
        name                                      = "snet-egress-transit-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        delegation                                = []
    }
    snet_egress_transit_002 = {
        address_prefixes                          = ["10.128.63.64/26"]
        name                                      = "snet-egress-transit-${local.location}-${local.env}-002"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        delegation                                = []
    }
    snet_egress_transit_003 = {
        address_prefixes                          = ["10.128.63.128/26"]
        name                                      = "snet-egress-transit-${local.location}-${local.env}-003"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        delegation                                = []
    }
    snet_egress_transit_004 = {
        address_prefixes                          = ["10.128.63.192/27"]
        name                                      = "snet-egress-transit-${local.location}-${local.env}-004"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        delegation                                = []
    }
    snet_ingress_transit = {
        address_prefixes                          = ["10.128.63.224/27"]
        name                                      = "snet-ingress-transit-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        delegation                                = []
    }
    snet_shared_transit = {
        address_prefixes                          = ["10.128.60.96/27"]
        name                                      = "snet-shared-transit-${local.location}-${local.env}-001"
        private_endpoint_network_policies_enabled = false
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        service_endpoints                         = []
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        delegation                                = []
    }
  }

  bastion_pubip = {
      bastion_pip = {
          name                                      = "pip-hub-${local.location}-${local.env}-001"
          location                                  = local.location
          resource_group_name                       = local.resource_groups.resource_group_hub.name
          allocation_method                         = "Static"
          sku                                       = "Standard"
      },
      bastion_pip_transit = {
          name                                      = "pip-transit-${local.location}-${local.env}-001"
          location                                  = local.location
          resource_group_name                       = local.resource_groups.resource_group_transit.name
          allocation_method                         = "Static"
          sku                                       = "Standard"
      }
  }

  bastion_hosts = {
      bastionhost = {
        name                                      = "bastion-hub-${local.location}-${local.env}-001"
        location                                  = local.location
        resource_group_name                       = local.resource_groups.resource_group_hub.name
        virtual_network_name                      = local.virtual_networks.vnet1.name
        subnet_name                               = local.subnets.snet_bastion.name
        bastion_host_sku                          = "Standard"
        scale_units                               = 2
        tunneling_enabled                         = true
        ip_configuration           = [{
            name                    = "pip-bastion-${local.env}-configuration-001"
            subnet_name             = local.subnets.snet_bastion.name
            bastion_pip_name        = local.bastion_pubip.bastion_pip.name
            virtual_network_name    = local.virtual_networks.vnet1.name
            resource_group_name     = local.resource_groups.resource_group_hub.name
            
        }]      
      }
      bastionhost_transit = {
        name                                      = "bastion-transit-${local.location}-${local.env}-001"
        location                                  = local.location
        resource_group_name                       = local.resource_groups.resource_group_transit.name
        virtual_network_name                      = local.virtual_networks.vnet_transit.name
        subnet_name                               = local.subnets.snet_bastion_transit.name
        bastion_host_sku                          = "Standard"
        scale_units                               = 2
        tunneling_enabled                         = true
        ip_configuration           = [{
            name                    = "pip-bastion-${local.env}-configuration-001"
            subnet_name             = local.subnets.snet_bastion_transit.name
            bastion_pip_name        = local.bastion_pubip.bastion_pip_transit.name
            virtual_network_name    = local.virtual_networks.vnet_transit.name
            resource_group_name     = local.resource_groups.resource_group_transit.name
        }]      
      }
  }
 
  private_dns_resolvers = {
    resolver = {
        location                = local.location
        name                    = "prn-hub-${local.location}-${local.env}-001"
        resource_group_name     = local.resource_groups.resource_group_hub.name
        virtual_network_name    = local.virtual_networks.vnet1.name
    }
  }

  private_dns_resolver_inbound_endpoints = {
    endpoint = {
        location                    = local.location
        name                        = "pe-hub-dns-${local.location}-${local.env}-001"
        private_dns_resolver_name   = local.private_dns_resolvers.resolver.name
        resource_group_name         = local.resource_groups.resource_group_hub.name
        ip_configurations           = [{
            virtual_network_name    = local.virtual_networks.vnet1.name
            resource_group_name     = local.resource_groups.resource_group_hub.name
            subnet_name             = local.subnets.snet_dns.name
        }]
    }
  }

  private_dns_zones = {
    dnsz_infradev = { 
      name  = "infradev.azure.cloud.ihf" 
      resource_group_name = local.resource_groups.resource_group_hub.name 
    }
    dnsz_dev = { 
      name  = "dev.azure.cloud.ihf" 
      resource_group_name = local.resource_groups.resource_group_hub.name 
    }
    dnsz_hom = { 
      name  = "hom.azure.cloud.ihf" 
      resource_group_name = local.resource_groups.resource_group_hub.name 
    }
    dnsz_prod = { 
      name  = "prod.azure.cloud.ihf" 
      resource_group_name = local.resource_groups.resource_group_hub.name 
    }
    afs                     = {
      name = "brazilsouth.privatelink.afs.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azurecr_001             = {
      name = "brazilsouth.privatelink.azurecr.io"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    adf                     = {
      name = "privatelink.adf.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azure_automation        = {
      name = "privatelink.agentsvc.azure-automation.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    analysis                = {
      name = "privatelink.analysis.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azureml                 = {
      name = "privatelink.api.azureml.ms"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    applicationinsights     = {
      name = "privatelink.applicationinsights.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azconfig                = {
      name = "privatelink.azconfig.io"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    api                     = {
      name = "privatelink.azure-api.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    automation              = {
      name = "privatelink.azure-automation.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azurecr_002             = {
      name = "privatelink.azurecr.io"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azuredatabricks         = {
      name = "privatelink.azuredatabricks.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    devices                 = {
      name = "privatelink.azure-devices.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    devices_provisioning    = {
      name = "privatelink.azure-devices-provisioning.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azurehdinsight          = {
      name = "privatelink.azurehdinsight.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azurestaticapps         = {
      name = "privatelink.azurestaticapps.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azuresynapse            = {
      name = "privatelink.azuresynapse.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azurewebsites           = {
      name = "privatelink.azurewebsites.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    batch                   = {
      name = "privatelink.batch.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    blob                    = {
      name = "privatelink.blob.core.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azmk8s                  = {
      name = "privatelink.brazilsouth.azmk8s.io"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    backup                  = {
      name = "privatelink.brazilsouth.backup.windowsazure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    kusto                   = {
      name = "privatelink.brazilsouth.kusto.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    cassandra               = {
      name = "privatelink.cassandra.cosmos.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    cognitiveservices       = {
      name = "privatelink.cognitiveservices.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    database                = {
      name = "privatelink.database.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    datafactory             = {
      name = "privatelink.datafactory.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    azuresynapse_dev        = {
      name = "privatelink.dev.azuresynapse.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    api_dev                 = {
      name = "privatelink.developer.azure-api.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    dfs                     = {
      name = "privatelink.dfs.core.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    dicom                   = {
      name = "privatelink.dicom.azurehealthcareapis.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    digitaltwins            = {
      name = "privatelink.digitaltwins.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    directline              = {
      name = "privatelink.directline.botframework.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    documents               = {
      name = "privatelink.documents.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    eventgrid               = {
      name = "privatelink.eventgrid.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    fhir                    = {
      name = "privatelink.fhir.azurehealthcareapis.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    file                    = {
      name = "privatelink.file.core.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    gremlin                 = {
      name = "privatelink.gremlin.cosmos.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    guestconfiguration      = {
      name = "privatelink.guestconfiguration.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    his                     = {
      name = "privatelink.his.arc.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    kubernetesconfiguration = {
      name = "privatelink.kubernetesconfiguration.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    managedhsm              = {
      name = "privatelink.managedhsm.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    mariadb                 = {
      name = "privatelink.mariadb.database.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    media                   = {
      name = "privatelink.media.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    mongo                   = {
      name = "privatelink.mongo.cosmos.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    monitor                 = {
      name = "privatelink.monitor.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    mysql                   = {
      name = "privatelink.mysql.database.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    notebooks               = {
      name = "privatelink.notebooks.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    ods                     = {
      name = "privatelink.ods.opinsights.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    oms                     = {
      name = "privatelink.oms.opinsights.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    openai                  = {
      name = "privatelink.openai.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    pbidedicated            = {
      name = "privatelink.pbidedicated.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    postgres                = {
      name = "privatelink.postgres.database.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    migration               = {
      name = "privatelink.prod.migration.windowsazure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    purview                 = {
      name = "privatelink.purview.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    purviewstudio           = {
      name = "privatelink.purviewstudio.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    queue                   = {
      name = "privatelink.queue.core.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    redis                   = {
      name = "privatelink.redis.cache.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    redisenterprise         = {
      name = "privatelink.redisenterprise.cache.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    search                  = {
      name = "privatelink.search.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    signalr                 = {
      name = "privatelink.service.signalr.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    servicebus              = {
      name = "privatelink.servicebus.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    siterecovery            = {
      name = "privatelink.siterecovery.windowsazure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    sql                     = {
      name = "privatelink.sql.azuresynapse.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    table                   = {
      name = "privatelink.table.core.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    table_cosmos            = {
      name = "privatelink.table.cosmos.azure.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    tip1                    = {
      name = "privatelink.tip1.powerquery.microsoft.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    token                   = {
      name = "privatelink.token.botframework.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    vaultcore               = {
      name = "privatelink.vaultcore.azure.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    web                     = {
      name = "privatelink.web.core.windows.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    workspace               = {
      name = "privatelink.workspace.azurehealthcareapis.com"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
    scm                     = {
      name = "scm.privatelink.azurewebsites.net"
      resource_group_name = local.resource_groups.resource_group_hub.name
    }
  }
 
  private_dns_zone_virtual_network_links = {
      dns_link_env = {
        name                    = "vnet-hub-${local.location}-${local.env}-link-001"
        private_dns_zone_name   = local.private_dns_zones["dnsz_${local.env}"].name
        resource_group_name     = local.resource_groups.resource_group_hub.name
        dns_resource_group_name = local.resource_groups.resource_group_hub.name
        virtual_network_name    = local.virtual_networks.vnet1.name
    }
  }

  subnet_network_security_group_associations = {
     untrust = {
         network_security_group_name = local.network_security_groups.nsg_hub_001.name
         resource_group_name         = local.resource_groups.resource_group_hub.name
         subnet_name                 = local.subnets.snet_untrust.name
         virtual_network_name        = local.virtual_networks.vnet1.name
    }
    snet_mgmt = {
         network_security_group_name = local.network_security_groups.nsg_hub_002.name
         resource_group_name         = local.resource_groups.resource_group_hub.name
         subnet_name                 = local.subnets.snet_mgmt.name
         virtual_network_name        = local.virtual_networks.vnet1.name
    }
    snet_dns = {
         network_security_group_name = local.network_security_groups.nsg_hub_003.name
         resource_group_name         = local.resource_groups.resource_group_hub.name
         subnet_name                 = local.subnets.snet_dns.name
         virtual_network_name        = local.virtual_networks.vnet1.name
    }
    shared_association = {
      network_security_group_name   = local.network_security_groups.nsg_shared.name
      resource_group_name           = local.resource_groups.resource_group_shared.name
      subnet_name                   = local.subnets.snet_shared.name
      virtual_network_name          = local.virtual_networks.vnet_shared.name
    }
    egress_transit_association_001 = {
      network_security_group_name   = local.network_security_groups.nsg_egress.name
      resource_group_name           = local.resource_groups.resource_group_transit.name
      subnet_name                   = local.subnets.snet_egress_transit_001.name
      virtual_network_name          = local.virtual_networks.vnet_transit.name
    }
    egress_transit_association_002 = {
      network_security_group_name   = local.network_security_groups.nsg_egress.name
      resource_group_name           = local.resource_groups.resource_group_transit.name
      subnet_name                   = local.subnets.snet_egress_transit_002.name
      virtual_network_name          = local.virtual_networks.vnet_transit.name
    }
    egress_transit_association_003 = {
      network_security_group_name   = local.network_security_groups.nsg_egress.name
      resource_group_name           = local.resource_groups.resource_group_transit.name
      subnet_name                   = local.subnets.snet_egress_transit_003.name
      virtual_network_name          = local.virtual_networks.vnet_transit.name
    }
    ingress_transit_association = {
      network_security_group_name   = local.network_security_groups.nsg_ingress.name
      resource_group_name           = local.resource_groups.resource_group_transit.name
      subnet_name                   = local.subnets.snet_ingress_transit.name
      virtual_network_name          = local.virtual_networks.vnet_transit.name
    }
    shared_transit_association = {
      network_security_group_name   = local.network_security_groups.nsg_shared_transit.name
      resource_group_name           = local.resource_groups.resource_group_transit.name
      subnet_name                   = local.subnets.snet_shared_transit.name
      virtual_network_name          = local.virtual_networks.vnet_transit.name
    }
 }

  nat_gateways = {
    natgtw1 = {
          location            = local.location
          name                = "natgtw-hub-${local.location}-${local.env}-001"
          resource_group_name = local.resource_groups.resource_group_hub.name
          ip_prefix_name      = "ipprefix-hub-${local.location}-${local.env}-001"
          prefix_length       = 30
    },
    natgtw2 = {
          location            = local.location
          name                = "natgtw-hub-mgmt-${local.location}-${local.env}-001"
          resource_group_name = local.resource_groups.resource_group_hub.name
          ip_prefix_name      = "ipprefix-hub-mgmt-${local.location}-${local.env}-001"
          prefix_length       = 31
    },
    natgtw3 = {
          location            = local.location
          name                = "natgtw-transit-${local.location}-${local.env}-001"
          resource_group_name = local.resource_groups.resource_group_transit.name
          ip_prefix_name      = "ipprefix-transit-${local.location}-${local.env}-001"
          prefix_length       = 31
    }
  }

  nat_gateway_subnet_associations = {
    association1 = {
      nat_gateway_name    = local.nat_gateways.natgtw1.name
      vnet_name           = local.virtual_networks.vnet1.name
      subnet_name         = local.subnets.snet_untrust.name
    }
    association2 = {
      nat_gateway_name    = local.nat_gateways.natgtw2.name
      vnet_name           = local.virtual_networks.vnet1.name
      subnet_name         = local.subnets.snet_mgmt.name
    }
    association_mgmt_transit = {
      nat_gateway_name    = local.nat_gateways.natgtw3.name
      vnet_name           = local.virtual_networks.vnet_transit.name
      subnet_name         = local.subnets.snet_mgmt_transit.name
    }
    association_egress01_transit = {
      nat_gateway_name    = local.nat_gateways.natgtw3.name
      vnet_name           = local.virtual_networks.vnet_transit.name
      subnet_name         = local.subnets.snet_egress_transit_001.name
    }
    association_egress02_transit = {
      nat_gateway_name    = local.nat_gateways.natgtw3.name
      vnet_name           = local.virtual_networks.vnet_transit.name
      subnet_name         = local.subnets.snet_egress_transit_002.name
    }
    association_egress03_transit = {
      nat_gateway_name    = local.nat_gateways.natgtw3.name
      vnet_name           = local.virtual_networks.vnet_transit.name
      subnet_name         = local.subnets.snet_egress_transit_003.name
    }
  }

  load_balancers = {
    paloalto_001 = {
      location            = local.resource_groups.resource_group_hub.location
      name                = "ilb-paloalto-hub-${local.location}-${local.env}-001"
      resource_group_name = local.resource_groups.resource_group_hub.name
      sku                 = "Standard"
      sku_tier            = "Regional"
      frontend_ips        = {
        hub_001 = {
          availability_zone             = ["1", "2", "3"]
          name                          = "fip-hub-${local.location}-${local.env}-001"
          private_ip_address_allocation = "static"
          private_ip_address            = cidrhost(local.subnets.snet_trust.address_prefixes[0], 6) # (Optional) Set null to get dynamic IP 
          subnet_name                   = local.subnets.snet_trust.name
        }
      }
    }
  }

  backend_address_pools = {
    hub_001 = {
      name                = "bep-hub-${local.location}-${local.env}-001"
      load_balancer_name  = local.load_balancers.paloalto_001.name
    }
  }

  load_balancer_probes = {
    hub_001 = {
      interval            = 5
      load_balancer_name  = local.load_balancers.paloalto_001.name
      name                = "lbr-hub-${local.location}-${local.env}-001"
      port                = "443"
      protocol            = "Https"
      request_path        = "/php/login.php"
      unhealthy_threshold = 2
    }
  }

  load_balancer_rules = {
     hub_001 = {
      backend_pool_name               = local.backend_address_pools.hub_001.name
      backend_port                    = 0
      disable_outbound_snat           = null
      enable_floating_ip              = null
      enable_tcp_reset                = null
      frontend_ip_configuration_name  = local.load_balancers.paloalto_001.frontend_ips.hub_001.name
      frontend_port                   = 0
      idle_timeout_in_minutes         = 5
      load_balancer_name              = local.load_balancers.paloalto_001.name
      load_balancer_probe_name        = local.load_balancer_probes.hub_001.name
      load_distribution               = "SourceIP"
      name                            = "lbr-hub-${local.location}-${local.env}-001"
      protocol                        = "All"
     }
  }

  load_balancer_nat_rules = {}

 palo_alto_nics1 = {
  "trust-nic-1" ={
    nic_name                      = "palo-alto-trust-nic-1"
    resource_group_name           = local.resource_groups.resource_group_hub.name
    location                      = local.location
    enable_accelerated_networking = true
    enable_ip_forwarding          = true
    backend_pool_name             = local.backend_address_pools.hub_001.name
    ip_configuration = [{
          nic_config_name        = "trust1"
          subnet_name             = local.subnets.snet_trust.name
          virtual_network_name    = local.virtual_networks.vnet1.name
          resource_group_name     = local.resource_groups.resource_group_hub.name
          primary                 = true
     }]
  },   
  "mgmt-nic-1" ={
    nic_name                      = "palo-alto-mgmt-nic-1"
    resource_group_name           = local.resource_groups.resource_group_hub.name
    location                      = local.location
    enable_accelerated_networking = true
    enable_ip_forwarding          = false
    backend_pool_name             = ""
    ip_configuration = [{
          nic_config_name         = "mgmt"
          subnet_name             = local.subnets.snet_mgmt.name
          virtual_network_name    = local.virtual_networks.vnet1.name
          resource_group_name     = local.resource_groups.resource_group_hub.name
          primary                 = false
        }]
  },
  "untrust-nic-1" ={
    nic_name                      = "palo-alto-untrust-nic-1"
    resource_group_name           = local.resource_groups.resource_group_hub.name
    location                      = local.location
    enable_accelerated_networking = true
    enable_ip_forwarding          = true
    backend_pool_name             = ""
    ip_configuration = [{
          nic_config_name         = "public"
          subnet_name             = local.subnets.snet_untrust.name
          virtual_network_name    = local.virtual_networks.vnet1.name
          resource_group_name     = local.resource_groups.resource_group_hub.name
          primary                 = false
        }]   
  }
}

palo_alto_nics2 = {
  "trust-nic-2" ={
    nic_name                      = "palo-alto-trust-nic-2"
    resource_group_name           = local.resource_groups.resource_group_hub.name
    location                      = local.location
    enable_accelerated_networking = true
    enable_ip_forwarding          = true
    backend_pool_name             = local.backend_address_pools.hub_001.name
    ip_configuration = [{
          nic_config_name        = "trust1"
          subnet_name             = local.subnets.snet_trust.name
          virtual_network_name    = local.virtual_networks.vnet1.name
          resource_group_name     = local.resource_groups.resource_group_hub.name
          primary                 = true
     }]
  },   
  "mgmt-nic-2" ={
    nic_name                      = "palo-alto-mgmt-nic-2"
    resource_group_name           = local.resource_groups.resource_group_hub.name
    location                      = local.location
    enable_accelerated_networking = true
    enable_ip_forwarding          = false
    backend_pool_name             = ""
    ip_configuration = [{
          nic_config_name         = "mgmt"
          subnet_name             = local.subnets.snet_mgmt.name
          virtual_network_name    = local.virtual_networks.vnet1.name
          resource_group_name     = local.resource_groups.resource_group_hub.name
          primary                 = false
        }]
  },
  "untrust-nic-2" ={
    nic_name                      = "palo-alto-untrust-nic-2"
    resource_group_name           = local.resource_groups.resource_group_hub.name
    location                      = local.location
    enable_accelerated_networking = true
    enable_ip_forwarding          = true
    backend_pool_name             = ""
    ip_configuration = [{
          nic_config_name         = "public"
          subnet_name             = local.subnets.snet_untrust.name
          virtual_network_name    = local.virtual_networks.vnet1.name
          resource_group_name     = local.resource_groups.resource_group_hub.name
          primary                 = false
        }]   
  }
}

palo_alto_instances1 = {
  palo-alto-vm1 = {
    vm_name        = "AZRBRL-${ upper(local.env) }-SM01"
    location = local.location
    resource_group_name = local.resource_groups.resource_group_hub.name
    admin_username = "paloaltovm1"
    nics = ["mgmt-nic-1","trust-nic-1","untrust-nic-1"]  
    zones = ["1"]
    primary_nic_name = "mgmt-nic-1"   
  }
 }

palo_alto_instances2 = {
  palo-alto-vm2 = {
    vm_name        = "AZRBRL-${ upper(local.env) }-SM02"
    resource_group_name = local.resource_groups.resource_group_hub.name
    location = local.location
    admin_username = "paloaltovm2"
    nics = ["mgmt-nic-2","trust-nic-2","untrust-nic-2"]  
    zones = ["2"]
    primary_nic_name = "mgmt-nic-2"
  }
 }

 palo_alto_img_version = "10.1.4"
    

  core_dns_virtual_network = {
    name                = "vnet-dns-${local.location}-prod-001"
    subscription_name   = "itau-connectivity-core-001"
    resource_group_name = "rg-dns-${local.location}-prod-001"
  }

  aks_private_dns_zones = {
    transit_aks = {
      suffix = ".privatelink.${local.location}.azmk8s.io"
      resource_group_name = local.resource_groups.resource_group_transit.name
    }
  }    

   key_vault = {
    name                = "kv-aks-transit-001"
    location            = local.location
    resource_group_name = local.resource_groups.resource_group_transit.name
    sku_name            = "standard"
    private_endpoint    = {
      name                          = "pe-transit-shared-${local.location}-${local.env}-001"
      approval_required             = null
      approval_message              = null
      subnet_name                   = local.subnets.snet_shared_transit.name
      virtual_network_name          = local.subnets.snet_shared_transit.virtual_network_name
      subnet_resource_group_name    = local.subnets.snet_shared_transit.resource_group_name
      private_connection_address_id = null
      group_ids                     = ["vault"]
      dnsz_ids                      = []
    }
  } 

  managed_identity = {
    identity_001 = {
        resource_group_name     = local.resource_groups.resource_group_transit.name
        name                    = "id-aks-${local.location}-${local.env}-001" 
        location                = local.location
    }
  }

  log_analytics_workspaces = {
    log_001 = {
      name  = "log-aks-transit-${local.location}-${local.env}-001"
      location  = local.location
      resource_group_name = local.resource_groups.resource_group_transit.name
      solution_name = "las-aks-transit-${local.location}-${local.env}-001"
    }
  }

  aks_clusters = {
    aks_001 = {
      name                = "aks-transit-${local.location}-${local.env}-001"
      resource_group_name = local.resource_groups.resource_group_transit.name
      location            = local.location
      dns_prefix          = "dnsprefix-aks-${local.location}-${local.env}-001"
      kubernetes_version  = "1.26.6"
      sku_tier            = "Standard"
      node_resource_group = "aks-noderg-${local.location}-${local.env}-001"
      log_analytics_workspaces_name = local.log_analytics_workspaces.log_001.name
      ssh_key_name        = "aks-sshkey-transit-${local.location}-${local.env}-001" 

      aks_default_pool = {
        name                         = "agentpool"
        vm_size                      = "Standard_DS3_V2"
        availability_zones           = [3]
        enable_auto_scaling          = true
        max_pods                     = 30
        os_disk_size_gb              = 128
        os_disk_type                 = "Ephemeral"
        networking_resource_group    = local.managed_identity.identity_001.resource_group_name
        enable_host_encryption       = false
        node_count                   = 1
        min_count                    = 1
        max_count                    = 3
        only_critical_addons_enabled = true
        resource_group_name          = local.resource_groups.resource_group_transit.name
        virtual_network_name         = local.virtual_networks.vnet_transit.name
        subnet_name                  = local.subnets.snet_egress_transit_001.name  
      }
      additional_node_pools = {
        pool_001 = {
            name                         = "nodepool001"
            vm_size                      = "Standard_DS3_V2"
            availability_zones           = ["3"]
            enable_auto_scaling          = true
            max_pods                     = 30
            os_disk_size_gb              = 128
            os_disk_type                 = "Ephemeral"
            enable_host_encryption       = false
            node_count                   = 1
            min_count                    = 1
            max_count                    = 3
            resource_group_name          = local.resource_groups.resource_group_transit.name
            virtual_network_name         = local.virtual_networks.vnet_transit.name
            subnet_name                  = local.subnets.snet_egress_transit_001.name  
        }
      }

      identity = {
        resource_group_name = local.managed_identity.identity_001.resource_group_name
        user_assigned_identity_name = local.managed_identity.identity_001.name
      }
    },
    aks_002 = {
      name                = "aks-transit-${local.location}-${local.env}-002"
      resource_group_name = local.resource_groups.resource_group_transit.name
      location            = local.location
      dns_prefix          = "dnsprefix-aks-${local.location}-${local.env}-002"
      kubernetes_version  = "1.26.6"
      sku_tier            = "Standard"
      node_resource_group = "aks-noderg-${local.location}-${local.env}-002"
      log_analytics_workspaces_name = local.log_analytics_workspaces.log_001.name
      ssh_key_name        = "aks-sshkey-transit-${local.location}-${local.env}-002" 

      aks_default_pool = {
        name                         = "agentpool"
        vm_size                      = "Standard_DS3_V2"
        availability_zones           = [3]
        enable_auto_scaling          = true
        max_pods                     = 30
        os_disk_size_gb              = 128
        os_disk_type                 = "Ephemeral"
        networking_resource_group    = local.resource_groups.resource_group_transit.name
        enable_host_encryption       = false
        node_count                   = 3
        min_count                    = 3
        max_count                    = 10
        only_critical_addons_enabled = true
        resource_group_name          = local.resource_groups.resource_group_transit.name
        virtual_network_name         = local.virtual_networks.vnet_transit.name
        subnet_name                  = local.subnets.snet_egress_transit_002.name  
      }
      additional_node_pools = {
        pool_001 = {
            name                         = "nodepool001"
            vm_size                      = "Standard_DS3_V2"
            availability_zones           = ["3"]
            enable_auto_scaling          = true
            max_pods                     = 30
            os_disk_size_gb              = 128
            os_disk_type                 = "Ephemeral"
            enable_host_encryption       = false
            node_count                   = 1
            min_count                    = 1
            max_count                    = 3
            resource_group_name          = local.resource_groups.resource_group_transit.name
            virtual_network_name         = local.virtual_networks.vnet_transit.name
            subnet_name                  = local.subnets.snet_egress_transit_001.name  
        }
      }

      identity = {
        resource_group_name = local.managed_identity.identity_001.resource_group_name
        user_assigned_identity_name = local.managed_identity.identity_001.name
      }
    },
    aks_003 = {
      name                = "aks-transit-${local.location}-${local.env}-003"
      resource_group_name = local.resource_groups.resource_group_transit.name
      location            = local.location
      dns_prefix          = "dnsprefix-aks-${local.location}-${local.env}-003"
      kubernetes_version  = "1.26.6"
      sku_tier            = "Standard"
      node_resource_group = "aks-noderg-${local.location}-${local.env}-003"
      log_analytics_workspaces_name = local.log_analytics_workspaces.log_001.name
      ssh_key_name        = "aks-sshkey-transit-${local.location}-${local.env}-003" 

      aks_default_pool = {
        name                         = "agentpool"
        vm_size                      = "Standard_DS3_V2"
        availability_zones           = [3]
        enable_auto_scaling          = true
        max_pods                     = 30
        os_disk_size_gb              = 128
        os_disk_type                 = "Ephemeral"
        networking_resource_group    = local.resource_groups.resource_group_transit.name
        enable_host_encryption       = false
        node_count                   = 3
        min_count                    = 3
        max_count                    = 10
        only_critical_addons_enabled = true
        resource_group_name          = local.resource_groups.resource_group_transit.name
        virtual_network_name         = local.virtual_networks.vnet_transit.name
        subnet_name                  = local.subnets.snet_egress_transit_003.name  
      }
      additional_node_pools = {
        pool_001 = {
            name                         = "nodepool001"
            vm_size                      = "Standard_DS3_V2"
            availability_zones           = ["3"]
            enable_auto_scaling          = true
            max_pods                     = 30
            os_disk_size_gb              = 128
            os_disk_type                 = "Ephemeral"
            enable_host_encryption       = false
            node_count                   = 1
            min_count                    = 1
            max_count                    = 3
            resource_group_name          = local.resource_groups.resource_group_transit.name
            virtual_network_name         = local.virtual_networks.vnet_transit.name
            subnet_name                  = local.subnets.snet_egress_transit_001.name  
        }
      }

      identity = {
        resource_group_name = local.managed_identity.identity_001.resource_group_name
        user_assigned_identity_name = local.managed_identity.identity_001.name
      }
    }
  }

  auto_scaler_profile = {
    expander                    = "random"
    scan_interval               = "10s"
    skip_nodes_with_system_pods = true
  }

  maintenance_window = null

  linux_profile = {
    admin_username = "azureaksadmin"
  }

  network_profile = {
    load_balancer_sku     = "standard"
    network_plugin_mode   = "Overlay"
    dns_service_ip        = "10.255.255.10"
    service_cidr          = "10.255.255.0/28"
    network_policy        = "azure"
    outbound_type         = "loadBalancer"
  }

  azure_active_directory_role_based_access_control = {
    managed            = true
    azure_rbac_enabled = false
    admin_group_object_ids = []
  }

}

terraform {
   source = "${get_parent_terragrunt_dir()}/modules//hub-core"
}

inputs = {
     subscription_id                            = dependency.subscription.outputs.subscription_id
     resource_groups                            = local.resource_groups
     network_security_groups                    = local.network_security_groups
     virtual_networks                           = local.virtual_networks
     subnets                                    = local.subnets
     private_dns_resolvers                      = local.private_dns_resolvers
     private_dns_resolver_inbound_endpoints     = local.private_dns_resolver_inbound_endpoints
     private_dns_zones                          = local.private_dns_zones
     private_dns_zone_virtual_network_links     = local.private_dns_zone_virtual_network_links
     bastion_pubip                              = local.bastion_pubip
     bastion_hosts                              = local.bastion_hosts
     subnet_network_security_group_associations = local.subnet_network_security_group_associations
     nat_gateways                               = local.nat_gateways
     nat_gateway_subnet_associations            = local.nat_gateway_subnet_associations               
     load_balancers                             = local.load_balancers
     backend_address_pools                      = local.backend_address_pools
     load_balancer_probes                       = local.load_balancer_probes
     load_balancer_rules                        = local.load_balancer_rules
     load_balancer_nat_rules                    = local.load_balancer_nat_rules
     palo_alto_nics1                            = local.palo_alto_nics1
     palo_alto_nics2                            = local.palo_alto_nics2
     palo_alto_instances1                       = local.palo_alto_instances1
     palo_alto_instances2                       = local.palo_alto_instances2
     img_version                                = local.palo_alto_img_version
     aks_clusters                                      = local.aks_clusters
     network_profile                                   = local.network_profile
     auto_scaler_profile                               = local.auto_scaler_profile
     maintenance_window                                = local.maintenance_window
     linux_profile                                     = local.linux_profile
     azure_active_directory_role_based_access_control  = local.azure_active_directory_role_based_access_control
     managed_identity                                  = local.managed_identity
     key_vault                                         = local.key_vault
     log_analytics_workspaces                          = local.log_analytics_workspaces
     environment                                       = local.env
     aks_private_dns_zones                             = local.aks_private_dns_zones
     core_dns_virtual_network                          = local.core_dns_virtual_network
}

