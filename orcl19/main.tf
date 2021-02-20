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
sleep 10    
yum -y install wget    
sleep 3    
cd /etc/yum.repos.d/    
wget http://yum.oracle.com/public-yum-ol7.repo    
yum -y --nogpgcheck install  oracle-database-preinstall-19c openssl    
EOF    
    
}    
    

resource "google_storage_bucket" "for-ora" {
  name          = "postgretrial-orcl"
  location      = "US"

  uniform_bucket_level_access = true

}