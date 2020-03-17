cp startup.service /etc/systemd/system/startup.service
cp startup.sh /usr/local/bin

systemctl enable --now startup.service
