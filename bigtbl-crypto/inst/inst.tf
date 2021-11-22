# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


provider "google" {
  region = "${var.region}"
  project = "${var.project_id}"
}

data "google_compute_default_service_account" "default" {
}


resource "google_compute_instance" "default" {
  project = "${var.project_id}"
  zone = "${var.zone}"
  name = "tf-compute-2"
  machine_type = "n2-standard-2"
  boot_disk {
    initialize_params {
      image = "centos-8"
      size = "30"
    }
  }


  metadata_startup_script = templatefile("${path.module}/startup-cent.tpl", {
    project_id = "${var.project_id}",
    region = "${var.region}",
    zone = "${var.zone}",
    BUCKET_NAME ="${var.BUCKET_NAME}",
    BUCKET_FOLDER = "${var.BUCKET_FOLDER}",
    bigtable_instance_name = "${var.bigtable_instance_name}",
    bigtable_table_name = "${var.bigtable_table_name}",
    bigtable_family_name = "${var.bigtable_family_name}"
  })

  network_interface {
    network = "default"
    access_config {
    }
  }

  service_account {
    email = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  // Apply the firewall rule to allow external IPs to access this instance
  tags = [
    "http-server"]


}




