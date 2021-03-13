provider "google" {
  project     = "postgretrial"    
  region      = "us-central1"    
  zone        = "us-central1-b"    
}    

resource "google_compute_address" "pubnetwork" {
  name = "public-ipv4-address"
  address_type = "EXTERNAL"
}

##################################################
resource "google_compute_network" "priv_asm_net" {
  name = "my-asm-priv-network"
  auto_create_subnetworks = false
}

resource "google_compute_network" "priv_asm_net2" {
  name = "my-asm-priv-network2"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "priv-asm-firewall" {
  name    = "priv-asm-firewall"
  network = google_compute_network.priv_asm_net.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_subnetwork" "priv_asm_subnet" {
  name          = "my-asm-priv-subnet"
  region        = "us-central1"
  ip_cidr_range = "10.4.0.0/14"
  network       = google_compute_network.priv_asm_net.id
}

resource "google_compute_subnetwork" "priv_asm_subnet2" {
  name          = "my-asm-priv-subnet2"
  region        = "us-central1"
  ip_cidr_range = "192.168.2.0/24"
  network       = google_compute_network.priv_asm_net2.id
}


resource "google_compute_address" "addr1" {
  name         = "my-internal-address"
  subnetwork   = google_compute_subnetwork.priv_asm_subnet.id
  address_type = "INTERNAL"
  region       = "us-central1"
}

resource "google_compute_address" "addr2" {
  name         = "my-internal-address2"
  subnetwork   = google_compute_subnetwork.priv_asm_subnet2.id
  address_type = "INTERNAL"
  region       = "us-central1"
}


## end network

data "google_compute_default_service_account" "default" {
}

data "google_compute_image" "image-terra-ora" {
  provider = google-beta
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_disk" "disk-b" {
    name    = "disk-b1-data"
    type    = "pd-balanced"
    zone    = "us-central1-b"
    size    = "25"
}

resource "google_compute_disk" "disk-c" {
    name    = "disk-c1-data"
    type    = "pd-balanced"
    zone    = "us-central1-b"
    size    = "25"
}

resource "google_compute_disk" "disk-d" {
    name    = "disk-d1-data"
    type    = "pd-balanced"
    zone    = "us-central1-b"
    size    = "25"
}

resource "google_compute_disk" "disk-e" {
    name    = "disk-e1-data"
    type    = "pd-balanced"
    zone    = "us-central1-b"
    size    = "25"
}

data "google_compute_instance" "data-asm-1" {
  self_link = google_compute_instance.terra-asm-1.self_link
}

output "my-inst-1" {
  value = data.google_compute_instance.data-asm-1.network_interface.0.network_ip
}


resource "google_compute_instance" "terra-asm-1" {
  provider = google-beta
  name           = "terra-inst-asm-01"
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
    subnetwork = google_compute_subnetwork.priv_asm_subnet.self_link
    network_ip = google_compute_address.addr1.address
    access_config {
     nat_ip = google_compute_address.pubnetwork.address
   //network_tier = "PREMIUM"
    }
   }

  network_interface {
    #network = "default"
    subnetwork = google_compute_subnetwork.priv_asm_subnet2.self_link
    network_ip = google_compute_address.addr2.address
   }

  attached_disk {
        source      = google_compute_disk.disk-b.self_link
        device_name = google_compute_disk.disk-b.name
  }
  attached_disk {
        source      = google_compute_disk.disk-c.self_link
        device_name = google_compute_disk.disk-c.name
  }
  attached_disk {
        source      = google_compute_disk.disk-d.self_link
        device_name = google_compute_disk.disk-d.name
  }
  attached_disk {
        source      = google_compute_disk.disk-e.self_link
        device_name = google_compute_disk.disk-e.name
  }

  metadata_startup_script = <<EOF
echo "partitioning /sdb"
#parted -s /dev/sdb mklabel gpt
#parted -s /dev/sdb mkpart primary ext4 1Mib 1025Mib
#parted -s /dev/sdb resizepart 1 100%
parted /dev/sdb --script -- mklabel gpt mkpart primary 4096s 80%
parted /dev/sdb --script -- mkpart primary 80% 100%

echo "KERNEL==\"sdb\",  SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK1\"    OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
echo "KERNEL==\"sdb1\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK1_P1\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
echo "KERNEL==\"sdb2\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK1_P2\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
#mkfs -t ext4 /dev/sdb1
/sbin/partprobe /dev/sdb1
/sbin/partprobe /dev/sdb2


echo "partitioning /sdc"
#parted -s /dev/sdc mklabel gpt
#parted -s /dev/sdc mkpart primary ext4 1Mib 1025Mib
#parted -s /dev/sdc resizepart 1 100%
parted /dev/sdc --script -- mklabel gpt mkpart primary 4096s 80%
parted /dev/sdc --script -- mkpart primary 80% 100%

echo "KERNEL==\"sdc\",  SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK2\"    OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
echo "KERNEL==\"sdc1\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK2_P1\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
echo "KERNEL==\"sdc2\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK2_P2\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
#mkfs -t ext4 /dev/sdc1
/sbin/partprobe /dev/sdc1
/sbin/partprobe /dev/sdc2


echo "partitioning /sdd"
parted -s /dev/sdd mklabel gpt
parted -s /dev/sdd mkpart primary ext4 1Mib 1025Mib
parted -s /dev/sdd resizepart 1 100%
mkfs -t ext4 /dev/sdd1

#mkdir -p /mnt/diskb
#echo "UUID=`blkid /dev/sdb1 -o value | head -n 1` /mnt/diskb ext4 defaults 0 0" >>/etc/fstab
#echo "UUID=`blkid /dev/sdb2 -o value | head -n 1` /mnt/diskb ext4 defaults 0 0" >>/etc/fstab

#mkdir -p /mnt/diskc
#echo "UUID=`blkid /dev/sdc1 -o value | head -n 1` /mnt/diskc ext4 defaults 0 0" >>/etc/fstab

mkdir -p /mnt/diskd
echo "UUID=`blkid /dev/sdd1 -o value | head -n 1` /mnt/diskd ext4 defaults 0 0" >>/etc/fstab

echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Make swap"
echo "-----------------------------------------------------------------"
parted /dev/sde --script -- mklabel gpt mkpart primary linux-swap 4096s 4096Mib
sleep 5
/sbin/partprobe /dev/sde1
mkswap -v1 -L swap /dev/sde1
swapon /dev/sde1
sync

mount -a

sleep 10
/sbin/udevadm control --reload-rules
sleep 10
/sbin/partprobe /dev/sdb1
/sbin/partprobe /dev/sdb2
/sbin/udevadm control --reload-rules


echo "IP PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"
echo "addr1=${google_compute_address.addr1.address}"
echo "addr2=${google_compute_address.addr2.address}"
yum -y install wget
cd /etc/yum.repos.d/
wget http://yum.oracle.com/public-yum-ol7.repo
yum -y --nogpgcheck install  oracle-database-preinstall-19c openssl
yum -y --nogpgcheck install  deltarpm expect tree unzip zip
yum -y --nogpgcheck install  oracleasm-support
yum -y --nogpgcheck install  bc binutils compat-libcap1 compat-libstdc++-33 fontconfig-devel glibc glibc-devel ksh libaio libaio-devel libX11 libXau libXi libXtst libgcc librdmacm-devel libstdc++  libstdc++-devel libxcb make nfs-utils net-tools python python-configshell python-rtslib python-six smartmontools sysstat targetcli unixODBC chrony

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
groupadd asmadmin
groupadd asmoper
groupadd asmdba
groupadd backupdba
groupadd dgdba
groupadd kmdba
groupadd racdba
useradd oracle -d /home/oracle -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g oinstall -G dbaoper,dba,asmdba,backupdba,dgdba,kmdba,racdba
useradd grid   -d /home/grid   -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g oinstall -G dbaoper,dba,asmadmin,asmoper,asmdba

echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Set oracle and grid limits"
echo "-----------------------------------------------------------------"
cat << EOL >> /etc/security/limits.conf
# Grid user
grid soft nofile 131072
grid hard nofile 131072
grid soft nproc 131072
grid hard nproc 131072
grid soft core unlimited
grid hard core unlimited
grid soft memlock 98728941
grid hard memlock 98728941
grid soft stack 10240
grid hard stack 32768
# Oracle user
oracle soft nofile 131072
oracle hard nofile 131072
oracle soft nproc 131072
oracle hard nproc 131072
oracle soft core unlimited
oracle hard core unlimited
oracle soft memlock 98728941
oracle hard memlock 98728941
oracle soft stack 10240
oracle hard stack 32768
EOL

export GRID_BASE=/u01/app/grid
export DB_BASE=/u01/app/oracle
export GI_HOME=/u01/app/19.3.0.0/grid
export DB_HOME=/u01/app/oracle/product/19.3.0.0/dbhome_1

echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Create GI_HOME and DB_HOME directories"
echo "-----------------------------------------------------------------"
mkdir -p /u01/app/19.3.0.0/grid
mkdir -p /u01/app/oracle/product/19.3.0.0/dbhome_1
chown -R grid:oinstall /u01
chown -R grid:oinstall /u01/app/19.3.0.0/grid
chown -R oracle:oinstall /u01/app/oracle
chmod -R ug+rw /u01

echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Setup profiles"
echo "-----------------------------------------------------------------"

  cat >> /home/grid/.bash_profile << EOL
export ORACLE_HOME=$${GI_HOME}
export PATH=\$ORACLE_HOME/bin:$${PATH}
export ORACLE_SID=+ASM
EOL

    cat >> /home/oracle/.bash_profile << EOL
export ORACLE_HOME=$${DB_HOME}
export PATH=\$ORACLE_HOME/bin:$${PATH}
export ORACLE_SID=$${DB_NAME}_1
EOL

echo "-----------------------------------------------------------------"
echo "copy grid software binaries"
echo "-----------------------------------------------------------------"
gsutil cp gs://postgretrial-orcl/LINUX.X64_193000_grid_home.zip  /tmp

# unzip grid software
echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Unzip grid software"
echo "-----------------------------------------------------------------"
cd $${GI_HOME}
unzip -oq /tmp/LINUX.X64_193000_grid_home.zip
chown -R grid:oinstall $${GI_HOME}

# Install cvuqdisk package
yum install -y $${GI_HOME}/cv/rpm/cvuqdisk*.rpm

##install package for ASMLib
yum -y --nogpgcheck install kmod-oracleasm

/usr/sbin/oracleasm configure -u grid -g asmadmin -e -b -s y
/usr/sbin/oracleasm init

/usr/sbin/oracleasm createdisk ORCL_DISK1_P1 /dev/sdb1
/usr/sbin/oracleasm createdisk ORCL_DISK1_P2 /dev/sdb2

/usr/sbin/oracleasm createdisk ORCL_DISK2_P1 /dev/sdc1
/usr/sbin/oracleasm createdisk ORCL_DISK2_P2 /dev/sdc2


/usr/sbin/oracleasm scandisks
/usr/sbin/oracleasm listdisks

cat > /tmp/gi_installation.sh << EOL
$${GI_HOME}/gridSetup.sh -ignorePrereq -waitforcompletion -silent \\
    -responseFile $${GI_HOME}/install/response/gridsetup.rsp \\
    INVENTORY_LOCATION=/u01/app/oraInventory \\
    SELECTED_LANGUAGES=en,en_GB \\
EOL

cat >> /tmp/gi_installation.sh << EOL
    oracle.install.option=HA_CONFIG \\
EOL

cat >> /tmp/gi_installation.sh << EOL
    ORACLE_BASE=$${GRID_BASE} \\
    oracle.install.asm.OSDBA=asmdba \\
    oracle.install.asm.OSOPER=asmoper \\
    oracle.install.asm.OSASM=asmadmin \\
EOL

cat >> /tmp/gi_installation.sh << EOL
    oracle.install.crs.config.ClusterConfiguration=STANDALONE \\
    oracle.install.crs.config.configureAsExtendedCluster=false \\
    oracle.install.crs.config.clusterName=ol7-rac-c \\
EOL

cat >> /tmp/gi_installation.sh << EOL
    oracle_install_crs_ConfigureMgmtDB=false \\
EOL

cat >> /tmp/gi_installation.sh << EOL
    oracle.install.crs.config.gpnp.configureGNS=false \\
    oracle.install.crs.config.autoConfigureClusterNodeVIP=false \\
    oracle.install.asm.configureGIMRDataDG=false \\
    oracle.install.crs.config.useIPMI=false \\
    oracle.install.asm.storageOption=ASM \\
    oracle.install.asmOnNAS.configureGIMRDataDG=false \\
    oracle.install.asm.SYSASMPassword=welcome1 \\
    oracle.install.asm.diskGroup.name=DATA \\
    oracle.install.asm.diskGroup.redundancy=EXTERNAL \\
    oracle.install.asm.diskGroup.AUSize=4 \\
EOL

cat >> /tmp/gi_installation.sh << EOL
    oracle.install.asm.diskGroup.disksWithFailureGroupNames=/dev/oracleasm/disks/ORCL_DISK1_P1,,/dev/oracleasm/disks/ORCL_DISK2_P1, \\
    oracle.install.asm.diskGroup.disks=/dev/oracleasm/disks/ORCL_DISK1_P1,/dev/oracleasm/disks/ORCL_DISK2_P1 \\
    oracle.install.asm.diskGroup.diskDiscoveryString=/dev/oracleasm/disks/ORCL_* \\
EOL

cat >> /tmp/gi_installation.sh << EOL
    oracle.install.asm.gimrDG.AUSize=1 \\
    oracle.install.asm.monitorPassword=welcome1 \\
    oracle.install.crs.configureRHPS=false \\
    oracle.install.crs.config.ignoreDownNodes=false \\
    oracle.install.config.managementOption=NONE \\
    oracle.install.config.omsPort=0 \\
    oracle.install.crs.rootconfig.executeRootScript=false
EOL

chown -R grid:oinstall /tmp/gi_installation.sh

echo "-----------------------------------------------------------------"
echo -e "`date +%F' '%T`: Install GI software"
echo "-----------------------------------------------------------------"
su - grid /tmp/gi_installation.sh
$${GI_HOME}/perl/bin/perl -I $${GI_HOME}/perl/lib -I $${GI_HOME}/crs/install $${GI_HOME}/crs/install/roothas.pl

EOF
}