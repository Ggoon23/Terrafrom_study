# IAM 사용자 계정 식별 관리 보안 점검 및 조치 파일

# 기존 IAM 사용자 데이터 소스
data "aws_iam_users" "all_users" {}

# 개별 사용자 정보 조회 (태그 확인용)
data "aws_iam_user" "user_details" {
  for_each  = toset(data.aws_iam_users.all_users.names)
  user_name = each.value
}

# 로컬 변수 - 보안 점검 로직
locals {
  # 필수 태그 목록 (ISMS-P 기준)
  required_tags = [
    "Name",        # 사용자 이름
    "Email",       # 이메일
    "Department",  # 부서
    "Role",        # 역할
    "Manager"      # 관리자
  ]
  
  # 태그가 없는 취약한 사용자들
  vulnerable_users = {
    for user_name, user_data in data.aws_iam_user.user_details :
    user_name => user_data
    if length(user_data.tags) == 0
  }
  
  # 필수 태그가 부족한 사용자들
  incomplete_users = {
    for user_name, user_data in data.aws_iam_user.user_details :
    user_name => {
      user_data = user_data
      missing_tags = [
        for tag in local.required_tags :
        tag if !contains(keys(user_data.tags), tag)
      ]
    }
    if length(user_data.tags) > 0 && length([
      for tag in local.required_tags :
      tag if !contains(keys(user_data.tags), tag)
    ]) > 0
  }
  
  # 양호한 사용자들 (모든 필수 태그 보유)
  compliant_users = {
    for user_name, user_data in data.aws_iam_user.user_details :
    user_name => user_data
    if length([
      for tag in local.required_tags :
      tag if !contains(keys(user_data.tags), tag)
    ]) == 0
  }
}

# 보안 점검 결과 출력
output "security_assessment" {
  description = "IAM 사용자 계정 식별 관리 보안 점검 결과"
  value = {
    total_users = length(data.aws_iam_users.all_users.names)
    
    # 취약점 현황
    vulnerability_summary = {
      vulnerable_users_count   = length(local.vulnerable_users)
      incomplete_users_count   = length(local.incomplete_users)
      compliant_users_count    = length(local.compliant_users)
    }
    
    # 세부 취약점 정보
    vulnerable_users_detail = {
      for user_name, user_data in local.vulnerable_users :
      user_name => {
        arn    = user_data.arn
        status = "취약 - 태그 없음"
        tags   = user_data.tags
      }
    }
    
    incomplete_users_detail = {
      for user_name, user_info in local.incomplete_users :
      user_name => {
        arn          = user_info.user_data.arn
        status       = "부분 취약 - 필수 태그 누락"
        current_tags = user_info.user_data.tags
        missing_tags = user_info.missing_tags
      }
    }
    
    compliant_users_detail = {
      for user_name, user_data in local.compliant_users :
      user_name => {
        arn    = user_data.arn
        status = "양호 - 모든 필수 태그 보유"
        tags   = user_data.tags
      }
    }
  }
}

# 보안 개선 권고사항
output "security_recommendations" {
  description = "보안 개선 권고사항"
  value = {
    action_required = length(local.vulnerable_users) > 0 || length(local.incomplete_users) > 0
    
    immediate_actions = [
      for user_name in keys(local.vulnerable_users) :
      "사용자 '${user_name}'에게 필수 태그 추가 필요: ${join(", ", local.required_tags)}"
    ]
    
    partial_actions = [
      for user_name, user_info in local.incomplete_users :
      "사용자 '${user_name}'에게 누락된 태그 추가 필요: ${join(", ", user_info.missing_tags)}"
    ]
    
    compliance_status = length(local.vulnerable_users) == 0 && length(local.incomplete_users) == 0 ? "양호" : "취약"
  }
}

# 자동 조치 리소스 (선택사항 - 주석 해제하여 사용)
# 주의: 실제 환경에서는 신중히 사용하세요

/*
# 취약한 사용자들에게 기본 태그 추가
resource "aws_iam_user" "remediate_vulnerable_users" {
  for_each = local.vulnerable_users
  
  name = each.key
  
  tags = {
    Name        = "미지정-${each.key}"
    Email       = "unknown@company.com"
    Department  = "미지정"
    Role        = "미지정"
    Manager     = "미지정"
    Environment = "unknown"
    Status      = "요확인"
    CreatedBy   = "Terraform-Auto-Remediation"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}
*/

# 컴플라이언스 메트릭 (CloudWatch 메트릭 생성용)
resource "aws_cloudwatch_metric_alarm" "iam_compliance_alarm" {
  alarm_name          = "IAM-User-Tag-Compliance"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAM_Users_Without_Required_Tags"
  namespace           = "Custom/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors IAM users without required tags"
  alarm_actions       = []

  # 임시 메트릭 (실제로는 Lambda 함수 등으로 메트릭 전송)
  treat_missing_data = "notBreaching"
}

# 보안 점검 스크립트 생성
resource "local_file" "security_check_script" {
  filename = "iam_security_check.sh"
  content = templatefile("${path.module}/templates/iam_check_script.tpl", {
    required_tags = local.required_tags
  })
}

# 보안 점검 결과 JSON 파일 생성
resource "local_file" "security_report" {
  filename = "iam_security_report.json"
  content = jsonencode({
    timestamp = timestamp()
    assessment = {
      total_users = length(data.aws_iam_users.all_users.names)
      vulnerable_users_count = length(local.vulnerable_users)
      incomplete_users_count = length(local.incomplete_users)
      compliant_users_count = length(local.compliant_users)
      compliance_rate = "${round((length(local.compliant_users) / length(data.aws_iam_users.all_users.names)) * 100)}%"
    }
    vulnerable_users = keys(local.vulnerable_users)
    incomplete_users = {
      for user_name, user_info in local.incomplete_users :
      user_name => user_info.missing_tags
    }
    compliant_users = keys(local.compliant_users)
  })
}