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

# 3. Node.js v20.x.x 설치 확인 및 설치
log "Node.js v20.x.x 설치 확인 중..."

# nvm 확인 함수
check_nvm() {
  if command -v nvm >/dev/null 2>&1; then
    log "nvm이 설치되어 있습니다."
    return 0
  elif [ -s "$HOME/.nvm/nvm.sh" ]; then
    log "nvm이 설치되어 있지만 PATH에 없습니다. nvm을 로드합니다."
    source "$HOME/.nvm/nvm.sh"
    if command -v nvm >/dev/null 2>&1; then
      log "nvm 로드 완료"
      return 0
    else
      log "nvm 로드 실패"
      return 1
    fi
  else
    log "nvm이 설치되어 있지 않습니다."
    return 1
  fi
}

# Node.js 버전 확인 함수
check_node_version() {
  if command -v node &>/dev/null; then
    local node_version=$(node --version 2>/dev/null)
    if [[ "$node_version" =~ ^v20\. ]]; then
      log "Node.js v20.x.x가 이미 설치되어 있습니다: $node_version"
      return 0
    else
      log "Node.js가 설치되어 있지만 v20.x.x가 아닙니다: $node_version"
      return 1
    fi
  else
    log "Node.js가 설치되어 있지 않습니다."
    return 1
  fi
}

# nvm을 통한 Node.js v20.x.x 설치
install_node_v20_with_nvm() {
  log "nvm을 통해 Node.js v20.x.x 설치를 시작합니다..."
  
  # nvm 최신 버전 확인
  nvm list-remote --lts | grep "v20" | tail -1
  
  # Node.js v20 최신 LTS 버전 설치
  log "Node.js v20 LTS 버전 설치 중..."
  nvm install 20
  
  # Node.js v20을 기본 버전으로 설정
  nvm use 20
  nvm alias default 20
  
  # 설치 확인
  if check_node_version; then
    log "nvm을 통한 Node.js v20.x.x 설치가 완료되었습니다."
    node --version
    npm --version
    
    # yarn 전역 설치
    log "yarn 전역 설치 중..."
    npm install -g yarn
    
    # yarn 설치 확인
    if command -v yarn >/dev/null 2>&1; then
      log "yarn 설치 완료: $(yarn --version)"
    else
      log "경고: yarn 설치에 실패했습니다."
    fi
  else
    log "오류: nvm을 통한 Node.js v20.x.x 설치에 실패했습니다."
    return 1
  fi
}

# Homebrew를 통한 Node.js v20.x.x 설치
install_node_v20_with_homebrew() {
  log "Homebrew를 통해 Node.js v20.x.x 설치를 시작합니다..."
  
  # Homebrew 업데이트
  log "Homebrew 업데이트 중..."
  brew update
  
  # Node.js v20 설치
  log "Node.js v20.x.x 설치 중..."
  brew install node@20
  
  # PATH에 Node.js v20 추가
  local node_path=$(brew --prefix node@20)
  if [[ ":$PATH:" != *":$node_path/bin:"* ]]; then
    echo 'export PATH="'$node_path'/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="'$node_path'/bin:$PATH"' >> ~/.bash_profile
    export PATH="$node_path/bin:$PATH"
    log "Node.js v20 PATH가 설정되었습니다."
  fi
  
  # 설치 확인
  if check_node_version; then
    log "Homebrew를 통한 Node.js v20.x.x 설치가 완료되었습니다."
    node --version
    npm --version
    
    # yarn 전역 설치
    log "yarn 전역 설치 중..."
    npm install -g yarn
    
    # yarn 설치 확인
    if command -v yarn >/dev/null 2>&1; then
      log "yarn 설치 완료: $(yarn --version)"
    else
      log "경고: yarn 설치에 실패했습니다."
    fi
  else
    log "오류: Homebrew를 통한 Node.js v20.x.x 설치에 실패했습니다."
    exit 1
  fi
}

