# IAM 보안 테스트 변수 정의

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "test_phase" {
  description = "테스트 단계 선택"
  type        = string
  default     = "vulnerable"
  
  validation {
    condition     = contains(["vulnerable", "check", "remediate"], var.test_phase)
    error_message = "test_phase must be one of: vulnerable, check, remediate"
  }
}

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

variable "required_tags" {
  description = "필수 태그 목록"
  type        = list(string)
  default     = ["Name", "Email", "Department", "Role", "Manager"]
}

variable "test_users" {
  description = "테스트용 사용자 목록"
  type = list(object({
    name = string
    tags = map(string)
  }))
  default = [
    {
      name = "testuser1"
      tags = {}
    },
    {
      name = "testuser2"
      tags = {}
    },
    {
      name = "partialuser"
      tags = {
        Name = "이부분"
      }
    }
  ]
}