# RKE2 Cluster on GCP - Terraform Infrastructure

## မြန်မာဘာသာဖြင့် ရှင်းလင်းချက် (Burmese Documentation)

ဒီ Terraform code က GCP (Google Cloud Platform) ပေါ်မှာ RKE2 Kubernetes cluster အတွက် infrastructure ကို provision လုပ်ပေးပါတယ်။

---

## 🏗️ Architecture

```
                                    ┌─────────────────────┐
                                    │    Internet         │
                                    └──────────┬──────────┘
                                               │
                    ┌──────────────────────────┼──────────────────────────┐
                    │                   GCP Cloud                          │
                    │                                                      │
                    │  ┌────────────────────────────────────────────────┐ │
                    │  │         VPC: rke2-test-network                 │ │
                    │  │         Subnet: 10.0.0.0/24                    │ │
                    │  │                                                │ │
                    │  │  ┌─────────────┐ ┌─────────────┐ ┌───────────┐ │ │
                    │  │  │Control Plane│ │  Worker 1   │ │ Worker 2  │ │ │
                    │  │  │             │ │             │ │           │ │ │
                    │  │  │ e2-standard │ │ e2-standard │ │e2-standard│ │ │
                    │  │  │ -2          │ │ -2          │ │-2         │ │ │
                    │  │  │             │ │             │ │           │ │ │
                    │  │  │ Tags:       │ │ Tags:       │ │Tags:      │ │ │
                    │  │  │ -rke2-      │ │ -rke2-      │ │-rke2-     │ │ │
                    │  │  │  cluster    │ │  cluster    │ │ cluster   │ │ │
                    │  │  │ -rke2-      │ │ -rke2-      │ │-rke2-     │ │ │
                    │  │  │  control-   │ │  worker     │ │ worker    │ │ │
                    │  │  │  plane      │ │             │ │           │ │ │
                    │  │  └─────────────┘ └─────────────┘ └───────────┘ │ │
                    │  │                                                │ │
                    │  └────────────────────────────────────────────────┘ │
                    │                                                      │
                    │  ┌────────────────────────────────────────────────┐ │
                    │  │              Firewall Rules                     │ │
                    │  │  • SSH (22)           - allowed_ssh_ips         │ │
                    │  │  • K8s API (6443)     - allowed_k8s_api_ips     │ │
                    │  │  • Supervisor (9345)  - internal subnet         │ │
                    │  │  • HTTP/HTTPS (80,443)- 0.0.0.0/0              │ │
                    │  │  • LB Health Checks   - GCP LB IP ranges        │ │
                    │  │  • Internal (all)     - 10.0.0.0/24            │ │
                    │  └────────────────────────────────────────────────┘ │
                    │                                                      │
                    └──────────────────────────────────────────────────────┘
```

---

## 📁 Files

| File | ရှင်းလင်းချက် |
|------|-------------|
| `main.tf` | Main infrastructure - VPC, Firewall, Compute Instances |
| `variables.tf` | Input variables |
| `outputs.tf` | Output values (IPs, SSH commands) |
| `terraform.auto.tfvars` | Variable values (project ID, region, etc.) |

---

## 🔧 Resources Created

### 1. VPC Network
```hcl
google_compute_network.rke2_network
```
- **Name:** `${cluster_name}-network` (e.g., `rke2-test-network`)
- **Auto subnets:** Disabled (custom subnet)

### 2. Subnet
```hcl
google_compute_subnetwork.rke2_subnet
```
- **Name:** `${cluster_name}-subnet`
- **CIDR:** `10.0.0.0/24`
- **Region:** Variable (default: `us-central1`)

### 3. Firewall Rules

| Rule Name | Ports | Source | Target Tags | ရည်ရွယ်ချက် |
|-----------|-------|--------|-------------|------------|
| `rke2_internal` | All TCP/UDP/ICMP | `10.0.0.0/24` | All in VPC | Internal node communication |
| `rke2_ssh` | 22 | `allowed_ssh_ips` | `rke2-cluster` | SSH access |
| `rke2_k8s_api` | 6443 | `allowed_k8s_api_ips` | `rke2-control-plane` | Kubernetes API |
| `rke2_supervisor` | 9345 | `10.0.0.0/24` | `rke2-control-plane` | Worker join |
| `rke2_lb_health_check` | All TCP | `35.191.0.0/16`, `130.211.0.0/22` | `rke2-cluster` | GCP Load Balancer health checks |
| `rke2_ingress_http_https` | 80, 443 | `0.0.0.0/0` | `rke2-cluster` | HTTP/HTTPS Ingress |