# Node.js v20.x.x 설치 확인 및 설치
if ! check_node_version; then
  # nvm이 설치되어 있으면 nvm을 통해 설치
  if check_nvm; then
    log "nvm을 사용하여 Node.js v20.x.x를 설치합니다."
    if install_node_v20_with_nvm; then
      log "nvm을 통한 Node.js 설치가 완료되었습니다."
    else
      log "nvm을 통한 설치에 실패했습니다. Homebrew를 통해 설치를 시도합니다."
      install_node_v20_with_homebrew
    fi
  else
    log "nvm이 설치되어 있지 않습니다. Homebrew를 통해 Node.js v20.x.x를 설치합니다."
    install_node_v20_with_homebrew
  fi
else
  log "Node.js v20.x.x가 이미 설치되어 있습니다."
  
  # yarn 설치 확인 및 설치
  if ! command -v yarn >/dev/null 2>&1; then
    log "yarn이 설치되어 있지 않습니다. 전역 설치를 시작합니다..."
    npm install -g yarn
    
    if command -v yarn >/dev/null 2>&1; then
      log "yarn 설치 완료: $(yarn --version)"
    else
      log "경고: yarn 설치에 실패했습니다."
    fi
  else
    log "yarn이 이미 설치되어 있습니다: $(yarn --version)"
  fi
fi

# 4. 암호화 키 생성 및 저장
# .autoA_key 파일 경로 설정
KEY_FILE="$HOME/.autoA_key"
log "암호화 키 파일 경로: $KEY_FILE"

# 암호화 키가 없으면 생성
if [ ! -f "$KEY_FILE" ]; then
  log "암호화 키 파일이 없습니다. 새로운 키를 생성합니다."
  
  # 256비트(32바이트) 키 생성 (16진수 64자리)
  KEY_HEX=$(openssl rand -hex 32)
  
  # 128비트(16바이트) IV 생성 (16진수 32자리)
  IV_HEX=$(openssl rand -hex 16)
  
  # .autoA_key 파일에 저장
  cat <<EOF > "$KEY_FILE"
SECRET_KEY_HEX=$KEY_HEX
SECRET_IV_HEX=$IV_HEX
EOF
  
  log ".autoA_key 파일이 생성되었습니다:"
  cat "$KEY_FILE"
else
  log "기존 암호화 키 파일이 존재합니다: $KEY_FILE"
fi

# 5. 암호화/복호화 함수 정의
# AES-256-CBC 암호화 함수
encrypt_aes256cbc() {
  local key_hex="$1"   # 64 hex chars (256bit)
  local iv_hex="$2"    # 32 hex chars (128bit)
  local plaintext="$3"
  printf '%s' "$plaintext" | openssl enc -aes-256-cbc -K "$key_hex" -iv "$iv_hex" -a
}

# AES-256-CBC 복호화 함수
decrypt_aes256cbc() {
  local key_hex="$1"   # 64 hex chars (256bit)
  local iv_hex="$2"    # 32 hex chars (128bit)
  local ciphertext_b64="$3"
  printf '%s\n' "$ciphertext_b64" | openssl enc -aes-256-cbc -d -K "$key_hex" -iv "$iv_hex" -a
}

# 6. 환경 변수 확인 및 입력
# EDGE_NODE_NAME을 먼저 입력받고, 파일명을 결정합니다.
EDGE_NODE_NAME=""
BASIC_ENV_FILE="$HOME/.autoA_env"
FORCE_NEW_ENV=0

