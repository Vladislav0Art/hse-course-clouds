terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  required_version = ">= 1.00"
}

provider "random" {
}

provider "yandex" {
  zone      = "ru-central1-a"
  folder_id = "b1gqk4vp5c9t7a151qav"
}
