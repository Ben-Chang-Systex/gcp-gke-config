variable "project_id" {
  type        = string
  description = "GCP 專案 ID"
}

variable "region" {
  type        = string
  description = "資源部署的 GCP 區域 (Region)"
  default     = "asia-east1"
}

variable "cluster_name" {
  type        = string
  description = "GKE 叢集名稱"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes 版本"
}

variable "network" {
  type        = string
  description = "VPC 網路名稱或路徑"
}

variable "subnetwork" {
  type        = string
  description = "子網路名稱或路徑"
}

variable "machine_type" {
  type        = string
  description = "工作節點的機器規格"
  default     = "e2-medium"
}

variable "initial_node_count" {
  type        = number
  description = "每個 Zone 的初始節點數量"
  default     = 1
}

variable "pod_ip_range_name" {
  type        = string
  description = "既有子網路中，預留給 Pod 使用的次要範圍名稱"
}

variable "service_ip_range_name" {
  type        = string
  description = "既有子網路中，預留給 Service 使用的次要範圍名稱"
}