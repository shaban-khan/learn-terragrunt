# stage/terragrunt.hcl

remote_state {
    backend = "azurerm"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }
    config = {
        //subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        resource_group_name  = "skhan-tfstate"
        storage_account_name = "skhantfstatesa"
        container_name       = "skhantfstatesa"
        key                  = "${path_relative_to_include("site")}/terraform.tfstate"
    }
}

# Generate an Azure provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}