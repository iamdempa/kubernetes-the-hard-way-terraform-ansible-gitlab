# Provide 
provider "google" {
  credentials = file("token.json")
  project     = var.project_name
  region      = var.region
  zone        = var.zone
}

# Configure the backend
terraform {
  backend "gcs" {
    bucket      = "tf_backend_gcp_banuka_jana_jayarathna_k8s_hardway"
    prefix      = "terraform/state"
    credentials = "token.json"
  }
}

# create network (subnet)
resource "google_compute_network" "kubernetes-the-hard-way" {
  name = "kubernetes-the-hard-way"
  auto_create_subnetworks = false
}

# create subnetwork
resource "google_compute_subnetwork" "kubernetes" {
  name          = "kubernetes"
  ip_cidr_range = "10.240.0.0/24"
  region        = var.region
  network       = google_compute_network.kubernetes-the-hard-way.id
}

# firewall rules - internal
resource "google_compute_firewall" "kubernetes-the-hard-way-allow-internal" {
  name    = "kubernetes-the-hard-way-allow-internal"
  network = google_compute_network.kubernetes-the-hard-way.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]
}


# firewall rules - external
resource "google_compute_firewall" "kubernetes-the-hard-way-allow-external" {
  name    = "kubernetes-the-hard-way-allow-external"
  network = google_compute_network.kubernetes-the-hard-way.name


  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

# create a IP address 
resource "google_compute_address" "kubernetes-the-hard-way" {
  name = "kubernetes-the-hard-way"
}


# master node/s
resource "google_compute_instance" "controllers" {
  name         = "controller-0"
  machine_type = "e2-standard-2"
  zone         = var.zone

  can_ip_forward = true



  tags = ["kubernetes-the-hard-way", "controller"]
  

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20200720"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.kubernetes.name
    network_ip = "10.240.0.10"    
  }
  
  metadata_startup_script = <<-EOF
              #!/bin/bash    
              sudo apt-get update -y
              sudo apt-get install ansible -y  
              sudo apt install python -y
              sudo echo 'ok' > /root/hi.txt
              sudo mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys
              sudo echo "${file("/root/.ssh/id_rsa.pub")}" >> /root/.ssh/authorized_keys  
            EOF  

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write,monitoring"]
  }
}

# worker node/s
resource "google_compute_instance" "workers" {
  name         = "worker-0"
  machine_type = "e2-standard-2"
  zone         = var.zone

  can_ip_forward = true
  


  tags = ["kubernetes-the-hard-way", "worker"]
  

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20200720"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.kubernetes.name
    network_ip = "10.240.0.20"
  }

  metadata = {
    pod-cidr = "10.200.0.0/24"
  }
    
  metadata_startup_script = <<-EOF
              #!/bin/bash    
              sudo apt-get update -y
              sudo apt-get install ansible -y  
              sudo apt install python -y
              sudo echo 'ok' > /root/hi.txt
              sudo mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys
              sudo echo "${file("/root/.ssh/id_rsa.pub")}" >> /root/.ssh/authorized_keys  
            EOF  

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write,monitoring"]
  }
}