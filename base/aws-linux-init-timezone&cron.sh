## AWS EC2 인스턴스 Timezone 변경하기
#!/bin/sh
date
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# sudo vi /etc/sysconfig/clock
sudo echo 'ZONE="Asia/Seoul"
UTC=true' > /etc/sysconfig/clock

cat /etc/sysconfig/clock 

sudo yum install -y cronie
sudo systemctl status crond
sudo systemctl enable crond
sudo systemctl start crond
sudo systemctl status crond

sudo reboot
