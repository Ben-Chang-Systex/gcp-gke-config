terraform {
  backend "gcs" {
    # 填寫剛剛建立的 Bucket 名稱 (不需要 gs:// 前綴)
    bucket  = "ben-test-terraform-state-bucket"
    
    # Prefix 相當於資料夾路徑。
    # 這能讓同一個 Bucket 存放多個不同專案的狀態檔，這裡我們設定為 gke-cluster
    prefix  = "terraform/gke/state"
  }
}