#!/bin/bash

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 스크립트 시작
print_status "Starting Terraform deployment..."

# 현재 디렉토리 확인
if [ ! -f "main.tf" ]; then
    print_error "main.tf not found. Please run this script from the terraform directory."
    exit 1
fi

# terraform.tfvars 파일 존재 확인
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found. Creating from example..."
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your specific values before proceeding."
        echo "Do you want to continue? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Deployment cancelled."
            exit 0
        fi
    else
        print_error "terraform.tfvars.example not found. Cannot proceed."
        exit 1
    fi
fi

# SSH 키 확인
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    print_error "SSH public key not found at ~/.ssh/id_rsa.pub"
    print_status "Please generate SSH keys using: ssh-keygen -t rsa -b 4096"
    exit 1
fi

# Terraform 초기화
print_status "Initializing Terraform..."
terraform init

if [ $? -ne 0 ]; then
    print_error "Terraform initialization failed!"
    exit 1
fi
print_success "Terraform initialized successfully!"

# Terraform 검증
print_status "Validating Terraform configuration..."
terraform validate

if [ $? -ne 0 ]; then
    print_error "Terraform validation failed!"
    exit 1
fi
print_success "Terraform configuration is valid!"

# Terraform 계획
print_status "Creating Terraform plan..."
terraform plan -out=tfplan

if [ $? -ne 0 ]; then
    print_error "Terraform plan failed!"
    exit 1
fi
print_success "Terraform plan created successfully!"

# 배포 확인
echo
print_warning "Review the plan above. Do you want to proceed with deployment? (y/n)"
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Terraform 적용
print_status "Applying Terraform configuration..."
terraform apply tfplan

if [ $? -ne 0 ]; then
    print_error "Terraform apply failed!"
    rm -f tfplan
    exit 1
fi

# 계획 파일 정리
rm -f tfplan

print_success "Deployment completed successfully!"
echo
print_status "Getting instance information..."
terraform output

echo
print_status "You can SSH to your instance using the command shown in the 'ssh_command' output above."
print_status "Web server is available at: http://\$(terraform output -raw elastic_ip)"