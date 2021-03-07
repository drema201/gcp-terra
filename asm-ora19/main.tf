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
}

resource "google_compute_subnetwork" "priv_asm_subnet" {
  name          = "my-asm-priv-subnet"
  region        = "us-central1"
  network       = google_compute_network.priv_asm_net.id
}

resource "google_compute_address" "privnetwork" {
  name         = "my-internal-address"
  subnetwork   = google_compute_subnetwork.priv_asm_subnet.id
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
    network_ip = google_compute_address.privnetwork.address
    access_config {    
     nat_ip = google_compute_address.pubnetwork.address
   //network_tier = "PREMIUM"    
    }
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
parted -s /dev/sdb mklabel gpt
parted -s /dev/sdb mkpart primary ext4 1Mib 1025Mib
parted -s /dev/sdb resizepart 1 100%
mkfs -t ext4 /dev/sdb1

echo "partitioning /sdc"
parted -s /dev/sdc mklabel gpt
parted -s /dev/sdc mkpart primary ext4 1Mib 1025Mib
parted -s /dev/sdc resizepart 1 100%
mkfs -t ext4 /dev/sdc1

echo "partitioning /sdd"
parted -s /dev/sdd mklabel gpt
parted -s /dev/sdd mkpart primary ext4 1Mib 1025Mib
parted -s /dev/sdd resizepart 1 100%
mkfs -t ext4 /dev/sdd1

mkdir -p /mnt/diskb
echo "UUID=`blkid /dev/sdb1 -o value | head -n 1` /mnt/diskb ext4 defaults 0 0" >>/etc/fstab

mkdir -p /mnt/diskc
echo "UUID=`blkid /dev/sdc1 -o value | head -n 1` /mnt/diskc ext4 defaults 0 0" >>/etc/fstab

mkdir -p /mnt/diskd
echo "UUID=`blkid /dev/sdd1 -o value | head -n 1` /mnt/diskd ext4 defaults 0 0" >>/etc/fstab

mount -a

echo "IP PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"

yum -y install wget
cd /etc/yum.repos.d/
wget http://yum.oracle.com/public-yum-ol7.repo
yum -y --nogpgcheck install  oracle-database-preinstall-19c openssl
yum -y --nogpgcheck install  deltarpm expect tree unzip zip 
yum -y --nogpgcheck install  oracleasm-support
yum -y --nogpgcheck install  bc binutils compat-libcap1 compat-libstdc++-33 fontconfig-devel glibc glibc-devel ksh libaio libaio-devel libX11 libXau libXi libXtst libgcc librdmacm-devel libstdc++  libstdc++-devel libxcb make nfs-utils net-tools python python-configshell python-rtslib python-six smartmontools sysstat targetcli unixODBC chrony

EOF
}