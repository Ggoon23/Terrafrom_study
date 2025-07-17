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
print_status "Running Terraform plan..."

# 현재 디렉토리 확인
if [ ! -f "main.tf" ]; then
    print_error "main.tf not found. Please run this script from the terraform directory."
    exit 1
fi

# terraform.tfvars 파일 존재 확인
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found."
    if [ -f "terraform.tfvars.example" ]; then
        print_status "Using terraform.tfvars.example as reference..."
        print_warning "Please create terraform.tfvars with your specific values."
    fi
fi

# Terraform 초기화 (필요시)
if [ ! -d ".terraform" ]; then
    print_status "Terraform not initialized. Running terraform init..."
    terraform init
    
    if [ $? -ne 0 ]; then
        print_error "Terraform initialization failed!"
        exit 1
    fi
    print_success "Terraform initialized successfully!"
fi

# Terraform 검증
print_status "Validating Terraform configuration..."
terraform validate

if [ $? -ne 0 ]; then
    print_error "Terraform validation failed!"
    exit 1
fi
print_success "Terraform configuration is valid!"

# Terraform 계획 실행
print_status "Creating Terraform plan..."
terraform plan -detailed-exitcode

case $? in
    0)
        print_success "No changes detected. Infrastructure is up-to-date."
        ;;
    1)
        print_error "Terraform plan failed!"
        exit 1
        ;;
    2)
        print_warning "Changes detected. Review the plan above."
        echo
        print_status "To apply these changes, run: ./scripts/deploy.sh"
        print_status "To destroy resources, run: ./scripts/destroy.sh"
        ;;
esac

print_status "Plan completed successfully!"