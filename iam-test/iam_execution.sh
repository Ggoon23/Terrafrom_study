#!/bin/bash

# IAM 사용자 계정 식별 관리 취약점 테스트 실행 스크립트

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# 테스트 단계 함수
run_vulnerable_phase() {
    print_header "1단계: 취약한 IAM 사용자 생성"
    
    # terraform.tfvars 설정
    sed -i 's/test_phase = .*/test_phase = "vulnerable"/' iam_test.tfvars
    
    print_status "취약한 IAM 사용자들을 생성합니다..."
    terraform init
    terraform plan -var-file="iam_test.tfvars"
    
    echo
    print_warning "취약한 사용자를 생성하시겠습니까? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        terraform apply -var-file="iam_test.tfvars" -auto-approve
        print_success "취약한 사용자 생성 완료"
    else
        print_status "사용자 생성 취소"
        return 1
    fi
}

run_check_phase() {
    print_header "2단계: 보안 점검 실행"
    
    # terraform.tfvars 설정
    sed -i 's/test_phase = .*/test_phase = "check"/' iam_test.tfvars
    
    print_status "IAM 사용자 보안 점검을 실행합니다..."
    terraform plan -var-file="iam_test.tfvars"
    terraform apply -var-file="iam_test.tfvars" -auto-approve
    
    print_success "보안 점검 완료"
    
    # 점검 결과 출력
    echo
    print_status "점검 결과:"
    terraform output -json | jq '.test_results.value.security_assessment'
    
    # 보안 점검 스크립트 실행
    if [ -f "iam_security_check.sh" ]; then
        echo
        print_status "세부 점검 스크립트 실행 중..."
        chmod +x iam_security_check.sh
        ./iam_security_check.sh
    fi
}

run_remediate_phase() {
    print_header "3단계: 취약점 조치 실행"
    
    # terraform.tfvars 설정
    sed -i 's/test_phase = .*/test_phase = "remediate"/' iam_test.tfvars
    sed -i 's/enable_remediation = .*/enable_remediation = true/' iam_test.tfvars
    
    print_status "취약점 조치를 실행합니다..."
    terraform plan -var-file="iam_test.tfvars"
    
    echo
    print_warning "취약점 조치를 실행하시겠습니까? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        terraform apply -var-file="iam_test.tfvars" -auto-approve
        print_success "취약점 조치 완료"
        
        # 조치 결과 출력
        echo
        print_status "조치 결과:"
        terraform output -json | jq '.test_results.value.remediation_results'
        
        # 재점검 실행
        echo
        print_status "조치 후 재점검 실행 중..."
        if [ -f "iam_security_check.sh" ]; then
            ./iam_security_check.sh
        fi
    else
        print_status "조치 실행 취소"
        return 1
    fi
}

cleanup_resources() {
    print_header "리소스 정리"
    
    print_warning "모든 테스트 리소스를 삭제하시겠습니까? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        terraform destroy -var-file="iam_test.tfvars" -auto-approve
        print_success "리소스 정리 완료"
    else
        print_status "리소스 정리 취소"
    fi
}

# 사용법 출력
show_usage() {
    echo "사용법: $0 [옵션]"
    echo "옵션:"
    echo "  1, vulnerable   : 취약한 IAM 사용자 생성"
    echo "  2, check        : 보안 점검 실행"
    echo "  3, remediate    : 취약점 조치 실행"
    echo "  all             : 전체 단계 순차 실행"
    echo "  cleanup         : 리소스 정리"
    echo "  -h, --help      : 도움말 표시"
}

# 전체 테스트 실행
run_all_phases() {
    print_header "전체 IAM 보안 테스트 실행"
    
    print_status "1단계부터 3단계까지 순차적으로 실행합니다."
    echo
    
    # 1단계: 취약한 사용자 생성
    if run_vulnerable_phase; then
        echo
        print_status "1단계 완료. 5초 후 2단계를 시작합니다..."
        sleep 5
        
        # 2단계: 보안 점검
        if run_check_phase; then
            echo
            print_status "2단계 완료. 5초 후 3단계를 시작합니다..."
            sleep 5
            
            # 3단계: 취약점 조치
            run_remediate_phase
        fi
    fi
}

# 메인 실행 로직
case "$1" in
    1|vulnerable)
        run_vulnerable_phase
        ;;
    2|check)
        run_check_phase
        ;;
    3|remediate)
        run_remediate_phase
        ;;
    all)
        run_all_phases
        ;;
    cleanup)
        cleanup_resources
        ;;
    -h|--help|*)
        show_usage
        ;;
esac

# 실행 완료 메시지
echo
print_success "테스트 실행 완료!"
print_status "생성된 보고서:"
if [ -f "iam_security_report.json" ]; then
    echo "  - iam_security_report.json (보안 점검 보고서)"
fi
if [ -f "iam_remediation_report.json" ]; then
    echo "  - iam_remediation_report.json (조치 보고서)"
fi