# 1) EDGE_NODE_NAME 입력 및 파일명 결정
if [ -f "$BASIC_ENV_FILE" ]; then
  EXISTING_EDGE_NODE_NAME=$(grep "^EDGE_NODE_NAME=" "$BASIC_ENV_FILE" | cut -d'=' -f2-)
  if [ -n "$EXISTING_EDGE_NODE_NAME" ]; then
    echo "기존 EDGE_NODE_NAME: $EXISTING_EDGE_NODE_NAME"
    read -p "새로운 EDGE_NODE_NAME을 입력하려면 입력, 아니면 Enter: " EDGE_NODE_NAME
    if [ -z "$EDGE_NODE_NAME" ]; then
      EDGE_NODE_NAME="$EXISTING_EDGE_NODE_NAME"
    else
      log "기존 EDGE_NODE_NAME: $EXISTING_EDGE_NODE_NAME"
      log "새로운 EDGE_NODE_NAME: $EDGE_NODE_NAME"

      if [ "$EDGE_NODE_NAME" != "$EXISTING_EDGE_NODE_NAME" ]; then
        unset EDGE_NODE_PW PRIBIT_CONNECT_ID PRIBIT_CONNECT_PASSWORD HR_ID HR_PW
        FORCE_NEW_ENV=1
      fi
    fi
  else
    read -p "EDGE_NODE_NAME을 입력하세요: " EDGE_NODE_NAME
  fi
else
  read -p "EDGE_NODE_NAME을 입력하세요: " EDGE_NODE_NAME
fi

ENV_FILE="$HOME/.autoA_env.$EDGE_NODE_NAME"

# 2) 환경변수 파일 생성
if [ ! -f "$BASIC_ENV_FILE" ]; then
  touch "$BASIC_ENV_FILE"
  log ".autoA_env 파일을 생성했습니다."
fi
if [ ! -f "$ENV_FILE" ]; then
  touch "$ENV_FILE"
  log "$ENV_FILE 파일을 생성했습니다."
fi

# 3) 환경변수 저장 함수: 두 파일 모두에 저장
set_env_value() {
  local key="$1"
  local value="$2"
  if [ "$FORCE_NEW_ENV" -eq 1 ]; then
    local files=("$ENV_FILE")
  else
    local files=("$BASIC_ENV_FILE" "$ENV_FILE")
  fi
  for file in "${files[@]}"; do
    local safe_value
    safe_value=$(printf '%s\n' "$value" | sed 's/[&/]/\\&/g')
    if grep -q "^${key}=" "$file"; then
      sed -i '' "s/^${key}=.*/${key}=${safe_value}/" "$file"
    else
      echo "${key}=${value}" >> "$file"
    fi
  done
}

# 4) 환경변수 읽기 함수: EDGE_NODE_NAME별 파일 우선, 없으면 기본 파일
get_env_value() {
  local key="$1"
  local value=""
  if [ -f "$ENV_FILE" ]; then
    value=$(grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2-)
  fi
  if [ -z "$value" ] && [ -f "$BASIC_ENV_FILE" ]; then
    value=$(grep "^${key}=" "$BASIC_ENV_FILE" | cut -d'=' -f2-)
  fi
  echo "$value"
}

log "환경 변수 설정 시작..."

# EDGE_NODE_NAME 저장
set_env_value "EDGE_NODE_NAME" "$EDGE_NODE_NAME"
export EDGE_NODE_NAME="$EDGE_NODE_NAME"
log "EDGE_NODE_NAME=$EDGE_NODE_NAME"

# EDGE_NODE_PW 처리
if [ -z "$EDGE_NODE_PW" ]; then
  existing_edge_node_pw=$(get_env_value "EDGE_NODE_PW")
  if [ -n "$existing_edge_node_pw" ] && [ "$FORCE_NEW_ENV" -eq 0 ]; then
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

  # 암호화 키 파일에서 키 읽기
  if [ -f "$KEY_FILE" ]; then
    source "$KEY_FILE"
    log "암호화 키를 로드했습니다."
    
    # 암호화 테스트
    ENC_EDGE_NODE_PW=$(encrypt_aes256cbc "$SECRET_KEY_HEX" "$SECRET_IV_HEX" "$EDGE_NODE_PW")
    log "암호화된 EDGE_NODE_PW: $ENC_EDGE_NODE_PW"
    
    # 복호화 테스트
    DEC_EDGE_NODE_PW=$(decrypt_aes256cbc "$SECRET_KEY_HEX" "$SECRET_IV_HEX" "$ENC_EDGE_NODE_PW")
    log "복호화된 EDGE_NODE_PW: $DEC_EDGE_NODE_PW"
    
    # 암호화된 비밀번호를 환경 변수로 저장
    export ENC_EDGE_NODE_PW="$ENC_EDGE_NODE_PW"
  else
    log "경고: 암호화 키 파일이 없습니다: $KEY_FILE"
  fi
