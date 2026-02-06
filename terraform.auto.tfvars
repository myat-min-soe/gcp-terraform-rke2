project_id               = "project-54a94d06-9f0f-439b-82e"
region                   = "asia-southeast1"
zone                     = "asia-southeast1-b"
cluster_name             = "rke2"
control_plane_machine_type = "e2-medium"
worker_machine_type      = "e2-medium"
ssh_user                 = "rke2admin"
ssh_public_key_path      = "./id_ed25519.pub"

# IMPORTANT: Change these to your public IP for security!
# Get your IP: curl ifconfig.me
allowed_ssh_ips          = ["0.0.0.0/0"]
allowed_k8s_api_ips      = ["0.0.0.0/0"]