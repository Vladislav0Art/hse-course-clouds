
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
  required_version = ">= 1.0"
}

# env variables: YC_TOKEN, YC_CLOUD_ID, YC_FOLDER_ID
provider "yandex" {
  zone = var.zone
}
