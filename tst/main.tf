provider "google" {
  project     = "postgretrial"
  region      = "us-central1"
  zone        = "us-central1-b"
}

data "google_compute_default_service_account" "default" {
}

data "google_compute_image" "image-terra-cent7" {
  provider = google-beta
  family  = "centos-7"
  project = "centos-cloud"

}

resource "google_service_account" "ora123" {
  account_id   = "ora123"
  display_name = "My Service Account"
}

resource "google_service_account_key" "orakey" {
  service_account_id = google_service_account.ora123.name
  private_key_type = "TYPE_PKCS12_FILE"
  key_algorithm = "KEY_ALG_RSA_2048"
}

resource "google_service_account_key" "orakey1" {
  service_account_id = google_service_account.ora123.name
  private_key_type = "TYPE_GOOGLE_CREDENTIALS_FILE"
  key_algorithm = "KEY_ALG_RSA_2048"
}


resource "google_compute_image" "image-base1" {
    name="image-base1"
    source_image=data.google_compute_image.image-terra-cent7.self_link

    guest_os_features {
      type = "MULTI_IP_SUBNET"
    }
}

resource "google_compute_instance" "terra-test-1" {
  provider = google-beta
  name           = "terra-test-01"
  machine_type   = "e2-standard-2"
  zone           = "us-central1-b"
  can_ip_forward = false
  service_account {
     email = data.google_compute_default_service_account.default.email
     scopes = ["cloud-platform"]
     }

  boot_disk {
    initialize_params {
      image = google_compute_image.image-base1.self_link
    }
  }
  network_interface {
    network = "default"
    access_config {
   //network_tier = "PREMIUM"
    }
  }
    metadata_startup_script = <<EOF
groupadd oinstall
useradd oracle -d /home/oracle -m -p $(echo "welcome1") -g oinstall
mkdir -p /home/oracle/.ssh
echo "${google_service_account_key.orakey.private_key}" > /home/oracle/.ssh/id_rsa
echo "${base64decode(google_service_account_key.orakey.public_key)}" > /home/oracle/.ssh/id_rsa.pub

echo "${google_service_account_key.orakey1.private_key}" > /home/oracle/.ssh/id_rsa1.sav
base64 --decode /home/oracle/.ssh/id_rsa1.sav | perl -ne 'print $1 if /"private_key".*BEGIN PRIVATE KEY-----(.*)-----END/ ' | tr -d '\\n'  > /home/oracle/.ssh/id_rsa1

echo "${base64decode(google_service_account_key.orakey1.private_key)}" > /home/oracle/.ssh/id_rsa1.decode

echo "${base64decode(google_service_account_key.orakey1.public_key)}" > /home/oracle/.ssh/id_rsa1.pub1
sed 's/-----BEGIN CERTIFICATE-----//' /home/oracle/.ssh/id_rsa1.pub1 | sed 's/-----END CERTIFICATE-----//' | tr -d '\n' >/home/oracle/.ssh/id_rsa1.pub

chown -R oracle:oinstall /home/oracle
chmod 0700 /home/oracle/.ssh
chmod og-r /home/oracle/.ssh/id_rsa
chmod og-r /home/oracle/.ssh/id_rsa.pub

chmod og-r /home/oracle/.ssh/id_rsa1
chmod og-r /home/oracle/.ssh/id_rsa1.pub

cat << EOL >> /etc/ssh/sshd_config
Match User oracle
       PubkeyAuthentication yes
       GSSAPIAuthentication no
EOL

systemctl restart sshd

#ssh-keygen -p -f /home/oracle/.ssh/id_rsa -P notasecret -N ""
su -l oracle -c "ssh-keygen -e -f /home/oracle/.ssh/id_rsa.pub >> /home/oracle/.ssh/authorized_keys"
EOF

}

output "key-out" {
  value = google_service_account_key.orakey
}

output "key-out1" {
  value = google_service_account_key.orakey1
}
