terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Get project data for default service account
data "google_project" "current" {
  project_id = var.project_id
}

# Get the default compute service account
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# Grant Compute Network Admin role to the default service account
resource "google_project_iam_member" "compute_network_admin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# VPC Network
resource "google_compute_network" "rke2_network" {
  name                    = "${var.cluster_name}-network"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "rke2_subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.rke2_network.id
}

# Firewall Rules - Allow internal communication
resource "google_compute_firewall" "rke2_internal" {
  name    = "${var.cluster_name}-internal"
  network = google_compute_network.rke2_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/24"]
}

# Firewall Rules - SSH access
resource "google_compute_firewall" "rke2_ssh" {
  name    = "${var.cluster_name}-ssh"
  network = google_compute_network.rke2_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ips
  target_tags   = ["rke2-cluster"]
}

# Firewall Rules - Kubernetes API access
resource "google_compute_firewall" "rke2_k8s_api" {
  name    = "${var.cluster_name}-k8s-api"
  network = google_compute_network.rke2_network.name

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = var.allowed_k8s_api_ips
  target_tags   = ["rke2-control-plane"]
}

# Firewall Rules - RKE2 supervisor API (for worker nodes to join)
resource "google_compute_firewall" "rke2_supervisor" {
  name    = "${var.cluster_name}-supervisor"
  network = google_compute_network.rke2_network.name

  allow {
    protocol = "tcp"
    ports    = ["9345"]
  }

  source_ranges = ["10.0.0.0/24"]
  target_tags   = ["rke2-control-plane"]
}

# Firewall Rules - Allow GCP Load Balancer health checks
resource "google_compute_firewall" "rke2_lb_health_check" {
  name    = "${var.cluster_name}-lb-health-check"
  network = google_compute_network.rke2_network.name

  allow {
    protocol = "tcp"
  }

  # GCP Load Balancer health check IP ranges
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["rke2-cluster"]
}

# Firewall Rules - HTTP/HTTPS access for Ingress
resource "google_compute_firewall" "rke2_ingress_http_https" {
  name    = "${var.cluster_name}-ingress-http-https"
  network = google_compute_network.rke2_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]  # Allow from internet
  target_tags   = ["rke2-cluster"]
}

# Control Plane Node
resource "google_compute_instance" "control_plane" {
  name         = "${var.cluster_name}-control-plane"
  machine_type = var.control_plane_machine_type
  zone         = var.zone

  allow_stopping_for_update = true

  tags = ["rke2-cluster", "rke2-control-plane"]

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.rke2_subnet.id
    
    access_config {
      # Ephemeral external IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  # Use default service account with full Cloud API access
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y curl vim
  EOF

  lifecycle {
    ignore_changes = [metadata_startup_script]
  }
}

# Worker Node 1
resource "google_compute_instance" "worker_1" {
  name         = "${var.cluster_name}-worker-1"
  machine_type = var.worker_machine_type
  zone         = var.zone

  allow_stopping_for_update = true

  tags = ["rke2-cluster", "rke2-worker"]

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.rke2_subnet.id
    
    access_config {
      # Ephemeral external IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  # Use default service account with full Cloud API access
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y curl vim
  EOF

  lifecycle {
    ignore_changes = [metadata_startup_script]
  }
}

# Worker Node 2
resource "google_compute_instance" "worker_2" {
  name         = "${var.cluster_name}-worker-2"
  machine_type = var.worker_machine_type
  zone         = var.zone

  allow_stopping_for_update = true

  tags = ["rke2-cluster", "rke2-worker"]

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.rke2_subnet.id
    
    access_config {
      # Ephemeral external IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  # Use default service account with full Cloud API access
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y curl vim
  EOF

  lifecycle {
    ignore_changes = [metadata_startup_script]
  }
}