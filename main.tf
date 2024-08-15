provider "google" {
  project     = "nomadic-girder-432605-v2"
  region      = "us-central1"
  credentials = "./nomadic-girder-432605-v2-5dfe42a3867e.json"
}

# Generate SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "terraform-key.pem"
}

# Create a VPC Network
resource "google_compute_network" "vpc_network" {
  name = "my-vpc-network"
}

# Create a Firewall Rule to Allow Port 22 (SSH)
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create a Firewall Rule to Allow Port 80 (HTTP)
resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create a VM Instance
resource "google_compute_instance" "vm_instance" {
  count        = 1
  name         = "vm-instance-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-jammy-v20230615"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name

    access_config {
      # This block allows SSH access through the external IP.
    }
  }

  metadata = {
    ssh-keys = "terraform:${tls_private_key.ssh_key.public_key_openssh}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo systemctl enable docker",
      "sudo systemctl start docker"
    ]

    connection {
      type        = "ssh"
      user        = "terraform"
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  tags = ["ssh"]
}

# Output the public IP of the instance
output "instance_ip" {
  value = google_compute_instance.vm_instance[0].network_interface[0].access_config[0].nat_ip
}
