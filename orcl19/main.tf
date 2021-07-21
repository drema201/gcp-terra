provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}    

variable "VAR_ORA_BASE" {
description ="Base directory for Oracle software"
type=string
default="/u01/app/oracle"
}

variable "VAR_ORA_HOME" {
description ="Home directory for Oracle database"
type=string
default="/u01/app/oracle/product/19.0.0/dbhome_1"
}

variable "VAR_ORA_SID" {
description ="Oracle database SID"
type=string
default="ORCLCDB"
}

variable "VAR_ORA_PDB" {
description ="Oracle database PDB"
type=string
default="ORCLPDB"
}

variable "VAR_ORA_CHARSET" {
description ="Oracle database charset"
type=string
default="AL32UTF8"
}

variable "VAR_ORA_SGA" {
description ="Oracle instance SGA"
type=number
default=2000
}


variable "VAR_ORA_BUCKET" {
description ="Storage bucket where I keep Oracle database binaries"
type=string
default="postgretrial-orcl"
}

    
data "google_compute_default_service_account" "default" {    
}    
    
data "google_compute_image" "image-terra-ora" {    
  provider = google-beta    
  family  = "centos-7"    
  project = "centos-cloud"    
}    
    
resource "google_compute_instance" "terra-ora-1" {    
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
echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Setup oracle and grid user"
echo "-----------------------------------------------------------------"
userdel -fr oracle
groupdel oinstall
groupdel dba
groupdel backupdba
groupdel dgdba
groupdel kmdba
groupdel racdba

groupadd oinstall
groupadd dbaoper
groupadd dba
groupadd backupdba

useradd oracle -d /home/oracle -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g oinstall -G dbaoper,dba,backupdba
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
mkdir -p /u02/oradata
chown -R oracle:oinstall /u01 /u02
chmod -R 775 /u01 /u02

##copy binaries zip
gsutil cp  gs://${var.VAR_ORA_BUCKET}/* /tmp

export "ORACLE_BASE"="${var.VAR_ORA_BASE}"
export "ORACLE_HOME"="${var.VAR_ORA_HOME}"
export "ORACLE_SID"="${var.VAR_ORA_SID}"
export "ORACLE_PDB"="${var.VAR_ORA_PDB}"
export "ORACLE_CHARACTERSET"="${var.VAR_ORA_CHARSET}"
export "ORACLE_EDITION"="EE"

echo "export ORACLE_BASE=$ORACLE_BASE" >> /home/oracle/.bashrc && \
echo "export ORACLE_HOME=$ORACLE_HOME" >> /home/oracle/.bashrc && \
echo "export ORACLE_SID=$ORACLE_SID" >> /home/oracle/.bashrc   && \
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

unzip /tmp/LINUX.X64_193000_db_home.zip -d $ORACLE_HOME/
chown oracle:oinstall -R $ORACLE_BASE
echo 'INSTALLER: Permissions updated'

#Prepare install rsp
echo "oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0" >> /tmp/inst.rsp
echo "oracle.install.option=INSTALL_DB_SWONLY" >> /tmp/inst.rsp
echo "UNIX_GROUP_NAME=dba" >> /tmp/inst.rsp
echo "INVENTORY_LOCATION=${var.VAR_ORA_BASE}/oraInventory" >> /tmp/inst.rsp
echo "SELECTED_LANGUAGES=en" >> /tmp/inst.rsp
echo "ORACLE_BASE=${var.VAR_ORA_BASE}" >> /tmp/inst.rsp
echo "ORACLE_HOME=${var.VAR_ORA_HOME}" >> /tmp/inst.rsp
echo "oracle.install.db.InstallEdition=$ORACLE_EDITION" >> /tmp/inst.rsp
echo "oracle.install.db.DBA_GROUP=dba" >> /tmp/inst.rsp
echo "oracle.install.db.BACKUPDBA_GROUP=dba" >> /tmp/inst.rsp
echo "oracle.install.db.DGDBA_GROUP=dba" >> /tmp/inst.rsp
echo "oracle.install.db.KMDBA_GROUP=dba" >> /tmp/inst.rsp
echo "oracle.install.db.OSRACDBA_GROUP=dba" >> /tmp/inst.rsp
echo "oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=/u02/oradata" >> /tmp/inst.rsp
echo "SECURITY_UPDATES_VIA_MYORACLESUPPORT=false" >> /tmp/inst.rsp
echo "DECLINE_SECURITY_UPDATES=true" >> /tmp/inst.rsp
echo "oracle.installer.autoupdates.option=SKIP_UPDATES" >> /tmp/inst.rsp


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

#Generate database(DBCA) response file
echo "responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v19.0.0" >> /tmp/db.rsp
echo "gdbName=${var.VAR_ORA_SID}" >> /tmp/db.rsp
echo "sid=${var.VAR_ORA_SID}" >> /tmp/db.rsp
echo "databaseConfigType=SI" >> /tmp/db.rsp
echo "createAsContainerDatabase=true" >> /tmp/db.rsp
echo "numberOfPDBs=1" >> /tmp/db.rsp
echo "pdbName=${var.VAR_ORA_PDB}" >> /tmp/db.rsp
echo "pdbAdminPassword=$ORACLE_PWD" >> /tmp/db.rsp
echo "templateName=General_Purpose.dbc" >> /tmp/db.rsp
echo "sysPassword=$ORACLE_PWD" >> /tmp/db.rsp
echo "systemPassword=$ORACLE_PWD" >> /tmp/db.rsp
echo "emConfiguration=DBEXPRESS" >> /tmp/db.rsp
echo "emExpressPort=5500" >> /tmp/db.rsp
echo "dbsnmpPassword=$ORACLE_PWD" >> /tmp/db.rsp
echo "storageType=FS" >> /tmp/db.rsp
echo "characterSet=${var.VAR_ORA_CHARSET}" >> /tmp/db.rsp
echo "nationalCharacterSet=AL16UTF16" >> /tmp/db.rsp
echo "automaticMemoryManagement=FALSE" >> /tmp/db.rsp
echo "totalMemory=${var.VAR_ORA_SGA}" >> /tmp/db.rsp
echo "datafileDestination=/u02/oradata" >> /tmp/db.rsp
echo "# Some init.ora parameters - disable auditing to save space, enable FS optimizations" >> /tmp/db.rsp
echo "initParams=audit_trail=none,audit_sys_operations=false,filesystemio_options=setall,commit_logging=batch,commit_wait=nowait" >> /tmp/db.rsp


cp /tmp/dbca.rsp.tmpl /tmp/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /tmp/dbca.rsp && \
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /tmp/dbca.rsp && \
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /tmp/dbca.rsp && \
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /tmp/dbca.rsp

# Create DB
su -l oracle -c "dbca -silent -createDatabase -responseFile /tmp/db.rsp"

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