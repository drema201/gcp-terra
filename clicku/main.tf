provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}

provider "null" {

}

data "google_compute_default_service_account" "default" {    
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network     = "default"

  allow {
    protocol = "tcp"
    ports    = ["8123"]
  }

  target_tags = ["clickout"]
  source_ranges = ["0.0.0.0/0"]

  enable_logging = true
  log_config {
    metadata="EXCLUDE_ALL_METADATA"
  }
}
    
data "google_compute_image" "image-terra-click" {
  provider = google-beta    
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}    
    
resource "google_compute_instance" "terra-click-1" {
  provider = google-beta    
  name           = "terra-inst-click-01"
  machine_type   = "e2-standard-2"    
  zone           = "us-central1-b"    
  can_ip_forward = false
  tags = ["clickout"]

  service_account {    
     email = data.google_compute_default_service_account.default.email    
     scopes = ["cloud-platform"]    
     }    
    
  boot_disk {    
    initialize_params {    
      image = data.google_compute_image.image-terra-click.self_link
    }    
  }    
  network_interface {    
    network = "default"    
    access_config {    
   //network_tier = "PREMIUM"    
    }    
    
  }    
    
  metadata_startup_script = <<EOF
sudo apt-get install zookeeperd
sleep 10
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4
sleep 1
echo "deb http://repo.yandex.ru/clickhouse/deb/stable/ main/" | sudo tee /etc/apt/sources.list.d/clickhouse.list
sudo apt update
echo -e "--======================================================================\n"
echo "install clickhouse"
echo -e "--======================================================================\n"
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install  clickhouse-server clickhouse-client
sleep 1
sudo sed -i 's@ <!-- <listen_host>0.0.0.0</listen_host> -->@<listen_host>0.0.0.0</listen_host>@g' /etc/clickhouse-server/config.xml
echo -e "--======================================================================\n"
echo "starting service"
echo -e "--======================================================================\n"
sudo service clickhouse-server start
sudo service clickhouse-server status


sleep 3

EOF

}

resource "google_compute_instance" "terra-click-2" {
  provider = google-beta
  name           = "terra-inst-click-02"
  machine_type   = "e2-standard-2"
  zone           = "us-central1-b"
  can_ip_forward = false
  tags = ["clickout"]

  service_account {
    email = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.image-terra-click.self_link
    }
  }
  network_interface {
    network = "default"
    access_config {
      //network_tier = "PREMIUM"
    }
  }
  metadata = {
    ssh-keys = "daviabidavi:ssh-rsa ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYawopcCxryps5HSvU9rxJp/uSeEW5PU1mjVvkoChPVIudso9vmn5kTVz5nCmnJ9yw2t/kd9Vh4TbLIGNrk1/IHlaW1W2S6WsRr6zyPPGZxgV+gjEpGsMuZpMixos4VWqPUsslO2nkZGK6fyoTG/WGgirFfC4z2qWLNK15kLjLS7JjNfkzHhkzAgCOe4hezm2qxob+5mMV9w6ju49VVNLcocqnfGg8qsSc2ICEtEQHvoS6cp4+MGs9t/8+ZRVz9nS5sO8NERMMvV9GjWGK99x2uhptT8559twauRaMdveyoXQrIVBURDteB3oljNVd7aVC4KxR/lwT5Fk4dt3FSrit daviabidavi"
  }

  metadata_startup_script = <<EOF
sudo apt-get -yq install zookeeperd
sleep 10
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4
sleep 1
echo "deb http://repo.yandex.ru/clickhouse/deb/stable/ main/" | sudo tee /etc/apt/sources.list.d/clickhouse.list
sudo apt update
echo -e "--======================================================================\n"
echo "install clickhouse"
echo -e "--======================================================================\n"
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install  clickhouse-server clickhouse-client
sleep 1
sed /
sudo sed -i 's@ <!-- <listen_host>0.0.0.0</listen_host> -->@<listen_host>0.0.0.0</listen_host>@g' /etc/clickhouse-server/config.xml
echo -e "--======================================================================\n"
echo "starting service"
echo -e "--======================================================================\n"
sudo service clickhouse-server start
sudo service clickhouse-server status


sleep 3

EOF

  provisioner "file" {
    source      = "config.xml"
    destination = "/tmp/config.xml"
    connection {
      host = "${google_compute_instance.terra-click-2.network_interface.0.access_config.0.nat_ip}"
      type = "ssh"
      user = "daviabidavi"
      private_key = "${file("~/.ssh/terra-davi")}"
    }    //connection_type         = "ssh"
  }

//  provisioner "file" {
//    source      = "1.sql"
//    destination = "/tmp/1.sql"
//    connection {
//      host = "${google_compute_instance.terra-click-2.network_interface.0.access_config.0.nat_ip}"
//      type = "ssh"
//      user = "daviabidavi"
//      private_key = "${file("~/.ssh/terra-davi")}"
//    }
//  }

}
output "my-key-1" {
  value = "${file("~/.ssh/terra-davi.pub")}"
}


//resource "null_resource" "copyfile" {
//
//}
