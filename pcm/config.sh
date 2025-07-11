#!/bin/bash

# 로그 함수
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "=== AutoA PCManager 설정 시작 ==="


# 1. macOS 확인
if [[ "$OSTYPE" != "darwin"* ]]; then
  log "오류: 이 스크립트는 macOS에서만 동작합니다."
  exit 1
fi

log "macOS 환경 확인 완료"

# 2. Homebrew 설치
if ! command -v brew &>/dev/null; then
  log "Homebrew가 설치되어 있지 않습니다. 설치를 시작합니다."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  log "Homebrew 설치 완료"
else
  log "Homebrew가 이미 설치되어 있습니다."
fi

# 3. 환경 변수 확인 및 입력
# .env 파일 경로 설정
ENV_FILE="$HOME/.autoA_env"
log "환경 설정 파일 경로: $ENV_FILE"

# # (선택) 기존 파일 마이그레이션
# if [ -f "/usr/local/bin/.env" ] && [ ! -f "$ENV_FILE" ]; then
#   cp "/usr/local/bin/.env" "$ENV_FILE"
#   log "기존 .env 파일을 홈디렉토리로 복사했습니다: $ENV_FILE"
# fi

# .env 파일이 없으면 생성 및 환경변수 값이 있으면 우선 저장
if [ ! -f "$ENV_FILE" ]; then
  touch "$ENV_FILE"
  log ".autoA_env 파일을 생성했습니다: $ENV_FILE"
  [ -n "$EDGE_NODE_NAME" ] && echo "EDGE_NODE_NAME=$EDGE_NODE_NAME" >> "$ENV_FILE"
  [ -n "$EDGE_NODE_PW" ] && echo "EDGE_NODE_PW=$EDGE_NODE_PW" >> "$ENV_FILE"
  [ -n "$PRIBIT_CONNECT_ID" ] && echo "PRIBIT_CONNECT_ID=$PRIBIT_CONNECT_ID" >> "$ENV_FILE"
  [ -n "$PRIBIT_CONNECT_PASSWORD" ] && echo "PRIBIT_CONNECT_PASSWORD=$PRIBIT_CONNECT_PASSWORD" >> "$ENV_FILE"
  [ -n "$HR_ID" ] && echo "HR_ID=$HR_ID" >> "$ENV_FILE"
  [ -n "$HR_PW" ] && echo "HR_PW=$HR_PW" >> "$ENV_FILE"
fi

# .env 파일에서 기존 값 읽기 함수
get_env_value() {
  local key="$1"
  local value
  value=$(grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2-)
  echo "$value"
}

