resource "google_compute_network" "oraclient_net" {
  name = "oraclient-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "oraclient_subnet" {
  name          = "oraclient-subnetwork"
  region        = "us-central1"
  ip_cidr_range = "192.168.2.0/24"
  network       = google_compute_network.oraclient_net.id
}

resource "google_compute_address" "clnt_addr1" {
  name         = "oraclnt-internal-address"
  subnetwork   = google_compute_subnetwork.oraclient_subnet.id
  address_type = "INTERNAL"
  region       = "us-central1"
}

resource "google_compute_firewall" "oraclient_ssh_fw" {
  name    = "oraclient-ssh-firewall"
  network = google_compute_network.oraclient_net.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "oraclient_egress" {
  name    = "oraclient-egress"
  network = google_compute_network.oraclient_net.name
  direction = "EGRESS"
  priority = 100

  allow {
    protocol = "tcp"
    ports    = ["1521","22", "80", "443"]
  }
  destination_ranges = ["0.0.0.0/0"]
//  target_tags = ["orcl"]
  target_service_accounts = [google_service_account.oraclnt.email]
  log_config {
    metadata="EXCLUDE_ALL_METADATA"
  }

}

resource "google_compute_firewall" "oraclient_egress_deny" {
  name    = "oraclient-egress-deny"
  network = google_compute_network.oraclient_net.name
  direction = "EGRESS"
  priority = 30000

  deny {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  destination_ranges = ["0.0.0.0/0"]
//  target_tags = ["orcl"]

  log_config {
    metadata="EXCLUDE_ALL_METADATA"
  }

}

resource "google_service_account" "oraclnt" {
  account_id   = "oraclient"
  display_name = "A service account for Oracle clients"
}

resource "google_service_account_iam_binding" "oraclnt-account-iam" {
  service_account_id = google_service_account.oraclnt.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "user:daviabidavi@gmail.com",
  ]
}


resource "google_compute_instance" "terra-oraclnt-1" {    
  provider = google-beta    
  name           = "terra-oraclient-02"
  machine_type   = "e2-standard-2"
  zone           = "us-central1-b"    
  can_ip_forward = false
  tags = ["orcl-client"]

  service_account {
     email = google_service_account.oraclnt.email
     scopes = ["cloud-platform"]    
     }    
    
  boot_disk {    
    initialize_params {    
      image = data.google_compute_image.image-terra-ora.self_link    
    }    
  }
  network_interface {
    #network = "default"
    subnetwork = google_compute_subnetwork.oraclient_subnet.self_link
    network_ip = google_compute_address.clnt_addr1.address
    access_config {
      //nat_ip = google_compute_address.pubnetwork.address
    }
  }

    
  metadata_startup_script = <<EOF
sleep 5
echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Yum installations"
echo "-----------------------------------------------------------------"

sudo yum -y install wget zip unzip libaio

cd /etc/yum.repos.d/
wget http://yum.oracle.com/public-yum-ol7.repo

echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Setup oracle and grid user"
echo "-----------------------------------------------------------------"

sudo yum -y install oracle-release-el7
sudo yum -y install oracle-instantclient19.10-basic

echo "-----------------------------------------------------------------"
echo 'INSTALLER: Environment variables set'
echo "-----------------------------------------------------------------"
. .bashrc

EOF
    
}    
    

