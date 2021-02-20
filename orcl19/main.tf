provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-b"
}

data "google_compute_default_service_account" "default" {
}

data "google_compute_image" "image-terra-ora" {
  provider = google-beta
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_instance" "terra-ora1" {
  provider = google-beta
  name           = "terra-inst-ora1"
  machine_type   = "e2-standard-2"
  zone           = "us-central1-b"
  can_ip_forward = false
  service_account {
     email = data.google_compute_default_service_account.default.email
     scopes = ["cloud-platform"]
     }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.image-terra-ora.self_link
    }
  }
  network_interface {
    network = "default"
    access_config {
   //network_tier = "PREMIUM"
    }

  }

  metadata_startup_script = <<EOF
yum install -y wget
cd /etc/yum.repo.d/
wget http://yum.oracle.com/public-yum-ol7.repo
yum install -y oracle-database-preinstall-19c openssl
EOF

}

