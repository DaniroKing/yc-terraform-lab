# Используем уже созданную ранее сеть
resource "yandex_vpc_network" "terraform_net" {
 name = "tf-network"
}

# Создаем подсеть в существующей сети
resource "yandex_vpc_subnet" "terraform_subnet" {
  name           = "tf-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.terraform_net.id
  v4_cidr_blocks = ["10.130.0.0/24"]
} 

# Получаем актуальный ID образа Ubuntu 24.04
data "yandex_compute_image" "ubuntu" {
 family = "ubuntu-24-04-lts"
}

# Создаем виртуальную машину
resource "yandex_compute_instance" "vm_1" {
  name        = "tf-dev-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.terraform_subnet.id
    nat       = true
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: yc-user\n    sudo: 'ALL=(ALL) NOPASSWD:ALL'\n    shell: /bin/bash\n    ssh_authorized_keys:\n      - ${file("~/.ssh/id_ed25519.pub")}"
  }
}

# Вывод публичного IP после развертывания
output "external_ip" {
  value       = yandex_compute_instance.vm_1.network_interface[0].nat_ip_address
  description = "Public IP address of the VM"
}
