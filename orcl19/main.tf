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
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
useradd -u 54321 -g oinstall -G dba,oper oracle
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
mkdir -p /u02/oradata
chown -R oracle:oinstall /u01 /u02
chmod -R 775 /u01 /u02
gsutil cp  gs://postgretrial-orcl/* /tmp
export "ORACLE_BASE"="/opt/oracle"
export "ORACLE_HOME"="/opt/oracle/product/19c/dbhome_1"
export "ORACLE_SID"="ORCLCDB"
export "ORACLE_PDB"="ORCLPDB1"
export "ORACLE_CHARACTERSET"="AL32UTF8"
export "ORACLE_EDITION"="EE"
unzip /tmp/LINUX.X64_193000_db_home.zip -d $$ORACLE_HOME/
cp /tmp/db_install.rsp.tmpl /tmp/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|$$ORACLE_BASE|g" /tmp/db_install.rsp && \
sed -i -e "s|###ORACLE_HOME###|$$ORACLE_HOME|g" /tmp/db_install.rsp && \
sed -i -e "s|###ORACLE_EDITION###|$$ORACLE_EDITION|g" /tmp  /db_install.rsp && \
chown oracle:oinstall -R $$ORACLE_BASE
EOF
    
}    
    

resource "google_storage_bucket" "for-ora" {
  name          = "postgretrial-orcl"
  location      = "US"

  uniform_bucket_level_access = true

}