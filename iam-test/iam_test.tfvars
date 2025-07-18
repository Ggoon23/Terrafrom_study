# IAM 보안 테스트 설정 파일

# 기본 설정
aws_region  = "ap-northeast-2"
environment = "dev"

# 테스트 단계 설정
# "vulnerable" : 취약한 사용자 생성
# "check"      : 보안 점검 실행
# "remediate"  : 취약점 조치
test_phase = "vulnerable"

# 조치 옵션
enable_remediation        = false
create_compliant_example  = false
enable_tag_policy        = false

# 필수 태그 목록 (ISMS-P 기준)
required_tags = [
  "Name",        # 사용자 이름
  "Email",       # 이메일 주소
  "Department",  # 부서
  "Role",        # 역할
  "Manager"      # 관리자
]

# 테스트 사용자 설정
test_users = [
  {
    name = "testuser1"
    tags = {}  # 태그 없음 (취약)
  },
  {
    name = "testuser2"  
    tags = {}  # 태그 없음 (취약)
  },
  {
    name = "partialuser"
    tags = {
      Name = "이부분"  # 일부 태그만 있음 (부분 취약)
    }
  }
]