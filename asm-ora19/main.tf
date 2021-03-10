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
echo "KERNEL==\"sdb1\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK1_p1\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
echo "KERNEL==\"sdb2\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK1_p2\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
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
echo "KERNEL==\"sdc1\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK2_p1\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
echo "KERNEL==\"sdc2\", SUBSYSTEM==\"block\", SYMLINK+=\"ORCL_DISK2_p2\" OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"" >> /etc/udev/rules.d/70-persistent-disk.rules
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
groupadd -g 1001 oinstall
groupadd -g 1002 dbaoper
groupadd -g 1003 dba
groupadd -g 1004 asmadmin
groupadd -g 1005 asmoper
groupadd -g 1006 asmdba
groupadd -g 1007 backupdba
groupadd -g 1008 dgdba
groupadd -g 1009 kmdba
groupadd -g 1010 racdba
useradd oracle -d /home/oracle -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g 1001 -G 1002,1003,1006,1007,1008,1009,1010
useradd grid   -d /home/grid   -m -p $(echo "welcome1" | openssl passwd -1 -stdin) -g 1001 -G 1002,1003,1004,1005,1006

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
mkdir -p $${GI_HOME}
mkdir -p $${DB_HOME}
chown -R grid:oinstall /u01
chown -R grid:oinstall $${GRID_BASE}
chown -R oracle:oinstall $${DB_BASE}
chmod -R ug+rw /u01



EOF
}