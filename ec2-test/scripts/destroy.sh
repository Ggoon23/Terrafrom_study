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
print_warning "This will destroy all resources created by Terraform!"
print_warning "This action cannot be undone!"
echo

# 현재 디렉토리 확인
if [ ! -f "main.tf" ]; then
    print_error "main.tf not found. Please run this script from the terraform directory."
    exit 1
fi

# 현재 리소스 확인
print_status "Current resources that will be destroyed:"
terraform show

echo
print_error "Are you sure you want to destroy all resources? (yes/no)"
read -r response

if [[ ! "$response" == "yes" ]]; then
    print_status "Destruction cancelled."
    exit 0
fi

# 한 번 더 확인
print_error "This is your final warning. Type 'DESTROY' to proceed:"
read -r confirm

if [[ ! "$confirm" == "DESTROY" ]]; then
    print_status "Destruction cancelled."
    exit 0
fi

# Terraform 파괴
print_status "Destroying Terraform resources..."
terraform destroy -auto-approve

if [ $? -ne 0 ]; then
    print_error "Terraform destroy failed!"
    exit 1
fi

print_success "All resources have been destroyed successfully!"
print_status "Cleaning up local files..."

# 로컬 정리 (선택사항)
if [ -f "terraform.tfstate" ]; then
    print_status "Backing up terraform.tfstate..."
    mv terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
fi

if [ -f "terraform.tfstate.backup" ]; then
    print_status "Backing up terraform.tfstate.backup..."
    mv terraform.tfstate.backup terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
fi

print_success "Cleanup completed!"
print_status "All AWS resources have been destroyed and local state has been cleaned up."