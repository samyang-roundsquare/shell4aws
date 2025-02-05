#!/usr/bin/sh
# 루트 사용자 변경 (간단하게 sudo -i 실행)
if [ "$(id -u)" -ne 0 ]; then
    echo "현재 사용자가 루트가 아닙니다. 루트 권한을 얻기 위해 sudo -i를 실행합니다."
    sudo -i
    if [ $? -ne 0 ]; then
        echo "sudo -i 실행에 실패했습니다. sudo로 스크립트를 다시 실행합니다."
        exec sudo bash "$0" "$@"
        exit
    fi
fi

## AWS EC2 인스턴스 Timezone 변경하기
# 초기 파일 삭제 및 링크
date
rm /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# sudo vi /etc/sysconfig/clock
echo 'ZONE="Asia/Seoul"
UTC=true' > /etc/sysconfig/clock
# cat <<EOF > /etc/sysconfig/clock
# ZONE="Asia/Seoul"
# UTC=true
# EOF
cat /etc/sysconfig/clock

if command -v apt-get &>/dev/null; then
    apt-get update && apt-get install -y cronie
elif command -v yum &>/dev/null; then
    yum updata -y && yum upgrade -y && yum install -y cronie
elif command -v dnf &>/dev/null; then
    dnf install -y cronie
elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm cronie
else
    echo "지원되지 않는 패키지 관리자입니다."

systemctl enable crond
systemctl start crond

## AWS EC2 인스턴스에 Docker Install 하기
# Docker Install
if command -v apt-get &>/dev/null; then
    apt-get install -y docker
elif command -v yum &>/dev/null; then
    yum install -y docker
elif command -v dnf &>/dev/null; then
    dnf install -y docker
elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm docker
else
    echo "지원되지 않는 패키지 관리자입니다."

# Docker group을 새로 만들고 ec2-user 그룹에 편입
usermod -aG docker ec2-user

# Docker 실행
service docker start
docker ps

# ec2-user 권한 추가
gpasswd -a $USER docker
newgrp docker
service docker restart
docker ps

# Docker Compose Plugin Install : AWS Linux
mkdir -p /usr/local/lib/docker/cli-plugins/
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version

# Compose 플러그인을 docker-compose 명령어로 사용하기
# sudo ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
alias docker-compose='docker compose --compatibility "$@"'
docker-compose version

# 시스템 리부팅
echo "시스템을 2초 후 리부팅합니다..."
sleep 2
reboot
