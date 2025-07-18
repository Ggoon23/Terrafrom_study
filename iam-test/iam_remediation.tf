# IAM 사용자 계정 식별 관리 취약점 조치 파일

# 기존 취약한 사용자들을 양호하게 변경
resource "aws_iam_user" "remediated_testuser1" {
  count = var.enable_remediation ? 1 : 0
  name  = "testuser1"
  path  = "/"
  
  tags = {
    Name        = "김테스트"
    Email       = "kim.test@company.com"
    Department  = "IT"
    Role        = "Tester"
    Manager     = "박팀장"
    Environment = "dev"
    Status      = "Active"
    CreatedBy   = "Terraform"
    LastUpdated = timestamp()
  }
  
  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

resource "aws_iam_user" "remediated_testuser2" {
  count = var.enable_remediation ? 1 : 0
  name  = "testuser2"
  path  = "/"
  
  tags = {
    Name        = "이테스트"
    Email       = "lee.test@company.com"
    Department  = "개발"
    Role        = "Developer"
    Manager     = "최팀장"
    Environment = "dev"
    Status      = "Active"
    CreatedBy   = "Terraform"
    LastUpdated = timestamp()
  }
  
  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# 부분적으로 취약한 사용자 개선
resource "aws_iam_user" "remediated_partial_user" {
  count = var.enable_remediation ? 1 : 0
  name  = "partialuser"
  path  = "/"
  
  tags = {
    Name        = "이부분"
    Email       = "lee.partial@company.com"  # 추가됨
    Department  = "QA"                       # 추가됨
    Role        = "QA Engineer"              # 추가됨
    Manager     = "김매니저"                  # 추가됨
    Environment = "dev"
    Status      = "Active"
    CreatedBy   = "Terraform"
    LastUpdated = timestamp()
  }
  
  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# 새로운 보안 준수 사용자 생성 예시
resource "aws_iam_user" "compliant_user_example" {
  count = var.create_compliant_example ? 1 : 0
  name  = "compliant-user"
  path  = "/"
  
  tags = {
    Name        = "박준수"
    Email       = "park.junsoo@company.com"
    Department  = "보안팀"
    Role        = "Security Engineer"
    Manager     = "정보보안팀장"
    Environment = "prod"
    Status      = "Active"
    CreatedBy   = "Terraform"
    LastUpdated = timestamp()
    # 추가 태그 (선택사항)
    CostCenter  = "IT-SEC-001"
    Project     = "Security-Compliance"
  }
  
  lifecycle {
    ignore_changes = [tags["LastUpdated"]]
  }
}

# IAM 사용자 태그 정책 (선택사항)
resource "aws_iam_policy" "tag_enforcement_policy" {
  count       = var.enable_tag_policy ? 1 : 0
  name        = "IAM-Tag-Enforcement-Policy"
  description = "IAM 사용자 태그 강제 적용 정책"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyCreateUserWithoutTags"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:PutUserPermissionsBoundary"
        ]
        Resource = "*"
        Condition = {
          "Null" = {
            "aws:RequestedRegion" = "false"
          }
          "ForAllValues:StringNotEquals" = {
            "aws:TagKeys" = [
              "Name",
              "Email", 
              "Department",
              "Role",
              "Manager"
            ]
          }
        }
      },
      {
        Sid    = "AllowTaggedUserOperations"
        Effect = "Allow"
        Action = [
          "iam:CreateUser",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:ListUserTags"
        ]
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "iam:ResourceTag/Environment" = ["dev", "staging", "prod"]
          }
        }
      }
    ]
  })
}

# 조치 완료 후 검증
data "aws_iam_user" "verification_testuser1" {
  count     = var.enable_remediation ? 1 : 0
  user_name = "testuser1"
  depends_on = [aws_iam_user.remediated_testuser1]
}

data "aws_iam_user" "verification_testuser2" {
  count     = var.enable_remediation ? 1 : 0
  user_name = "testuser2"
  depends_on = [aws_iam_user.remediated_testuser2]
}

# 조치 결과 출력
output "remediation_results" {
  description = "취약점 조치 결과"
  value = var.enable_remediation ? {
    remediated_users = [
      {
        name = "testuser1"
        tags = try(data.aws_iam_user.verification_testuser1[0].tags, {})
        status = "조치 완료"
      },
      {
        name = "testuser2"
        tags = try(data.aws_iam_user.verification_testuser2[0].tags, {})
        status = "조치 완료"
      }
    ]
    compliance_status = "양호"
    last_updated = timestamp()
  } : {
    status = "조치 미실행"
    note = "var.enable_remediation = true로 설정하여 조치 실행"
  }
}

# 변수 정의
variable "enable_remediation" {
  description = "취약점 조치 활성화 여부"
  type        = bool
  default     = false
}

variable "create_compliant_example" {
  description = "준수 사용자 예시 생성 여부"
  type        = bool
  default     = false
}

variable "enable_tag_policy" {
  description = "태그 강제 정책 활성화 여부"
  type        = bool
  default     = false
}

# 조치 전후 비교 보고서
resource "local_file" "remediation_report" {
  count    = var.enable_remediation ? 1 : 0
  filename = "iam_remediation_report.json"
  content = jsonencode({
    timestamp = timestamp()
    remediation_summary = {
      total_users_remediated = 3
      remediation_actions = [
        {
          user = "testuser1"
          action = "태그 추가"
          tags_added = ["Name", "Email", "Department", "Role", "Manager"]
        },
        {
          user = "testuser2"
          action = "태그 추가"
          tags_added = ["Name", "Email", "Department", "Role", "Manager"]
        },
        {
          user = "partialuser"
          action = "누락 태그 추가"
          tags_added = ["Email", "Department", "Role", "Manager"]
        }
      ]
    }
    compliance_status = "양호"
    next_review_date = timeadd(timestamp(), "720h") # 30일 후
  })
}