### 4. Compute Instances

| Instance | Machine Type | Tags | Role |
|----------|-------------|------|------|
| `control_plane` | `e2-standard-2` | `rke2-cluster`, `rke2-control-plane` | K8s Control Plane |
| `worker_1` | `e2-standard-2` | `rke2-cluster`, `rke2-worker` | K8s Worker Node |
| `worker_2` | `e2-standard-2` | `rke2-cluster`, `rke2-worker` | K8s Worker Node |

### 5. IAM

```hcl
google_project_iam_member.compute_network_admin
```
- Default service account ကို `roles/compute.networkAdmin` role ပေးထားပါတယ်
- GCP Load Balancer integration အတွက် လိုအပ်ပါတယ်

---

## 📊 Variables

| Variable | Default | ရှင်းလင်းချက် |
|----------|---------|-------------|
| `project_id` | (required) | GCP Project ID |
| `region` | `us-central1` | GCP Region |
| `zone` | `us-central1-a` | GCP Zone |
| `cluster_name` | `rke2-test` | Cluster name prefix |
| `control_plane_machine_type` | `e2-standard-2` | Control plane VM size |
| `worker_machine_type` | `e2-standard-2` | Worker VM size |
| `os_image` | `ubuntu-os-cloud/ubuntu-2204-lts` | VM OS image |
| `disk_size_gb` | `50` | Boot disk size |
| `ssh_user` | `rke2admin` | SSH username |
| `ssh_public_key_path` | `~/.ssh/id_rsa.pub` | SSH public key path |
| `allowed_ssh_ips` | `["0.0.0.0/0"]` | IPs allowed SSH access |
| `allowed_k8s_api_ips` | `["0.0.0.0/0"]` | IPs allowed K8s API access |

---

## 📤 Outputs

| Output | ရှင်းလင်းချက် |
|--------|-------------|
| `control_plane_external_ip` | Control plane public IP |
| `control_plane_internal_ip` | Control plane internal IP |
| `worker_1_external_ip` | Worker 1 public IP |
| `worker_1_internal_ip` | Worker 1 internal IP |
| `worker_2_external_ip` | Worker 2 public IP |
| `worker_2_internal_ip` | Worker 2 internal IP |
| `ssh_command_control_plane` | SSH command for control plane |
| `ssh_command_worker_1` | SSH command for worker 1 |
| `ssh_command_worker_2` | SSH command for worker 2 |

---

## 🚀 Usage

### Prerequisites

1. **GCP Account** with billing enabled
2. **gcloud CLI** installed and authenticated
3. **Terraform** >= 1.0 installed
4. **SSH key pair** generated

### Step 1: Configure Variables

Create `terraform.auto.tfvars`:
```hcl
project_id          = "your-gcp-project-id"
region              = "asia-southeast1"
zone                = "asia-southeast1-a"
cluster_name        = "rke2-cluster"
ssh_user            = "rke2admin"
ssh_public_key_path = "./id_ed25519.pub"
allowed_ssh_ips     = ["YOUR_PUBLIC_IP/32"]
allowed_k8s_api_ips = ["YOUR_PUBLIC_IP/32"]
```

### Step 2: Initialize Terraform

```bash
cd rke2-cluster
terraform init
```

### Step 3: Plan

```bash
terraform plan
```

### Step 4: Apply

```bash
terraform apply
```

### Step 5: Get Outputs

```bash
terraform output

# Or specific output
terraform output control_plane_external_ip
```

---

## 🔥 Firewall Rules Explanation

### Why Each Rule is Needed (ဘာကြောင့် လိုအပ်လဲ)

#### 1. Internal Communication (`rke2_internal`)
- **Port:** All TCP/UDP/ICMP
- **Source:** `10.0.0.0/24` (subnet)
- **ရည်ရွယ်ချက်:** Kubernetes components (etcd, kubelet, CNI) တွေ အချင်းချင်း communicate လုပ်ဖို့

