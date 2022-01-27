
data "google_compute_image" "image-terra-postgr" {
  provider = google-beta
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_instance" "terra-postgr-1" {
  provider = google-beta
  name = "terra-postgr-01"
  machine_type = "e2-small"
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
      image = data.google_compute_image.image-terra-postgr.self_link
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
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sleep 1
echo -e "--======================================================================\n"
echo "install postgresql"
echo -e "--======================================================================\n"

yum install -y postgresql13-server
sleep 1
/usr/pgsql-13/bin/postgresql-13-setup initdb

echo -e "--======================================================================\n"
echo "starting service"
echo -e "--======================================================================\n"
sudo systemctl enable postgresql-13
sudo systemctl start postgresql-13
sudo systemctl status postgresql-13
sleep 3

EOF
  provisioner "file" {
    source = "wait-pg.sh"
    destination = "/tmp/wait-pg.sh"
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

  provisioner "remote-exec" {
    inline = [
      "echo 'start remote'",
      "sudo chmod u+x /tmp/wait-pg.sh",
      "/tmp/wait-pg.sh",
      "sudo systemctl start postgresql-13",
      "sudo systemctl status postgresql-13",
      "echo 'start psql execution'",
      "su -l oracle -c 'psql --file=restore.sql'",
      "echo 'after psql execution'",
    ]
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      type = "ssh"
      user = var.mytfuser
      private_key = "${file("~/.ssh/terra-davi")}"
    }
  }

}



