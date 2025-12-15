# -----------------------------
# Enable required APIs
# -----------------------------
locals {
  services = [
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "artifactregistry.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

resource "google_project_service" "services" {
  for_each           = toset(local.services)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# -----------------------------
# Artifact Registry (Docker)
# -----------------------------
resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.ar_repo_name
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}

# -----------------------------
# Service Account for deploy
# -----------------------------
resource "google_service_account" "deploy_sa" {
  account_id   = "gha-deploy"
  display_name = "GitHub Actions Deploy SA"
  project      = var.project_id

  depends_on = [google_project_service.services]
}

# Minimal permissions for pushing images + deploying to GKE later
resource "google_project_iam_member" "deploy_sa_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.deploy_sa.email}"
}

# We'll use this later in Phase 2/3 (GKE)
resource "google_project_iam_member" "deploy_sa_gke_dev" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.deploy_sa.email}"
}

# -----------------------------
# Workload Identity Federation for GitHub Actions (OIDC)
# -----------------------------
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"

  depends_on = [google_project_service.services]
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  # Only allow tokens from THIS repo
  attribute_condition = "attribute.repository == \"${var.github_repo}\""
}

# Allow GitHub repo identities to impersonate the deploy SA
resource "google_service_account_iam_binding" "deploy_sa_wif" {
  service_account_id = google_service_account.deploy_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
  ]
}

module "gke" {
  source       = "../../modules/gke"
  project_id   = var.project_id
  region       = var.region
  cluster_name = var.cluster_name
}