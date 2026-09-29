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

module "service_plan" {
  source  = "codectl/plan/azure"
  version = "~> 1.0"

  plans = {
    dev = {
      name                = module.naming.app_service_plan.name_unique
      resource_group_name = module.rg.groups.demo.name
      location            = module.rg.groups.demo.location
      os_type             = "Linux"
      sku_name            = "B1"
    }
  }
}
