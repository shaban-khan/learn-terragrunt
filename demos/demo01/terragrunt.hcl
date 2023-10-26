remote_state {
    backend = "azurerm"
    config = {
        key = "${path_relative_to_include()}/terraform.tfstate"
        resource_group_name = "skhan-tfstate"
        storage_account_name = "skhantfstatesa"
        container_name = "tgt-tfstate"
    }
}

inputs = {
    location = "westus"
    resource_group_name = "testResourceGroup1-10"
}