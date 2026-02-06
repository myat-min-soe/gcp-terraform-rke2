output "control_plane_external_ip" {
  description = "External IP of control plane node"
  value       = google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip
}

output "control_plane_internal_ip" {
  description = "Internal IP of control plane node"
  value       = google_compute_instance.control_plane.network_interface[0].network_ip
}

output "worker_1_external_ip" {
  description = "External IP of worker node 1"
  value       = google_compute_instance.worker_1.network_interface[0].access_config[0].nat_ip
}

output "worker_1_internal_ip" {
  description = "Internal IP of worker node 1"
  value       = google_compute_instance.worker_1.network_interface[0].network_ip
}

output "worker_2_external_ip" {
  description = "External IP of worker node 2"
  value       = google_compute_instance.worker_2.network_interface[0].access_config[0].nat_ip
}

output "worker_2_internal_ip" {
  description = "Internal IP of worker node 2"
  value       = google_compute_instance.worker_2.network_interface[0].network_ip
}

output "ssh_command_control_plane" {
  description = "SSH command for control plane"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip}"
}

output "ssh_command_worker_1" {
  description = "SSH command for worker 1"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.worker_1.network_interface[0].access_config[0].nat_ip}"
}

output "ssh_command_worker_2" {
  description = "SSH command for worker 2"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.worker_2.network_interface[0].access_config[0].nat_ip}"
}