resource "google_compute_network" "oraclient_net" {
  name = "oraclient-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "oraclient_subnet" {
  name          = "oraclient-subnetwork"
  region        = "us-central1"
  ip_cidr_range = "10.6.0.0/14"
  network       = google_compute_network.oraclient_net.id
}

resource "google_compute_address" "clnt_addr1" {
  name         = "my-internal-address"
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

resource "google_compute_firewall" "oraclient_fw" {
  name    = "oraclient-firewall"
  network     = google_compute_network.oraclient_net.name

  allow {
    protocol = "tcp"
    ports    = ["1521"]
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata="EXCLUDE_ALL_METADATA"
  }
}

resource "google_compute_instance" "terra-oraclnt-1" {    
  provider = google-beta    
  name           = "terra-oraclient-01"    
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
    #network = "default"
    subnetwork = google_compute_subnetwork.oraclient_subnet.self_link
    network_ip = google_compute_address.clnt_addr1.address
    access_config {
      //nat_ip = google_compute_address.pubnetwork.address
    }
  }

    
  metadata_startup_script = <<EOF
sleep 5
yum -y install wget
yum -y install zip unzip
sleep 3
cd /etc/yum.repos.d/
wget http://yum.oracle.com/public-yum-ol7.repo

echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Setup oracle and grid user"
echo "-----------------------------------------------------------------"

groupadd oinstall
groupadd dbaoper
groupadd dba
useradd oracle -d /home/oracle -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g oinstall -G dbaoper,dba

mkdir -p /opt/oracle
chown -R oracle:oinstall /opt/oracle
chmod -R 775 /opt/oracle

##copy binaries zip
cd /opt/oracle
wget https://download.oracle.com/otn_software/linux/instantclient/214000/instantclient-basic-linux.x64-21.4.0.0.0dbru.zip
wget https://download.oracle.com/otn_software/linux/instantclient/214000/instantclient-sqlplus-linux.x64-21.4.0.0.0dbru.zip
unzip instantclient-basic-linux.x64-21.4.0.0.0dbru.zip
unzip instantclient-sqlplus-linux.x64-21.4.0.0.0dbru.zip


echo "-----------------------------------------------------------------"
echo 'INSTALLER: START Environment variables '
echo "-----------------------------------------------------------------"

export PATH="$PATH:/opt/oracle/instantclient_21_4"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/oracle/instantclient_21_4"

echo "export PATH=\"$PATH:/opt/oracle/instantclient_21_4\"" >> /home/oracle/.profile
echo "export LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH:/opt/oracle/instantclient_21_4\"" >> /home/oracle/.profile

echo "-----------------------------------------------------------------"
echo 'INSTALLER: Environment variables set'
echo "-----------------------------------------------------------------"
. .profile

EOF
    
}    
    

