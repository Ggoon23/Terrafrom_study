#!/bin/bash

# IAM 사용자 계정 식별 관리 보안 점검 스크립트
# 생성일: $(date)

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 필수 태그 목록
REQUIRED_TAGS=(${join(" ", [for tag in required_tags : "\"${tag}\""])})

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}IAM 사용자 계정 식별 관리 점검${NC}"
echo -e "${BLUE}================================${NC}"
echo

# 모든 IAM 사용자 목록 조회
echo -e "${YELLOW}[1] IAM 사용자 목록 조회 중...${NC}"
USERS=$(aws iam list-users --query 'Users[].UserName' --output text)

if [ -z "$USERS" ]; then
    echo -e "${RED}IAM 사용자를 찾을 수 없습니다.${NC}"
    exit 1
fi

USER_COUNT=$(echo $USERS | wc -w)
echo -e "${GREEN}총 $USER_COUNT 명의 사용자 발견${NC}"
echo

# 각 사용자별 태그 점검
echo -e "${YELLOW}[2] 사용자별 태그 점검 시작...${NC}"
echo

VULNERABLE_COUNT=0
INCOMPLETE_COUNT=0
COMPLIANT_COUNT=0

for USER in $USERS; do
    echo -e "${BLUE}사용자: $USER${NC}"
    
    # 사용자 태그 조회
    TAGS=$(aws iam get-user --user-name $USER --query 'User.Tags' --output json 2>/dev/null)
    
    if [ "$TAGS" == "[]" ] || [ "$TAGS" == "null" ]; then
        echo -e "${RED}  ❌ 취약: 태그 없음${NC}"
        echo -e "${RED}  → 필요한 태그: ${REQUIRED_TAGS[@]}${NC}"
        ((VULNERABLE_COUNT++))
    else
        # 필수 태그 확인
        MISSING_TAGS=()
        for REQUIRED_TAG in "$${REQUIRED_TAGS[@]}"; do
            if ! echo "$TAGS" | jq -r '.[].Key' | grep -q "^$REQUIRED_TAG$"; then
                MISSING_TAGS+=("$REQUIRED_TAG")
            fi
        done
        
        if [ $${#MISSING_TAGS[@]} -eq 0 ]; then
            echo -e "${GREEN}  ✅ 양호: 모든 필수 태그 보유${NC}"
            echo "$TAGS" | jq -r '.[] | "    - \(.Key): \(.Value)"'
            ((COMPLIANT_COUNT++))
        else
            echo -e "${YELLOW}  ⚠️  부분 취약: 필수 태그 누락${NC}"
            echo -e "${YELLOW}  → 누락된 태그: $${MISSING_TAGS[*]}${NC}"
            echo "$TAGS" | jq -r '.[] | "    - \(.Key): \(.Value)"'
            ((INCOMPLETE_COUNT++))
        fi
    fi
    echo
done

# 점검 결과 요약
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}점검 결과 요약${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "총 사용자 수: $USER_COUNT"
echo -e "${RED}취약 사용자 (태그 없음): $VULNERABLE_COUNT${NC}"
echo -e "${YELLOW}부분 취약 사용자 (태그 부족): $INCOMPLETE_COUNT${NC}"
echo -e "${GREEN}양호 사용자 (완전): $COMPLIANT_COUNT${NC}"
echo

# 컴플라이언스 비율 계산
if [ $USER_COUNT -gt 0 ]; then
    COMPLIANCE_RATE=$(( (COMPLIANT_COUNT * 100) / USER_COUNT ))
    echo -e "컴플라이언스 비율: $COMPLIANCE_RATE%"
else
    COMPLIANCE_RATE=0
fi

echo

# 권고사항
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}권고사항${NC}"
echo -e "${BLUE}================================${NC}"

if [ $VULNERABLE_COUNT -gt 0 ] || [ $INCOMPLETE_COUNT -gt 0 ]; then
    echo -e "${RED}⚠️  조치 필요!${NC}"
    echo
    echo "1. 즉시 조치 필요 (태그 없는 사용자):"
    echo "   - 사용자 정보 확인 후 필수 태그 추가"
    echo "   - 필수 태그: ${REQUIRED_TAGS[*]}"
    echo
    echo "2. 부분 조치 필요 (태그 부족 사용자):"
    echo "   - 누락된 태그 추가"
    echo
    echo "3. 정기적인 점검 수행:"
    echo "   - 월 1회 이상 IAM 사용자 태그 점검"
    echo "   - 신규 사용자 생성 시 태그 필수 적용"
    echo
    echo "4. 자동화 고려사항:"
    echo "   - IAM 사용자 생성 시 태그 강제 적용"
    echo "   - CloudWatch 알람을 통한 모니터링"
    
    # 종료 코드 설정 (취약점 발견 시 1)
    exit 1
else
    echo -e "${GREEN}✅ 모든 사용자가 필수 태그를 보유하고 있습니다.${NC}"
    echo -e "${GREEN}현재 상태: 양호${NC}"
    
    # 종료 코드 설정 (양호 시 0)
    exit 0
fi