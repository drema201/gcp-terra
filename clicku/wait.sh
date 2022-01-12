sudo -s <<EOF
while [ ! -f /etc/clickhouse-server/config.xml ]
do
        sleep  5;
done;
EOF
