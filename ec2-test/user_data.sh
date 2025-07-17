#!/bin/bash

# 로그 파일 설정
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script execution at $(date)"

# 시스템 업데이트
yum update -y

# 기본 패키지 설치
yum install -y \
    htop \
    git \
    curl \
    wget \
    vim \
    unzip \
    tree

# Docker 설치
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Node.js 설치 (선택사항)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Python3 및 pip 설치
yum install -y python3 python3-pip

# AWS CLI v2 설치
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# 간단한 웹 서버 설치 (nginx)
yum install -y nginx
systemctl start nginx
systemctl enable nginx

# 간단한 HTML 페이지 생성
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Terraform EC2 Instance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🚀 Terraform EC2 Instance Successfully Deployed!</h1>
    <div class="info">
        <h2>Instance Information</h2>
        <p><strong>Date:</strong> $(date)</p>
        <p><strong>Hostname:</strong> $(hostname)</p>
        <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
        <p><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
        <p><strong>Public IP:</strong> $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
        <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
    </div>
    <h2>Services Installed</h2>
    <ul>
        <li>Docker</li>
        <li>Node.js</li>
        <li>Python3</li>
        <li>AWS CLI v2</li>
        <li>Nginx</li>
    </ul>
</body>
</html>
EOF

# 방화벽 설정 (Amazon Linux 2023는 기본적으로 방화벽이 비활성화되어 있음)
# firewall-cmd --permanent --add-service=http
# firewall-cmd --permanent --add-service=https
# firewall-cmd --reload

# 로그 완료 메시지
echo "User data script completed at $(date)"

# 시스템 정보 로그
echo "=== System Information ===" >> /var/log/user-data.log
echo "Hostname: $(hostname)" >> /var/log/user-data.log
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> /var/log/user-data.log
echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)" >> /var/log/user-data.log
echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" >> /var/log/user-data.log
echo "=========================" >> /var/log/user-data.log