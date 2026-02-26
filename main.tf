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