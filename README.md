# suricata

echo 'export SPAN_PORT=enX0' >> ~/.bashrc

source ~/.bashrc

curl -sSL https://raw.githubusercontent.com/farooq-001/suricata/master/install-suricata.sh | bash

wget http://172.31.252.1/export/idsrules/idsrules.tar.gz -P /opt/sensor/conf/etc/capture

tar -zxvf /opt/sensor/conf/etc/capture/idsrules.tar.gz -C /opt/sensor/conf/etc/capture/
