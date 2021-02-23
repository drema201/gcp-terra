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
  name           = "terra-inst-ora-01"    
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
export "ORACLE_BASE"="/u01/app/oracle"
export "ORACLE_HOME"="/u01/app/oracle/product/19.0.0/dbhome_1"
export "ORACLE_SID"="ORCLCDB"
export "ORACLE_PDB"="ORCLPDB1"
export "ORACLE_CHARACTERSET"="AL32UTF8"
export "ORACLE_EDITION"="EE"

echo "export ORACLE_BASE=$ORACLE_BASE" >> /home/oracle/.bashrc && \
echo "export ORACLE_HOME=$ORACLE_HOME" >> /home/oracle/.bashrc && \
echo "export ORACLE_SID=$ORACLE_SID" >> /home/oracle/.bashrc   && \
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

unzip /tmp/LINUX.X64_193000_db_home.zip -d $ORACLE_HOME/
chown oracle:oinstall -R $ORACLE_BASE
echo 'INSTALLER: Permissions updated'
cp /tmp/db_install.rsp.tmpl /tmp/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /tmp/db_install.rsp && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /tmp/db_install.rsp && \
sed -i -e "s|###ORACLE_EDITION###|$ORACLE_EDITION|g" /tmp/db_install.rsp && \
chown oracle:oinstall -R $ORACLE_BASE
su -l oracle -c "yes | $ORACLE_HOME/runInstaller -silent -ignorePrereqFailure -waitforcompletion -responseFile /tmp/db_install.rsp"
$ORACLE_BASE/oraInventory/orainstRoot.sh
$ORACLE_HOME/root.sh

echo 'INSTALLER: Oracle software installed'

# create sqlnet.ora, listener.ora and tnsnames.ora
su -l oracle -c "mkdir -p $ORACLE_HOME/network/admin"
su -l oracle -c "echo 'NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)' > $ORACLE_HOME/network/admin/sqlnet.ora"

# Listener.ora
su -l oracle -c "echo 'LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
' > $ORACLE_HOME/network/admin/listener.ora"

su -l oracle -c "echo '$ORACLE_SID=localhost:1521/$ORACLE_SID' > $ORACLE_HOME/network/admin/tnsnames.ora"
su -l oracle -c "echo '$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)' >> $ORACLE_HOME/network/admin/tnsnames.ora"

# Start LISTENER
su -l oracle -c "lsnrctl start"

echo 'INSTALLER: Listener created'

# Create database

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=$${ORACLE_PWD:-"`openssl rand -base64 8`1"}

cp /tmp/dbca.rsp.tmpl /tmp/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /tmp/dbca.rsp && \
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /tmp/dbca.rsp && \
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /tmp/dbca.rsp && \
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /tmp/dbca.rsp

# Create DB
su -l oracle -c "dbca -silent -createDatabase -responseFile /tmp/dbca.rsp"

echo 'INSTALLER: Database created'

sed '$s/N/Y/' /etc/oratab | sudo tee /etc/oratab > /dev/null
echo 'INSTALLER: Oratab configured'

# configure systemd to start oracle instance on startup
sudo cp /tmp/oracle-rdbms.service /etc/systemd/system/
sudo sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/oracle-rdbms.service
sudo systemctl daemon-reload
sudo systemctl enable oracle-rdbms
sudo systemctl start oracle-rdbms
echo "INSTALLER: Created and enabled oracle-rdbms systemd's service"

sudo cp /tmp/setPassword.sh /home/oracle/ && \
sudo chmod a+rx /home/oracle/setPassword.sh

echo "INSTALLER: setPassword.sh file setup";
/home/oracle/setPassword.sh

echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";

EOF
    
}    
    

resource "google_storage_bucket" "for-ora" {
  name          = "postgretrial-orcl"
  location      = "US"

  uniform_bucket_level_access = true

}