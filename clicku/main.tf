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
  name = "terra-inst-click-01"
  machine_type = "e2-standard-2"
  zone = "us-central1-b"
  can_ip_forward = false
  tags = [
    "clickout"]

  service_account {
    email = data.google_compute_default_service_account.default.email
    scopes = [
      "cloud-platform"]
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
    ssh-keys = "${var.mytfuser}:${trimspace(file("~/.ssh/terra-davi.pub"))}"
  }


  metadata_startup_script = <<EOF
sleep 2
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

sleep 5
echo -e "--======================================================================\n"
echo "install zookeeper"
echo -e "--======================================================================\n"

sudo apt-get -yq install zookeeperd

echo -e "--======================================================================\n"
echo "starting service"
echo -e "--======================================================================\n"
sudo service clickhouse-server start
sudo service clickhouse-server status


sleep 3

EOF
  provisioner "file" {
    source = "wait.sh"
    destination = "/tmp/wait.sh"
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

  provisioner "file" {
    //    source = "config.xml"
    content = templatefile("${path.module}/config.tpl.xml",{click_hosts = ["terra-inst-click-01", "terra-inst-click-02"], zooinst= "terra-inst-click-01", replica = "replica1"} )
    destination = "/tmp/config.xml"
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

  provisioner "file" {
    source = "sql/"
    destination = "/tmp"
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

}

resource "google_compute_instance" "terra-click-2" {
    provider = google-beta
    name = "terra-inst-click-02"
    machine_type = "e2-standard-2"
    zone = "us-central1-b"
    can_ip_forward = false
    tags = [
      "clickout"]

    service_account {
      email = data.google_compute_default_service_account.default.email
      scopes = [
        "cloud-platform"]
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
      ssh-keys = "${var.mytfuser}:${trimspace(file("~/.ssh/terra-davi.pub"))}"
    }

    metadata_startup_script = <<EOF
sleep 2
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

sleep 5
echo -e "--======================================================================\n"
echo "install zookeeper"
echo -e "--======================================================================\n"

sudo apt-get -yq install zookeeperd

echo -e "--======================================================================\n"
echo "starting service"
echo -e "--======================================================================\n"
sudo service clickhouse-server start
sudo service clickhouse-server status


sleep 3

EOF
  provisioner "file" {
    source = "wait.sh"
    destination = "/tmp/wait.sh"
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

  provisioner "file" {
//    source = "config.xml"
    content = templatefile("${path.module}/config.tpl.xml",{click_hosts = ["terra-inst-click-01", "terra-inst-click-02"], zooinst= "terra-inst-click-01", replica = "replica2"} )
    destination = "/tmp/config.xml"
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }
  provisioner "file" {
    source = "sql/"
    destination = "/tmp"
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

}

resource "null_resource" "rexec_all" {
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo chmod u+x /tmp/wait.sh",
      "/tmp/wait.sh",
      "sudo chown clickhouse:clickhouse /tmp/config.xml",
      "sudo mv /etc/clickhouse-server/config.xml /etc/clickhouse-server/config.xml.sav",
      "sudo cp -f /tmp/config.xml /etc/clickhouse-server/config.xml",
      "sudo service clickhouse-server restart",
    ]
    connection {
      host = "${google_compute_instance.terra-click-1.network_interface.0.access_config.0.nat_ip}"
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo chmod u+x /tmp/wait.sh",
      "/tmp/wait.sh",
      "sudo chown clickhouse:clickhouse /tmp/config.xml",
      "sudo mv /etc/clickhouse-server/config.xml /etc/clickhouse-server/config.xml.sav",
      "sudo cp -f /tmp/config.xml /etc/clickhouse-server/config.xml",
      "sudo service clickhouse-server restart",
    ]
    connection {
      host = "${google_compute_instance.terra-click-2.network_interface.0.access_config.0.nat_ip}"
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }
  depends_on = [google_compute_instance.terra-click-2,google_compute_instance.terra-click-1]
}

resource "null_resource" "rexec_sql_1" {
  provisioner "remote-exec" {
    inline = [
      "echo start sql apply [database]",
      "/usr/bin/clickhouse-client --queries-file /tmp/sql/00-create-databases.sql",    ]
    connection {
      host = "${google_compute_instance.terra-click-1.network_interface.0.access_config.0.nat_ip}"
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "echo start sql apply \\(database\\)",
      "/usr/bin/clickhouse-client --queries-file /tmp/sql/00-create-databases.sql",    ]
    connection {
      host = "${google_compute_instance.terra-click-2.network_interface.0.access_config.0.nat_ip}"
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

  provisioner "file" {
    source = "sql/"
    destination = "/tmp"
    connection {
      host = google_compute_instance.terra-click-1.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo start sql apply \\(1\\)",
      "echo start sql distributed ",
      "/usr/bin/clickhouse-client --queries-file /tmp/sql/1.sql",    ]
    connection {
      host = "${google_compute_instance.terra-click-1.network_interface.0.access_config.0.nat_ip}"
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

  depends_on = [null_resource.rexec_all]
}

data "google_project" "project" {
}


output "my-proj" {
  value = data.google_project.project
}

