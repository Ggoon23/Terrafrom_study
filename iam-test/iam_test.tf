# IAM 사용자 계정 식별 관리 취약점 테스트용 파일

# 1. 취약한 사용자 - 태그 없음 (testuser1)
resource "aws_iam_user" "vulnerable_user1" {
  name = "testuser1"
  path = "/"
}

# 2. 취약한 사용자 - 태그 없음 (testuser2)  
resource "aws_iam_user" "vulnerable_user2" {
  name = "testuser2"
  path = "/"
}

# 3. 양호한 사용자 - 태그 있음 (gooduser)
resource "aws_iam_user" "good_user" {
  name = "gooduser"
  path = "/"
  
  tags = {
    Name        = "홍길동"
    Email       = "hong@company.com"
    Department  = "IT"
    Role        = "Developer"
    Manager     = "김팀장"
    Environment = "dev"
  }
}

# 4. 부분적으로 취약한 사용자 - 일부 태그만 있음
resource "aws_iam_user" "partial_user" {
  name = "partialuser"
  path = "/"
  
  tags = {
    Name = "이부분"
    # Email, Department 등 필수 태그 누락
  }
}

# 테스트용 IAM 정책 (읽기 전용)
resource "aws_iam_policy" "test_policy" {
  name        = "TestReadOnlyPolicy"
  description = "Test policy for IAM users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

# 정책 연결 (테스트용)
resource "aws_iam_user_policy_attachment" "test_attachment1" {
  user       = aws_iam_user.vulnerable_user1.name
  policy_arn = aws_iam_policy.test_policy.arn
}

resource "aws_iam_user_policy_attachment" "test_attachment2" {
  user       = aws_iam_user.vulnerable_user2.name
  policy_arn = aws_iam_policy.test_policy.arn
}

resource "aws_iam_user_policy_attachment" "good_attachment" {
  user       = aws_iam_user.good_user.name
  policy_arn = aws_iam_policy.test_policy.arn
}

# 출력 - 테스트 결과 확인용
output "vulnerable_users" {
  description = "취약한 사용자 목록 (태그 없음)"
  value = {
    user1 = {
      name = aws_iam_user.vulnerable_user1.name
      arn  = aws_iam_user.vulnerable_user1.arn
      tags = aws_iam_user.vulnerable_user1.tags
    }
    user2 = {
      name = aws_iam_user.vulnerable_user2.name
      arn  = aws_iam_user.vulnerable_user2.arn
      tags = aws_iam_user.vulnerable_user2.tags
    }
  }
}

output "good_user" {
  description = "양호한 사용자 (태그 있음)"
  value = {
    name = aws_iam_user.good_user.name
    arn  = aws_iam_user.good_user.arn
    tags = aws_iam_user.good_user.tags
  }
}

output "partial_user" {
  description = "부분적으로 취약한 사용자 (일부 태그만 있음)"
  value = {
    name = aws_iam_user.partial_user.name
    arn  = aws_iam_user.partial_user.arn
    tags = aws_iam_user.partial_user.tags
  }
}