terraform {
  backend "gcs" {
    bucket = "ben-test-terraform-state-bucket"
    prefix = "terraform/gke/state"
  }
}

# 建立 GKE Standard 叢集 (測試用設定)
resource "google_container_cluster" "primary" {
  name     = "my-standard-cluster"
  location = "asia-east1-a" # 指定單一可用區以節省測試成本

  # 綁定網路團隊建立的 VPC 與 Subnet
  network    = "my-test-vpc"
  subnetwork = "subnet-tw"

  # 移除預設 Node Pool，我們將自訂 Node Pool
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false # 允許透過 Terraform 刪除叢集 (測試環境)
  # --- 關鍵新增部分：設定為私有叢集 ---
  private_cluster_config {
    enable_private_nodes    = true             # 核心：這會讓 Node 只有 Internal IP
    enable_private_endpoint = false            # 通常設為 false，以便你從外部透過 Public Endpoint 控管 Master
    master_ipv4_cidr_block  = "172.16.0.0/28"  # 指定給 Google 託管 Master 使用的專用網段
  } 
  # 建議加上 ip_allocation_policy 以啟用 VPC-native 模式 (Private Cluster 必要條件)
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }   
}


# 建立自訂的 Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "my-node-pool"
  location   = "asia-east1-a"
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "e2-medium" # 適合測試的機型
    disk_size_gb = 50
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}