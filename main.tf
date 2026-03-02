# 定義 Google Cloud Provider (使用 beta 版本以支援進階參數)
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
# ==========================================
# 1. GKE 叢集主體設定 (Control Plane & Configuration)
# ==========================================
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

# 指定 Kubernetes 版本與發布通道
  min_master_version = var.cluster_version
  release_channel {
    channel = "REGULAR"
  }

  # 綁定網路團隊建立的 VPC 與 Subnet
  network    = var.network
  subnetwork = var.subnetwork

# 啟用 VPC 原生叢集 (IP Alias) 與指定 Pod IP 網段
  ip_allocation_policy {
    cluster_ipv4_cidr_block = "/16"
  }

  # 停用節點內可視性
  enable_intranode_visibility = false

  # 私有叢集設定 (--enable-private-nodes)
  private_cluster_config {
    enable_private_nodes    = true # 這裡設定成true，則node就不會有public ip
    enable_private_endpoint = false # 這裡維持預設開啟外部 Endpoint，若需完全封閉請改為 true
  }
 # 安全性與存取控制
  security_posture_config {
    mode               = "BASIC" # 對應 --security-posture=standard
    vulnerability_mode = "VULNERABILITY_DISABLED" # 對應 --workload-vulnerability-scanning=disabled
  }
  
  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  # 擴充套件 (--addons)
  addons_config {
    horizontal_pod_autoscaling { disabled = false }
    http_load_balancing        { disabled = false }
    gce_persistent_disk_csi_driver_config { enabled = true }
    dns_cache_config           { enabled = true } # 對應 NodeLocalDNS
  }

  # 監控與日誌收集 (--logging & --monitoring)
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "STORAGE", "POD", "DEPLOYMENT", "STATEFULSET", "DAEMONSET", "HPA", "CADVISOR", "KUBELET", "DCGM"]
    # 備註：若 Terraform 執行時不認得 JOBSET，可以將其從上述陣列移除
    managed_prometheus {
      enabled = true
    }
  }

  default_max_pods_per_node = 110

  # 最佳實踐：移除預設節點池，並透過下方的 google_container_node_pool 獨立管理
  remove_default_node_pool = true
  initial_node_count       = var.initial_node_count
}

# ==========================================
# 2. GKE 節點池設定 (Worker Nodes)
# ==========================================
resource "google_container_node_pool" "primary_nodes" {
  provider = google-beta

  name       = "${var.cluster_name}-node-pool" # 讓節點池名稱跟隨叢集名稱自動變化
  location   = var.region
  cluster    = google_container_cluster.primary.name
  
  # 每個 Zone 的節點數 (區域級叢集在 3 個 Zone 建立，總節點數會是 3)
  initial_node_count = var.initial_node_count

  # 節點維護與升級策略
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  # 節點詳細規格
  node_config {
    machine_type = var.machine_type
    image_type   = "COS_CONTAINERD"

    disk_type    = "pd-standard"
    disk_size_gb = 100

    # 安全防護節點 (--enable-shielded-nodes)
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = false
    }

    # 中繼資料 (--metadata)
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # 服務帳戶與權限範圍 (對應 --no-enable-google-cloud-access，僅給予最基本且必須的存取權)
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }  
    

}