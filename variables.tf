variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name prefix for the cluster resources"
  type        = string
  default     = "rke2-test"
}

variable "control_plane_machine_type" {
  description = "Machine type for control plane node"
  type        = string
  default     = "e2-standard-2" # 2 vCPU, 8GB RAM
}

variable "worker_machine_type" {
  description = "Machine type for worker nodes"
  type        = string
  default     = "e2-standard-2" # 2 vCPU, 8GB RAM
}

variable "os_image" {
  description = "OS image for the VMs"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "rke2admin"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_ips" {
  description = "List of IPs allowed to SSH (use your public IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for security!
}

variable "allowed_k8s_api_ips" {
  description = "List of IPs allowed to access Kubernetes API"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for security!
}