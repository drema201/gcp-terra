provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-c"
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

  binding {
    role = "roles/owner"

    members = [
      "serviceAccount:${google_service_account.gkecli.email}",
    ]
  }

  binding {
    role = "roles/viewer"

    members = [
      "serviceAccount:${google_service_account.gkecli.email}",
    ]
  }

}

data "google_iam_policy" "dfltpolicy" {

  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "serviceAccount:${data.google_compute_default_service_account.default.email}",
    ]
  }

  binding {
    role = "roles/editor"

    members = [
      "serviceAccount:${data.google_compute_default_service_account.default.email}",
    ]
  }

  binding {
    role = "roles/owner"

    members = [
      "serviceAccount:${data.google_compute_default_service_account.default.email}",
    ]
  }

  binding {
    role = "roles/viewer"

    members = [
      "serviceAccount:${data.google_compute_default_service_account.default.email}",
    ]
  }


}

resource "google_service_account_iam_policy" "gke-account-iam" {
  service_account_id = google_service_account.gkecli.name
  policy_data        = data.google_iam_policy.gkepolicy.policy_data
}

resource "google_service_account_iam_policy" "gke-dflt-iam" {
  service_account_id = data.google_compute_default_service_account.default.name
  policy_data        = data.google_iam_policy.dfltpolicy.policy_data
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
  ip_cidr_range = "10.2.0.0/20"
  region        = "us-central1"
  network       = google_compute_network.gkenet.id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.22.48.0/22"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "10.33.44.0/22"
  }
}

resource "google_compute_network" "gkenet" {
  name                    = "gke-network"
  routing_mode = "REGIONAL"
  auto_create_subnetworks = false
//  auto_create_subnetworks = true
}

resource "google_container_cluster" "vpc_native_gke" {
  name               = "vpc-native-gke"
  location           = "us-central1"
  initial_node_count = 1
  remove_default_node_pool = true

  network    = google_compute_network.gkenet.id
  subnetwork = google_compute_subnetwork.gkesubnet.id

  ip_allocation_policy {
//    cluster_ipv4_cidr_block = "/20"
//    services_ipv4_cidr_block = "/20"
    services_secondary_range_name = google_compute_subnetwork.gkesubnet.secondary_ip_range.0.range_name
    cluster_secondary_range_name  = google_compute_subnetwork.gkesubnet.secondary_ip_range.1.range_name
  }
  networking_mode = "VPC_NATIVE"

  node_config {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gkecli.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

}


resource "google_container_node_pool" "vpc_native_gke_nodes" {
  name       = "vpcnativegkepool"
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