locals {
  location           = "asia-northeast1"
  roles_for_oidc_iam = ["roles/artifactregistry.writer", "roles/run.developer", "roles/iam.serviceAccountUser"]
  cloud_run_jobs_config = {
    sample_job = {
      tf_resource_key = "sample_job"
      name            = "sample-job"
      image           = "asia-northeast1-docker.pkg.dev/hobby-383808/deploy-cloud-run-job-example/sample-job:latest"
      envs = {
        _1 = {
          name  = "GCP_PROJECT"
          value = data.google_project.project.name
        }
        _2 = {
          name  = "GCP_LOCATION"
          value = local.location
        }
      }
    }
  }
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
    "google.subject"        = "assertion.sub"
    "attribute.repository"  = "assertion.repository"
    "attribute.environment" = "assertion.environment"
    "attribute.actor"       = "assertion.actor"
  }
}

resource "google_service_account_iam_member" "github_actions_iam_workload_identity_user1" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions.workload_identity_pool_id}/subject/repo:tsugumi-sys/deploy-cloud-run-job-example:environment:production"
}

resource "google_service_account_iam_member" "github_actions_iam_workload_identity_user2" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions.workload_identity_pool_id}/subject/repo:tsugumi-sys/deploy-cloud-run-job-example:ref:refs/heads/main"
}

resource "google_project_iam_member" "github_actions_iam_workload_identity_user" {
  for_each = toset(local.roles_for_oidc_iam)

  project = data.google_project.project.id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_artifact_registry_repository" "default" {
  location      = "asia-northeast1"
  repository_id = "deploy-cloud-run-job-example"
  format        = "DOCKER"
}

resource "google_cloud_run_v2_job" "default" {
  for_each = local.cloud_run_jobs_config

  name     = each.value.name
  location = local.location

  template {
    template {
      containers {
        image = each.value.image
        # gcp projcet, gcp location, vertex search index name
        dynamic "env" {
          for_each = each.value.envs

          content {
            name  = env.value.name
            value = env.value.value
          }
        }
      }
    }
  }
}
