module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"


  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.0.0.0/16"]
    dns_servers         = ["8.8.8.8", "7.7.7.7"]

    subnets = {
      sn1 = {
        address_prefixes = ["10.0.1.0/24"]
        delegations = {
          plan = {
            name    = "Microsoft.Web/hostingEnvironments"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      }
    }
  }
}

module "service_plan" {
  source  = "codectl/plan/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  plans = {
    isolated = {
      name                       = module.naming.app_service_plan.name_unique
      app_service_environment_id = module.ase_secure.environment.id
      os_type                    = "Windows"
      sku_name                   = "I2v2"
      worker_count               = 5
    }
  }
}

module "ase_secure" {
  source  = "codectl/plan/azure//modules/app-service-environment"
  version = "~> 1.0"

  environment = {
    name                         = module.naming.app_service_environment.name_unique
    resource_group_name          = module.rg.groups.demo.name
    subnet_id                    = module.network.subnets.sn1.id
    internal_load_balancing_mode = "Web, Publishing"
    zone_redundant               = true
    remote_debugging_enabled     = false

    cluster_settings = {
      disable_tls_10 = {
        name  = "DisableTls1.0"
        value = "1"
      }
      internal_encryption = {
        name  = "InternalEncryption"
        value = "true"
      }
      ssl_cipher_order = {
        name  = "FrontEndSSLCipherSuiteOrder"
        value = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
      }
    }

    tags = {
      Security   = "High"
      Compliance = "SOC2"
    }
  }
}