#### 2. SSH Access (`rke2_ssh`)
- **Port:** 22
- **Source:** `allowed_ssh_ips`
- **ရည်ရွယ်ချက်:** Remote management, RKE2 setup scripts run ဖို့

#### 3. Kubernetes API (`rke2_k8s_api`)
- **Port:** 6443
- **Source:** `allowed_k8s_api_ips`
- **ရည်ရွယ်ချက်:** kubectl remote access, CI/CD pipelines

#### 4. RKE2 Supervisor (`rke2_supervisor`)
- **Port:** 9345
- **Source:** `10.0.0.0/24`
- **ရည်ရွယ်ချက်:** Worker nodes က control plane ကို join ဖို့

#### 5. Load Balancer Health Checks (`rke2_lb_health_check`)
- **Port:** All TCP
- **Source:** `35.191.0.0/16`, `130.211.0.0/22`
- **ရည်ရွယ်ချက်:** GCP Load Balancer က nodes health စစ်ဖို့

**⚠️ ဒီ rule မရှိရင် LoadBalancer type services fail ဖြစ်ပါမယ်!**

#### 6. HTTP/HTTPS Ingress (`rke2_ingress_http_https`)
- **Port:** 80, 443
- **Source:** `0.0.0.0/0` (internet)
- **ရည်ရွယ်ချက်:** Web applications များ internet ကနေ access ဖို့

---

## 🔐 Service Account Configuration

```hcl
service_account {
  email  = data.google_compute_default_service_account.default.email
  scopes = ["cloud-platform"]
}
```

### ဘာကြောင့် Default Service Account သုံးလဲ?
1. **GCP API Access** - LoadBalancer, Persistent Disk creation
2. **Metadata Access** - Zone, Region info ယူဖို့
3. **Cloud Platform Scope** - Full API access for cloud integrations

### Compute Network Admin Role
```hcl
google_project_iam_member.compute_network_admin
```
- LoadBalancer creation အတွက် network admin permission လိုအပ်ပါတယ်

---

## 🔄 Lifecycle Settings

```hcl
allow_stopping_for_update = true

lifecycle {
  ignore_changes = [metadata_startup_script]
}
```

### `allow_stopping_for_update = true`
- Service account, machine type, network စတာတွေ change ရင် VM ကို auto-stop/restart လုပ်ပေးပါတယ်
- ဒီ setting မရှိရင် apply error ဖြစ်ပါမယ်

### `ignore_changes = [metadata_startup_script]`
- Startup script changes ကို ignore လုပ်ပါတယ်
- VM recreate မလုပ်ဘဲ safe ဖြစ်အောင်

---

## 🧹 Cleanup

```bash
# Destroy all resources
terraform destroy

# Force destroy (if stuck)
terraform destroy -auto-approve
```

---

## ⚠️ Security Recommendations

1. **SSH IPs ကို restrict လုပ်ပါ:**
   ```hcl
   allowed_ssh_ips = ["YOUR_IP/32"]  # Not 0.0.0.0/0
   ```

2. **K8s API IPs ကို restrict လုပ်ပါ:**
   ```hcl
   allowed_k8s_api_ips = ["YOUR_IP/32"]  # Not 0.0.0.0/0
   ```

3. **Private cluster သုံးဖို့ စဉ်းစားပါ:**
   - External IPs remove လုပ်ပြီး Cloud NAT သုံးပါ
   - VPN/Cloud IAP သုံးပြီး access လုပ်ပါ

---

## 📚 Next Steps

Infrastructure provision ပြီးရင်:

1. **RKE2 Install:**
   ```bash
   cd ../automation-scripts
   ./rke2.sh
   ```

2. **Verify Cluster:**
   ```bash
   ssh -i ~/.ssh/id_ed25519 rke2admin@<CONTROL_PLANE_IP>
   kubectl get nodes
   ```

3. **Fetch Kubeconfig:**
   ```bash
   ./fetch-kubeconfig.sh
   ```

---

## 📚 References

- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Compute Engine](https://cloud.google.com/compute/docs)
- [GCP VPC Firewall Rules](https://cloud.google.com/vpc/docs/firewalls)
- [GCP Load Balancer Health Checks](https://cloud.google.com/load-balancing/docs/health-checks)
- [RKE2 Documentation](https://docs.rke2.io/)
