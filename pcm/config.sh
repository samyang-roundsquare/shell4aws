#!/bin/bash

# 로그 함수
default_log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}
log() { default_log "$@"; }

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

install_node_v20_with_nvm() {
  log "nvm을 통해 Node.js v20.x.x 설치를 시작합니다..."
  nvm install 20
  nvm use 20
  nvm alias default 20
  if check_node_version; then
    log "nvm을 통한 Node.js v20.x.x 설치가 완료되었습니다."
    node --version
    npm --version
    log "yarn 전역 설치 중..."
    npm install -g yarn
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

install_node_v20_with_homebrew() {
  log "Homebrew를 통해 Node.js v20.x.x 설치를 시작합니다..."
  brew update
  brew install node@20
  local node_path=$(brew --prefix node@20)
  if [[ ":$PATH:" != *":$node_path/bin:"* ]]; then
    echo 'export PATH="'$node_path'/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="'$node_path'/bin:$PATH"' >> ~/.bash_profile
    export PATH="$node_path/bin:$PATH"
    log "Node.js v20 PATH가 설정되었습니다."
  fi
  if check_node_version; then
    log "Homebrew를 통한 Node.js v20.x.x 설치가 완료되었습니다."
    node --version
    npm --version
    log "yarn 전역 설치 중..."
    npm install -g yarn
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

if ! check_node_version; then
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
KEY_FILE="$HOME/.autoA_key"
log "암호화 키 파일 경로: $KEY_FILE"
if [ ! -f "$KEY_FILE" ]; then
  log "암호화 키 파일이 없습니다. 새로운 키를 생성합니다."
  KEY_HEX=$(openssl rand -hex 32)
  IV_HEX=$(openssl rand -hex 16)
  cat <<EOF > "$KEY_FILE"
SECRET_KEY_HEX=$KEY_HEX
SECRET_IV_HEX=$IV_HEX
EOF
  log ".autoA_key 파일이 생성되었습니다:"
  cat "$KEY_FILE"
else
  log "기존 암호화 키 파일이 존재합니다: $KEY_FILE"
fi

encrypt_aes256cbc() {
  local key_hex="$1"
  local iv_hex="$2"
  local plaintext="$3"
  printf '%s' "$plaintext" | openssl enc -aes-256-cbc -K "$key_hex" -iv "$iv_hex" -a
}

decrypt_aes256cbc() {
  local key_hex="$1"
  local iv_hex="$2"
  local ciphertext_b64="$3"
  printf '%s\n' "$ciphertext_b64" | openssl enc -aes-256-cbc -d -K "$key_hex" -iv "$iv_hex" -a
}

# 6. 환경 변수 확인 및 입력
ENV_FILE="$HOME/.autoA_env"
log "환경 설정 파일 경로: $ENV_FILE"
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
log ".autoA_env 파일 위치: $ENV_FILE"

echo ""
echo "=== AutoA PCManager 환경 설정 완료 ==="
echo "모든 설정이 완료되었습니다."
# echo "설정 파일 위치: $ENV_FILE"
cat $ENV_FILE
# echo ""