fi

# PRIBIT_CONNECT_ID 처리
if [ -z "$PRIBIT_CONNECT_ID" ]; then
  existing_pribit_connect_id=$(get_env_value "PRIBIT_CONNECT_ID")
  if [ -n "$existing_pribit_connect_id" ] && [ "$FORCE_NEW_ENV" -eq 0 ]; then
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
  if [ -n "$existing_pribit_connect_password" ] && [ "$FORCE_NEW_ENV" -eq 0 ]; then
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

  if [ -f "$KEY_FILE" ]; then
    source "$KEY_FILE"
    log "암호화 키를 로드했습니다."
    
    # 암호화 테스트
    ENC_PRIBIT_CONNECT_PASSWORD=$(encrypt_aes256cbc "$SECRET_KEY_HEX" "$SECRET_IV_HEX" "$PRIBIT_CONNECT_PASSWORD")
    log "암호화된 PRIBIT_CONNECT_PASSWORD: $ENC_PRIBIT_CONNECT_PASSWORD"
    
    # 복호화 테스트
    DEC_PRIBIT_CONNECT_PASSWORD=$(decrypt_aes256cbc "$SECRET_KEY_HEX" "$SECRET_IV_HEX" "$ENC_PRIBIT_CONNECT_PASSWORD")
    log "복호화된 PRIBIT_CONNECT_PASSWORD: $DEC_PRIBIT_CONNECT_PASSWORD"
    
    # 암호화된 비밀번호를 환경 변수로 저장
    export ENC_PRIBIT_CONNECT_PASSWORD="$ENC_PRIBIT_CONNECT_PASSWORD"
  else
    log "경고: 암호화 키 파일이 없습니다: $KEY_FILE"
  fi
fi

# HR_ID 처리
if [ -z "$HR_ID" ]; then
  existing_hr_id=$(get_env_value "HR_ID")
  if [ -n "$existing_hr_id" ] && [ "$FORCE_NEW_ENV" -eq 0 ]; then
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
  if [ -n "$existing_hr_pw" ] && [ "$FORCE_NEW_ENV" -eq 0 ]; then
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

  if [ -f "$KEY_FILE" ]; then
    source "$KEY_FILE"
    log "암호화 키를 로드했습니다."
    
    # 암호화 테스트
    ENC_HR_PW=$(encrypt_aes256cbc "$SECRET_KEY_HEX" "$SECRET_IV_HEX" "$HR_PW")
    log "암호화된 HR_PW: $ENC_HR_PW"
    
    # 복호화 테스트
    DEC_HR_PW=$(decrypt_aes256cbc "$SECRET_KEY_HEX" "$SECRET_IV_HEX" "$ENC_HR_PW")
    log "복호화된 HR_PW: $DEC_HR_PW"
    
    # 암호화된 비밀번호를 환경 변수로 저장
    export ENC_HR_PW="$ENC_HR_PW"
  else
    log "경고: 암호화 키 파일이 없습니다: $KEY_FILE"
  fi
fi

log "모든 환경변수가 설정되었습니다."
log ".autoA_env 파일 위치: $BASIC_ENV_FILE"
log "현재 사용 중인 환경변수 파일: $ENV_FILE"

echo ""
echo "=== AutoA PCManager 환경 설정 완료 ==="
echo "모든 설정이 완료되었습니다."
# echo "설정 파일 위치: $ENV_FILE"
cat $ENV_FILE
# echo ""