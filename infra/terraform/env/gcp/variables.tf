variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

# GitHub repo that will deploy (format: "owner/repo")
variable "github_repo" {
  type = string
}

# Artifact Registry repo name
variable "ar_repo_name" {
  type    = string
  default = "py-api"
}

variable "cluster_name" {
  type    = string
  default = "py-gke-demo"
}