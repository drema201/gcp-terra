sudo -s <<EOF
while [ ! -d /etc/sysconfig/pgsql ]
do
        sleep  5;
done;
EOF
