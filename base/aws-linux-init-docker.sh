## AWS EC2 인스턴스에 Docker Install 하기
#!/bin/sh

# yum update & upgrade
sudo yum update -y
sudo yum upgrade -y

# Docker Install
sudo yum install docker -y

# Docker group을 새로 만들고 ec2-user 그룹에 편입
sudo usermod -aG docker ec2-user

# Docker 실행
sudo service docker start
docker ps

# ec2-user 권한 추가
sudo gpasswd -a $USER docker
newgrp docker
sudo service docker restart

# Docker Compose Plugin Install : AWS Linux
sudo mkdir -p /usr/local/lib/docker/cli-plugins/
sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version

# Compose 플러그인을 docker-compose 명령어로 사용하기
# sudo ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
alias docker-compose='docker compose --compatibility "$@"'
docker-compose version
