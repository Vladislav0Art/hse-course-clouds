packer {
  required_plugins {
    yandex = {
      version = "~> 1"
      source  = "github.com/hashicorp/yandex"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "yandex" "ubuntu-nginx" {
  folder_id           = "b1gqk4vp5c9t7a151qav"
  source_image_family = "ubuntu-2204-lts"
  ssh_username        = "ubuntu"
  use_ipv4_nat        = true
  image_description   = "Ubuntu with Flask app and Nginx"
  image_family        = "ubuntu-2204-lts"
  image_name          = "ubuntu-flask-nginx-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  subnet_id           = "e9bpq6kn3g72er97gin9"
  disk_type           = "network-ssd"
  zone                = "ru-central1-a"
}

build {
  sources = ["source.yandex.ubuntu-nginx"]

  provisioner "ansible" {
    playbook_file = "./ansible/playbook.yml"
    user          = "ubuntu"
    use_proxy     = false

    extra_arguments = [
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3",
      "--extra-vars", "ansible_become_password=''"
    ]

    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_PIPELINING=True",
      "ANSIBLE_REMOTE_TMP=/tmp/.ansible/tmp"
    ]
  }
}
