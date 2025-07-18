# IAM 사용자 계정 식별 관리 취약점 테스트 메인 파일

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "IAM-Security-Test"
      ManagedBy   = "Terraform"
    }
  }
}

# 변수 정의
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
  description = "테스트 단계 (vulnerable, check, remediate)"
  type        = string
  default     = "vulnerable"
  
  validation {
    condition     = contains(["vulnerable", "check", "remediate"], var.test_phase)
    error_message = "test_phase must be one of: vulnerable, check, remediate"
  }
}

# 단계별 실행 조건부 리소스 포함

# 1단계: 취약한 IAM 사용자 생성 (iam_test.tf 내용 포함)
module "vulnerable_users" {
  source = "./vulnerable"
  count  = contains(["vulnerable", "check"], var.test_phase) ? 1 : 0
}

# 2단계: 보안 점검 실행 (iam_security_check.tf 내용 포함)
module "security_check" {
  source = "./check"
  count  = contains(["check", "remediate"], var.test_phase) ? 1 : 0
  depends_on = [module.vulnerable_users]
}

# 3단계: 취약점 조치 (iam_remediation.tf 내용 포함)
module "remediation" {
  source = "./remediation"
  count  = var.test_phase == "remediate" ? 1 : 0
  
  enable_remediation = true
  depends_on = [module.security_check]
}

# 테스트 결과 출력
output "test_results" {
  description = "IAM 보안 테스트 결과"
  value = {
    current_phase = var.test_phase
    vulnerable_users = var.test_phase == "vulnerable" ? try(module.vulnerable_users[0].vulnerable_users, {}) : {}
    security_assessment = contains(["check", "remediate"], var.test_phase) ? try(module.security_check[0].security_assessment, {}) : {}
    remediation_results = var.test_phase == "remediate" ? try(module.remediation[0].remediation_results, {}) : {}
  }
}