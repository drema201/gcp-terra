sudo -s <<EOF
while [ ! -f /var/lib/pgsql/13/data/postmaster.pid ]
do
        sleep  5;
done;
EOF
