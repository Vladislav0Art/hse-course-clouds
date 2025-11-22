variable "zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}
variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  default     = ""
}
variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  default     = ""
}
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "secure-pass-123"
}

data "yandex_client_config" "client" {}

locals {
  cloud_id  = var.cloud_id != "" ? var.cloud_id : data.yandex_client_config.client.cloud_id
  folder_id = var.folder_id != "" ? var.folder_id : data.yandex_client_config.client.folder_id
}

# VPC
resource "yandex_vpc_network" "app_network" {
  name        = "app-network"
  description = "Network for the application"
  folder_id   = local.folder_id
}

# subnet
resource "yandex_vpc_subnet" "app_subnet" {
  name           = "app-subnet"
  description    = "Subnet for application resources"
  folder_id      = local.folder_id
  zone           = var.zone
  network_id     = yandex_vpc_network.app_network.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

# service account
resource "yandex_iam_service_account" "app_sa" {
  name        = "app-service-account"
  description = "service account for application resources (description)"
  folder_id   = local.folder_id
}

# role for storage (bucket) access
resource "yandex_resourcemanager_folder_iam_member" "sa_storage_editor" {
  folder_id = local.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.app_sa.id}"
}

# role for compute resources
resource "yandex_resourcemanager_folder_iam_member" "sa_compute_admin" {
  folder_id = local.folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.app_sa.id}"
}

# static access key S3
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.app_sa.id
  description        = "static access key for object storage"
}

# object storage, S3 bucket
resource "yandex_storage_bucket" "app_bucket" {
  bucket     = "app-bucket-${local.folder_id}-${formatdate("YYYYMMDD", timestamp())}"
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

  anonymous_access_flags {
    read = false
    list = false
  }
}

# postgres
resource "yandex_mdb_postgresql_cluster" "app_db" {
  name        = "app-database"
  description = "PostgreSQL database for the application"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.app_network.id
  folder_id   = local.folder_id

  config {
    version = "14"
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 10
    }
  }

  host {
    zone      = var.zone
    subnet_id = yandex_vpc_subnet.app_subnet.id
  }
}

# db user
resource "yandex_mdb_postgresql_user" "app_db_user" {
  cluster_id = yandex_mdb_postgresql_cluster.app_db.id
  name       = "appuser"
  password   = var.db_password
}

# db
resource "yandex_mdb_postgresql_database" "app_database" {
  cluster_id = yandex_mdb_postgresql_cluster.app_db.id
  name       = "appdb"
  owner      = yandex_mdb_postgresql_user.app_db_user.name
}

# VM
resource "yandex_compute_instance" "app_vm" {
  name        = "app-server"
  description = "Application web server"
  folder_id   = local.folder_id
  zone        = var.zone

  platform_id = "standard-v2"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3" # Ubuntu 22.04 LTS
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app_subnet.id
    nat       = true
  }

  # demo website
  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
      packages:
        - nginx
      runcmd:
        - systemctl enable nginx
        - systemctl start nginx
        - echo "<h1>Application</h1>" > /var/www/html/index.html
    EOF
  }

  scheduling_policy {
    preemptible = true
  }
}

# outputs
output "vm_external_ip" {
  description = "external IP address of the VM"
  value       = yandex_compute_instance.app_vm.network_interface[0].nat_ip_address
}
output "vm_internal_ip" {
  description = "internal IP address of the VM"
  value       = yandex_compute_instance.app_vm.network_interface[0].ip_address
}
output "bucket_name" {
  description = "name of the S3 bucket"
  value       = yandex_storage_bucket.app_bucket.bucket
}
output "database_host" {
  description = "postgres database host"
  value       = yandex_mdb_postgresql_cluster.app_db.host[0].fqdn
}
output "database_name" {
  description = "postgres database name"
  value       = yandex_mdb_postgresql_database.app_database.name
}
output "service_account_id" {
  description = "service account ID"
  value       = yandex_iam_service_account.app_sa.id
}
output "storage_access_key" {
  description = "storage access key"
  value       = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  sensitive   = true
}
