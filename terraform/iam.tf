locals {
  roles_for_oidc_iam = ["roles/artifactregistry.writer", "roles/run.developer"]
}

data "google_project" "project" {
}


resource "google_service_account" "github_actions" {
  account_id = "deploy-cloud-run-job-example"
}

resource "google_iam_workload_identity_pool" "github_actions" {
  workload_identity_pool_id = "deploy-cloud-run-job-example"
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  workload_identity_pool_provider_id = "github"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
  }
}

resource "google_service_account_iam_member" "github_actions_iam_workload_identity_user" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions.workload_identity_pool_id}/subject/repo:tsugumi-sys/deploy-cloud-run-job-example:ref:refs/heads/main"
}

resource "google_project_iam_member" "github_actions_iam_workload_identity_user" {
  for_each = toset(local.roles_for_oidc_iam)

  project = data.google_project.project.id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

