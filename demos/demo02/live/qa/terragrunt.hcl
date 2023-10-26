terraform {
    source = "git::git@github.com:shaban-khan/az-tf-modules.git//modules/app-service?ref=v0.0.1"
}

inputs = {
    sku_name = "F1"
}