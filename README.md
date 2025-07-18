# Terrafrom_study




---
# IAM 사용자 계정 식별 관리 취약점 테스트

AWS IAM 사용자 계정 식별 관리에 대한 취약점 점검 및 조치를 테스트하는 Terraform 프로젝트입니다.

## 📋 클라우드 보안가이드 기준

**항목**: 1.3 IAM 사용자 계정 식별 관리  
**중요도**: 중  
**진단 기준**:
- **양호**: 사용자 정보(이름, 이메일, 부서 등)가 IAM 사용자 태그에 설정되어 있을 경우
- **취약**: 사용자 정보(이름, 이메일, 부서 등)가 IAM 사용자 태그에 설정되어 있지 않을 경우

## 🏗️ 프로젝트 구조

```
iam-security-test/
├── iam_test.tf                    # 취약한 IAM 사용자 생성
├── iam_security_check.tf          # 보안 점검 및 평가
├── iam_remediation.tf             # 취약점 조치
├── iam_test_main.tf               # 메인 실행 파일
├── iam_test_variables.tf          # 변수 정의
├── iam_test.tfvars                # 설정 파일
├── test_execution.sh              # 테스트 실행 스크립트
├── templates/
│   └── iam_check_script.tpl       # 점검 스크립트 템플릿
└── IAM_TEST_README.md             # 이 파일
```

## 🚀 사용법

### 1. 환경 설정

```bash
# 프로젝트 디렉토리 생성
mkdir iam-security-test
cd iam-security-test

# 파일들을 위 구조대로 생성
# AWS CLI 설정 확인
aws configure list

# Terraform 초기화
terraform init
```

### 2. 테스트 실행

#### 방법 1: 스크립트 사용 (권장)

```bash
# 실행 권한 부여
chmod +x test_execution.sh

# 전체 테스트 실행
./test_execution.sh all

# 단계별 실행
./test_execution.sh 1      # 취약한 사용자 생성
./test_execution.sh 2      # 보안 점검
./test_execution.sh 3      # 취약점 조치

# 리소스 정리
./test_execution.sh cleanup
```

#### 방법 2: Terraform 직접 사용

```bash
# 1단계: 취약한 사용자 생성
terraform apply -var="test_phase=vulnerable" -var-file="iam_test.tfvars"

# 2단계: 보안 점검
terraform apply -var="test_phase=check" -var-file="iam_test.tfvars"

# 3단계: 취약점 조치
terraform apply -var="test_phase=remediate" -var="enable_remediation=true" -var-file="iam_test.tfvars"
```

## 🔍 테스트 시나리오

### 1단계: 취약한 환경 생성

생성되는 IAM 사용자들:
- **testuser1**: 태그 없음 (취약)
- **testuser2**: 태그 없음 (취약)
- **partialuser**: 일부 태그만 있음 (부분 취약)
- **gooduser**: 모든 필수 태그 있음 (양호)

### 2단계: 보안 점검

점검 항목:
- 전체 IAM 사용자 수 확인
- 필수 태그 보유 여부 확인
- 취약/부분취약/양호 사용자 분류
- 컴플라이언스 비율 계산

필수 태그 목록:
- `Name`: 사용자 이름
- `Email`: 이메일 주소
- `Department`: 부서
- `Role`: 역할
- `Manager`: 관리자

### 3단계: 취약점 조치

조치 내용:
- 태그 없는 사용자에게 필수 태그 추가
- 부분 태그 사용자에게 누락 태그 추가
- 조치 전후 비교 보고서 생성

## 📊 결과 확인

### 콘솔 출력

```bash
# 테스트 결과 확인
terraform output test_results

# 보안 점검 결과만 확인
terraform output -json | jq '.test_results.value.security_assessment'

# 조치 결과만 확인
terraform output -json | jq '.test_results.value.remediation_results'
```

### 생성되는 보고서

1. **iam_security_report.json**: 보안 점검 결과
2. **iam_remediation_report.json**: 조치 결과
3. **iam_security_check.sh**: 세부 점검 스크립트

## 🛡️ 보안 권고사항

### 즉시 조치 필요
- 태그 없는 사용자 식별 및 필수 태그 추가
- 사용자 생성 시 태그 입력 프로세스 수립

### 지속적 관리
- 월 1회 이상 IAM 사용자 태그 점검
- 신규 사용자 생성 시 태그 검증
- CloudWatch 알람을 통한 모니터링

### 자동화 구현
- IAM 사용자 생성 시 태그 강제 적용
- 태그 부족 사용자 자동 탐지
- 정기적인 컴플라이언스 보고서 생성

## 🔧 고급 설정

### 태그 강제 정책 적용

```hcl
# iam_test.tfvars에서 설정
enable_tag_policy = true
```

### 커스텀 필수 태그 설정

```hcl
# iam_test.tfvars에서 설정
required_tags = [
  "Name",
  "Email", 
  "Department",
  "Role",
  "Manager",
  "CostCenter",    # 추가 태그
  "Project"        # 추가 태그
]
```

## 🧹 정리

```bash
# 테스트 리소스 정리
terraform destroy -var-file="iam_test.tfvars" -auto-approve

# 생성된 파일 정리
rm -f iam_security_report.json iam_remediation_report.json iam_security_check.sh
```

## ⚠️ 주의사항

1. **테스트 환경에서만 사용**: 운영 환경에서는 신중히 사용하세요.
2. **권한 확인**: IAM 사용자 생성/수정 권한이 필요합니다.
3. **비용 발생**: IAM 사용자 생성 자체는 무료이지만, 연결된 리소스에 따라 비용이 발생할 수 있습니다.
4. **보안 정책**: 회사 보안 정책에 따라 태그 요구사항이 다를 수 있습니다.

## 🤝 기여

이 프로젝트는 ISMS-P 인증 및 클라우드 보안 강화를 위한 교육 목적으로 제작되었습니다. 개선사항이나 문제점이 있다면 이슈를 등록해 주세요.