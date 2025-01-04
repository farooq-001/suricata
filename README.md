# suricata

echo 'export SPAN_PORT=enX0' >> ~/.bashrc

source ~/.bashrc

curl -sSL https://raw.githubusercontent.com/farooq-001/suricata/master/install-suricata.sh | bash

wget https://prod1-us.blusapphire.net/export/idsrules/idsrules.tar.gz -P /opt/sensor/conf/etc/capture

tar -zxvf /opt/sensor/conf/etc/capture/idsrules.tar.gz -C /opt/sensor/conf/etc/capture/

curl -sSL https://raw.githubusercontent.com/farooq-001/suricata/master/suricata-yml.sh | bash