# .env 파일에 값 쓰기 함수
set_env_value() {
  local key="$1"
  local value="$2"
  # sed 특수문자 이스케이프
  local safe_value
  safe_value=$(printf '%s\n' "$value" | sed 's/[&/]/\\&/g')
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i '' "s/^${key}=.*/${key}=${safe_value}/" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

log "환경 변수 설정 시작..."

# EDGE_NODE_NAME 처리
if [ -z "$EDGE_NODE_NAME" ]; then
  existing_edge_node_name=$(get_env_value "EDGE_NODE_NAME")
  if [ -n "$existing_edge_node_name" ]; then
    EDGE_NODE_NAME="$existing_edge_node_name"
    log "기존 EDGE_NODE_NAME를 사용합니다: $EDGE_NODE_NAME"
  else
    echo "EDGE_NODE_NAME를 입력하세요:"
    read -p "> " EDGE_NODE_NAME
    set_env_value "EDGE_NODE_NAME" "$EDGE_NODE_NAME"
    log "EDGE_NODE_NAME를 .autoA_env 파일에 저장했습니다."
  fi
  export EDGE_NODE_NAME="$EDGE_NODE_NAME"
  log "EDGE_NODE_NAME=$EDGE_NODE_NAME"
fi

# EDGE_NODE_PW 처리
if [ -z "$EDGE_NODE_PW" ]; then
  existing_edge_node_pw=$(get_env_value "EDGE_NODE_PW")
  if [ -n "$existing_edge_node_pw" ]; then
    EDGE_NODE_PW="$existing_edge_node_pw"
    log "기존 EDGE_NODE_PW를 사용합니다."
  else
    echo "EDGE_NODE_PW를 입력하세요:"
    read -s -p "> " EDGE_NODE_PW
    echo
    set_env_value "EDGE_NODE_PW" "$EDGE_NODE_PW"
    log "EDGE_NODE_PW를 .autoA_env 파일에 저장했습니다."
  fi
  export EDGE_NODE_PW="$EDGE_NODE_PW"
  log "EDGE_NODE_PW 설정 완료"
fi

# PRIBIT_CONNECT_ID 처리
if [ -z "$PRIBIT_CONNECT_ID" ]; then
  existing_pribit_connect_id=$(get_env_value "PRIBIT_CONNECT_ID")
  if [ -n "$existing_pribit_connect_id" ]; then
    PRIBIT_CONNECT_ID="$existing_pribit_connect_id"
    log "기존 PRIBIT_CONNECT_ID를 사용합니다: $PRIBIT_CONNECT_ID"
  else
    echo "PRIBIT_CONNECT_ID를 입력하세요:"
    read -p "> " PRIBIT_CONNECT_ID
    set_env_value "PRIBIT_CONNECT_ID" "$PRIBIT_CONNECT_ID"
    log "PRIBIT_CONNECT_ID를 .autoA_env 파일에 저장했습니다."
  fi
  export PRIBIT_CONNECT_ID="$PRIBIT_CONNECT_ID"
  log "PRIBIT_CONNECT_ID=$PRIBIT_CONNECT_ID"
fi

# PRIBIT_CONNECT_PASSWORD 처리
if [ -z "$PRIBIT_CONNECT_PASSWORD" ]; then
  existing_pribit_connect_password=$(get_env_value "PRIBIT_CONNECT_PASSWORD")
  if [ -n "$existing_pribit_connect_password" ]; then
    PRIBIT_CONNECT_PASSWORD="$existing_pribit_connect_password"
    log "기존 PRIBIT_CONNECT_PASSWORD를 사용합니다."
  else
    echo "PRIBIT_CONNECT_PASSWORD를 입력하세요:"
    read -s -p "> " PRIBIT_CONNECT_PASSWORD
    echo
    set_env_value "PRIBIT_CONNECT_PASSWORD" "$PRIBIT_CONNECT_PASSWORD"
    log "PRIBIT_CONNECT_PASSWORD를 .autoA_env 파일에 저장했습니다."
  fi
  export PRIBIT_CONNECT_PASSWORD="$PRIBIT_CONNECT_PASSWORD"
  log "PRIBIT_CONNECT_PASSWORD 설정 완료"
fi

# HR_ID 처리
if [ -z "$HR_ID" ]; then
  existing_hr_id=$(get_env_value "HR_ID")
  if [ -n "$existing_hr_id" ]; then
    HR_ID="$existing_hr_id"
    log "기존 HR_ID를 사용합니다: $HR_ID"
  else
    echo "HR_ID(사번)를 입력하세요:"
    read -p "> " HR_ID
    set_env_value "HR_ID" "$HR_ID"
    log "HR_ID를 .autoA_env 파일에 저장했습니다."
  fi
  export HR_ID="$HR_ID"
  log "HR_ID=$HR_ID"
fi

# HR_PW 처리
if [ -z "$HR_PW" ]; then
  existing_hr_pw=$(get_env_value "HR_PW")
  if [ -n "$existing_hr_pw" ]; then
    HR_PW="$existing_hr_pw"
    log "기존 HR_PW를 사용합니다."
  else
    echo "HR_PW(비밀번호)를 입력하세요:"
    read -s -p "> " HR_PW
    echo
    set_env_value "HR_PW" "$HR_PW"
    log "HR_PW를 .autoA_env 파일에 저장했습니다."
  fi
  export HR_PW="$HR_PW"
  log "HR_PW 설정 완료"
fi

log "모든 환경변수가 설정되었습니다."
log ".autoA_env 파일 위치: $ENV_FILE"

echo ""
echo "=== AutoA PCManager 환경 설정 완료 ==="
echo "모든 설정이 완료되었습니다."
# echo "설정 파일 위치: $ENV_FILE"
cat $ENV_FILE
# echo ""