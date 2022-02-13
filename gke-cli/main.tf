provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}

provider "null" {

}

data "google_compute_default_service_account" "default" {    
}

resource "google_service_account" "gkecli" {
  account_id   = "mygkecli"
  display_name = "A service account for GKE"
}

data "google_iam_policy" "gkepolicy" {
  binding {
    role = "roles/compute.instanceAdmin"

    members = [
      "serviceAccount:${google_service_account.gkecli.email}",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "serviceAccount:${google_service_account.gkecli.email}",
    ]
  }

  binding {
    role = "roles/editor"

    members = [
      "serviceAccount:${google_service_account.gkecli.email}",
    ]
  }

}

resource "google_service_account_iam_policy" "admin-account-iam" {
  service_account_id = google_service_account.gkecli.name
  policy_data        = data.google_iam_policy.gkepolicy.policy_data
}

//resource "google_project_iam_binding" "project" {
//  project = "postgretrial"
//  role    = "roles/editor"
//
//  members = [
//    "serviceAccount:${google_service_account.gkecli.email}",
//  ]
//}

# Allow SA service account use the default GCE account
resource "google_service_account_iam_member" "gce-default-account-iam" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.gkecli.email}"
}


resource "google_compute_subnetwork" "gkesubnet" {
  name          = "test-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.gkenet.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.64.0/22"
  }
}

resource "google_compute_network" "gkenet" {
  name                    = "gke-network"
  auto_create_subnetworks = false
}

resource "google_container_cluster" "vpc_native_gke" {
  name               = "vpc-native-gke"
  location           = "us-central1"
  initial_node_count = 1
  remove_default_node_pool = true

  network    = google_compute_network.gkenet.id
  subnetwork = google_compute_subnetwork.gkesubnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "services-range"
    services_secondary_range_name = google_compute_subnetwork.gkesubnet.secondary_ip_range.1.range_name
  }

  node_config {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gkecli.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

}


resource "google_container_node_pool" "vpc_native_gke_nodes" {
  name       = "vpc_native_gke-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.vpc_native_gke.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gkecli.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}