#!/bin/bash

# shell4aws - macOS 설치 스크립트 (통합 버전)
# AWS EC2 설정을 위한 macOS 환경 구성
# Google Drive 파일 다운로드 기능 포함
# 작성자: shell4aws 팀
# 버전: 2.0.0

set -e  # 오류 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수들
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Google Drive 다운로드 기능 (download-helper.sh 통합)
# =============================================================================

# Google Drive 파일 ID 추출
extract_file_id() {
    local url="$1"
    local file_id
    
    # 다양한 Google Drive URL 형식 처리
    if [[ "$url" =~ /file/d/([a-zA-Z0-9_-]+) ]]; then
        file_id="${BASH_REMATCH[1]}"
    elif [[ "$url" =~ id=([a-zA-Z0-9_-]+) ]]; then
        file_id="${BASH_REMATCH[1]}"
    else
        log_error "Google Drive URL에서 파일 ID를 추출할 수 없습니다: $url"
        return 1
    fi
    
    echo "$file_id"
}

# 방법 1: curl을 사용한 직접 다운로드 (개선된 버전)
download_with_curl() {
    local file_id="$1"
    local output_file="$2"
    local url="https://drive.google.com/uc?export=download&id=$file_id"
    
    log_info "curl을 사용하여 다운로드 시도 중..."
    
    # 첫 번째 요청으로 쿠키와 확인 토큰 가져오기
    local temp_file=$(mktemp)
    local cookies_file=$(mktemp)
    
    if curl -c "$cookies_file" -L -o "$temp_file" "$url"; then
        # 확인 토큰 추출 (Google Drive의 바이러스 스캔 확인 페이지)
        local confirm_token=$(grep -o 'confirm=[^&]*' "$temp_file" | cut -d'=' -f2)
        
        if [[ -n "$confirm_token" ]]; then
            log_info "확인 토큰 발견: $confirm_token"
            # 확인 토큰을 사용하여 실제 다운로드
            local download_url="https://drive.google.com/uc?export=download&confirm=${confirm_token}&id=$file_id"
            
            if curl -b "$cookies_file" -L -o "$output_file" "$download_url"; then
                log_success "curl 다운로드 성공 (확인 토큰 사용)"
                rm -f "$temp_file" "$cookies_file"
                return 0
            fi
        else
            # 확인 토큰이 없으면 첫 번째 응답이 실제 파일일 수 있음
            if [[ -s "$temp_file" ]]; then
                # 파일이 HTML 페이지인지 확인 (Google Drive 오류 페이지)
                if grep -q "<!DOCTYPE html\|<html\|<title>Google Drive\|<title>Sign in" "$temp_file"; then
                    log_warning "Google Drive에서 HTML 페이지를 받았습니다. 확인 토큰이 필요할 수 있습니다."
                    rm -f "$temp_file" "$cookies_file"
                    return 1
                fi
                
                mv "$temp_file" "$output_file"
                log_success "curl 다운로드 성공 (직접 다운로드)"
                rm -f "$cookies_file"
                return 0
            fi
        fi
    fi
    
    rm -f "$temp_file" "$cookies_file"
    log_warning "curl 다운로드 실패"
    return 1
}

# 방법 2: wget을 사용한 다운로드 (개선된 버전)
download_with_wget() {
    local file_id="$1"
    local output_file="$2"
    local url="https://drive.google.com/uc?export=download&id=$file_id"
    
    log_info "wget을 사용하여 다운로드 시도 중..."
    
    if command -v wget &> /dev/null; then
        # wget으로 쿠키와 확인 토큰 처리
        local temp_file=$(mktemp)
        local cookies_file=$(mktemp)
        
        if wget --save-cookies "$cookies_file" --keep-session-cookies --no-check-certificate -O "$temp_file" "$url"; then
            # 확인 토큰 추출
            local confirm_token=$(grep -o 'confirm=[^&]*' "$temp_file" | cut -d'=' -f2)
            
            if [[ -n "$confirm_token" ]]; then
                log_info "확인 토큰 발견: $confirm_token"
                local download_url="https://drive.google.com/uc?export=download&confirm=${confirm_token}&id=$file_id"
                
                if wget --load-cookies "$cookies_file" --no-check-certificate -O "$output_file" "$download_url"; then
                    log_success "wget 다운로드 성공 (확인 토큰 사용)"
                    rm -f "$temp_file" "$cookies_file"
                    return 0
                fi
            else
                if [[ -s "$temp_file" ]]; then
                    # 파일이 HTML 페이지인지 확인 (Google Drive 오류 페이지)
                    if grep -q "<!DOCTYPE html\|<html\|<title>Google Drive\|<title>Sign in" "$temp_file"; then
                        log_warning "Google Drive에서 HTML 페이지를 받았습니다. 확인 토큰이 필요할 수 있습니다."
                        rm -f "$temp_file" "$cookies_file"
                        return 1
                    fi
                    
                    mv "$temp_file" "$output_file"
                    log_success "wget 다운로드 성공 (직접 다운로드)"
                    rm -f "$cookies_file"
                    return 0
                fi
            fi
        fi
        
        rm -f "$temp_file" "$cookies_file"
        log_warning "wget 다운로드 실패"
        return 1
    else
        log_warning "wget이 설치되지 않았습니다"
        return 1
    fi
}

# 방법 3: gdown을 사용한 다운로드 (Python 패키지)
download_with_gdown() {
    local file_id="$1"
    local output_file="$2"
    
    log_info "gdown을 사용하여 다운로드 시도 중..."
    
    # gdown 설치 확인 및 설치
    if ! command -v gdown &> /dev/null; then
        log_info "gdown 설치 중..."
        if command -v pip3 &> /dev/null; then
            pip3 install gdown
        elif command -v pip &> /dev/null; then
            pip install gdown
        else
            log_warning "pip이 설치되지 않았습니다"
            return 1
        fi
    fi
    
    if gdown "https://drive.google.com/uc?id=$file_id" -O "$output_file"; then
        log_success "gdown 다운로드 성공"
        return 0
    else
        log_warning "gdown 다운로드 실패"
        return 1
    fi
}

# 방법 4: rclone을 사용한 다운로드
download_with_rclone() {
    local file_id="$1"
    local output_file="$2"
    
    log_info "rclone을 사용하여 다운로드 시도 중..."
    
    # rclone 설치 확인 및 설치
    if ! command -v rclone &> /dev/null; then
        log_info "rclone 설치 중..."
        if command -v brew &> /dev/null; then
            brew install rclone
        else
            log_warning "Homebrew가 설치되지 않았습니다. rclone을 수동으로 설치해주세요."
            return 1
        fi
    fi
    
    # 임시 rclone 설정 생성
    local config_file=$(mktemp)
    cat > "$config_file" << EOF
[gdrive]
type = drive
scope = drive.readonly
token = 
EOF
    
    # rclone으로 다운로드 시도
    if rclone --config "$config_file" copy "gdrive:$file_id" "$(dirname "$output_file")" --drive-shared-with-me; then
        # 파일명 변경 (rclone은 원본 파일명을 사용)
        local downloaded_file=$(find "$(dirname "$output_file")" -name "*" -type f -newer "$config_file" | head -1)
        if [[ -n "$downloaded_file" ]]; then
            mv "$downloaded_file" "$output_file"
            log_success "rclone 다운로드 성공"
            rm -f "$config_file"
            return 0
        fi
    fi
    
    rm -f "$config_file"
    log_warning "rclone 다운로드 실패"
    return 1
}

# 방법 5: 강화된 curl 다운로드 (User-Agent 및 추가 헤더 사용)
download_with_curl_enhanced() {
    local file_id="$1"
    local output_file="$2"
    
    log_info "강화된 curl 다운로드를 시도 중..."
    
    # User-Agent와 추가 헤더를 사용한 다운로드
    local user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    local url="https://drive.google.com/uc?export=download&id=$file_id"
    
    # 첫 번째 요청으로 쿠키와 확인 토큰 가져오기
    local temp_file=$(mktemp)
    local cookies_file=$(mktemp)
    
    if curl -A "$user_agent" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
           -H "Accept-Language: en-US,en;q=0.5" \
           -H "Accept-Encoding: gzip, deflate" \
           -H "Connection: keep-alive" \
           -H "Upgrade-Insecure-Requests: 1" \
           -c "$cookies_file" -L -o "$temp_file" "$url"; then
        
        # 확인 토큰 추출
        local confirm_token=$(grep -o 'confirm=[^&]*' "$temp_file" | cut -d'=' -f2)
        
        if [[ -n "$confirm_token" ]]; then
            log_info "확인 토큰 발견: $confirm_token"
            local download_url="https://drive.google.com/uc?export=download&confirm=${confirm_token}&id=$file_id"
            
            if curl -A "$user_agent" -b "$cookies_file" -L -o "$output_file" "$download_url"; then
                log_success "강화된 curl 다운로드 성공 (확인 토큰 사용)"
                rm -f "$temp_file" "$cookies_file"
                return 0
            fi
        else
            # HTML 페이지 확인
            if grep -q "<!DOCTYPE html\|<html\|<title>Google Drive\|<title>Sign in" "$temp_file"; then
                log_warning "Google Drive에서 HTML 페이지를 받았습니다."
                rm -f "$temp_file" "$cookies_file"
                return 1
            fi
            
            if [[ -s "$temp_file" ]]; then
                mv "$temp_file" "$output_file"
                log_success "강화된 curl 다운로드 성공 (직접 다운로드)"
                rm -f "$cookies_file"
                return 0
            fi
        fi
    fi
    
    rm -f "$temp_file" "$cookies_file"
    log_warning "강화된 curl 다운로드 실패"
    return 1
}

# 수동 다운로드 안내 (개선된 버전)
manual_download_guide() {
    local url="$1"
    local output_file="$2"
    local file_id="$3"
    
    log_warning "자동 다운로드에 실패했습니다. 수동 다운로드를 진행해주세요."
    echo ""
    echo "📋 수동 다운로드 방법:"
    echo "1. 다음 URL로 이동: $url"
    echo "2. '다운로드' 버튼을 클릭하세요"
    echo "3. 파일을 다운로드하여 현재 디렉토리의 '$output_file'로 저장하세요"
    echo "4. 다운로드 완료 후 스크립트를 다시 실행하세요"
    echo ""
    echo "🔗 직접 다운로드 링크 (시도해보세요):"
    echo "   https://drive.google.com/uc?export=download&id=$file_id"
    echo ""
    echo "💡 팁:"
    echo "   - 파일이 크면 Google Drive에서 '다운로드할 수 없습니다' 메시지가 나타날 수 있습니다"
    echo "   - 이 경우 '다운로드' 버튼을 우클릭하여 '다른 이름으로 저장'을 선택하세요"
    echo "   - 또는 '다운로드' 버튼을 클릭한 후 '다운로드할 수 없습니다' 메시지가 나오면"
    echo "     '다운로드' 버튼을 다시 클릭하거나 우클릭하여 '다른 이름으로 저장'을 선택하세요"
    echo ""
    echo "🔄 대안 방법:"
    echo "   - Google Drive 앱을 사용하여 파일을 다운로드"
    echo "   - 다른 브라우저로 시도"
    echo "   - 시크릿/프라이빗 모드에서 시도"
    echo ""
    
    # curl로 실행 중인지 확인
    if [[ "${BASH_SOURCE[0]}" == *"curl"* ]] || [[ -z "${BASH_SOURCE[0]}" ]]; then
        log_info "curl로 실행 중이므로 브라우저를 자동으로 열 수 없습니다."
        log_info "위의 URL을 복사하여 브라우저에서 직접 접속해주세요."
        echo ""
        log_info "다운로드 완료 후 다음 명령어로 스크립트를 다시 실행하세요:"
        echo "   curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/install.sh | bash"
        echo ""
        return 1
    else
        # 브라우저에서 URL 열기
        if command -v open &> /dev/null; then
            log_info "브라우저에서 다운로드 페이지를 엽니다..."
            open "$url"
        fi
        
        # 사용자에게 대기 요청
        echo ""
        read -p "파일을 다운로드한 후 Enter 키를 눌러 계속하세요..."
        
        # 다운로드된 파일 확인
        if [[ -f "$output_file" ]]; then
            local file_size=$(du -h "$output_file" | cut -f1)
            local file_size_bytes=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo 0)
            
            # 파일 크기 검사
            if [[ $file_size_bytes -lt 10000 ]]; then
                log_warning "다운로드된 파일이 너무 작습니다 ($file_size_bytes bytes)."
                if grep -q "<!DOCTYPE html\|<html\|<title>Google Drive\|<title>Sign in" "$output_file"; then
                    log_error "HTML 페이지가 다운로드되었습니다. 올바른 파일을 다운로드해주세요."
                    return 1
                fi
            fi
            
            log_success "파일이 확인되었습니다! 크기: $file_size"
            return 0
        else
            log_error "파일을 찾을 수 없습니다: $output_file"
            return 1
        fi
    fi
}

# 파일 유효성 검사
validate_downloaded_file() {
    local file_path="$1"
    local expected_type="$2"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "파일이 존재하지 않습니다: $file_path"
        return 1
    fi
    
    if [[ ! -s "$file_path" ]]; then
        log_error "파일이 비어있습니다: $file_path"
        return 1
    fi
    
    # 파일 크기 확인 (너무 작은 파일은 HTML 페이지일 가능성)
    local file_size_bytes=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo 0)
    if [[ $file_size_bytes -lt 10000 ]]; then  # 10KB 미만
        log_warning "파일이 너무 작습니다 ($file_size_bytes bytes). HTML 페이지일 수 있습니다."
        
        # HTML 페이지인지 확인
        if grep -q "<!DOCTYPE html\|<html\|<title>Google Drive\|<title>Sign in" "$file_path"; then
            log_error "다운로드된 파일이 HTML 페이지입니다. Google Drive에서 오류 페이지를 받았습니다."
            return 1
        fi
    fi
    
    # 파일 타입별 검사
    case "$expected_type" in
        "tar.gz"|"tgz")
            if ! tar -tzf "$file_path" > /dev/null 2>&1; then
                log_error "파일이 유효한 tar.gz 형식이 아닙니다: $file_path"
                return 1
            fi
            ;;
        "pkg")
            if ! file "$file_path" | grep -q "xar archive"; then
                log_warning "파일이 macOS 패키지 형식이 아닐 수 있습니다: $file_path"
            fi
            ;;
    esac
    
    local file_size=$(du -h "$file_path" | cut -f1)
    log_success "파일 유효성 검사 통과! 크기: $file_size"
    return 0
}

# 메인 다운로드 함수
download_google_drive_file() {
    local url="$1"
    local output_file="$2"
    
    log_info "Google Drive 파일 다운로드 시작: $url"
    log_info "출력 파일: $output_file"
    
    # 파일 ID 추출
    local file_id
    file_id=$(extract_file_id "$url")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    log_info "파일 ID: $file_id"
    
    # 파일 확장자 추출
    local file_extension=""
    if [[ "$output_file" =~ \.([^.]+)$ ]]; then
        file_extension="${BASH_REMATCH[1]}"
    fi
    
    # 다양한 다운로드 방법 시도
    local methods=("download_with_curl" "download_with_curl_enhanced" "download_with_wget" "download_with_gdown" "download_with_rclone")
    
    for method in "${methods[@]}"; do
        log_info "방법 시도: $method"
        if $method "$file_id" "$output_file"; then
            # 파일 유효성 검사
            if validate_downloaded_file "$output_file" "$file_extension"; then
                local file_size=$(du -h "$output_file" | cut -f1)
                log_success "다운로드 완료! 파일 크기: $file_size"
                return 0
            else
                log_warning "다운로드된 파일이 유효하지 않습니다"
                rm -f "$output_file"
            fi
        fi
    done
    
    # 모든 자동 방법이 실패한 경우 수동 다운로드 안내
    if manual_download_guide "$url" "$output_file" "$file_id"; then
        return 0
    else
        # curl로 실행 중이고 수동 다운로드도 실패한 경우
        if [[ "${BASH_SOURCE[0]}" == *"curl"* ]] || [[ -z "${BASH_SOURCE[0]}" ]]; then
            log_error "curl로 실행 중이므로 수동 다운로드가 제한됩니다."
            log_info "다음 방법으로 로컬에서 실행해주세요:"
            echo ""
            echo "1. 스크립트 다운로드:"
            echo "   curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/install.sh -o install.sh"
            echo ""
            echo "2. 실행 권한 부여:"
            echo "   chmod +x install.sh"
            echo ""
            echo "3. 스크립트 실행:"
            echo "   ./install.sh"
            echo ""
            log_info "로컬에서 실행하면 브라우저 자동 실행 및 수동 다운로드 가이드가 정상 작동합니다."
            exit 1
        fi
        return 1
    fi
}

# =============================================================================
# 설치 기능
# =============================================================================

# 오류 복구 함수
cleanup_on_error() {
    log_error "설치 중 오류가 발생했습니다."
    log_info "임시 파일들을 정리합니다..."
    
    # 임시 디렉토리들 정리
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_info "서버 이미지 임시 파일 정리 완료"
    fi
    
    if [[ -n "$AGENT_TEMP_DIR" && -d "$AGENT_TEMP_DIR" ]]; then
        rm -rf "$AGENT_TEMP_DIR"
        log_info "에이전트 패키지 임시 파일 정리 완료"
    fi
    
    log_info "문제 해결 방법:"
    log_info "1. 인터넷 연결 상태를 확인하세요"
    log_info "2. 관리자 권한이 있는지 확인하세요"
    log_info "3. 충분한 디스크 공간이 있는지 확인하세요"
    log_info "4. README.md의 문제 해결 섹션을 참조하세요"
    
    exit 1
}

# 오류 트랩 설정
trap cleanup_on_error ERR

# 1. macOS 확인
check_macos() {
    log_info "1단계: macOS 환경 확인 중..."
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "이 스크립트는 macOS에서만 실행할 수 있습니다."
        log_error "현재 OS: $OSTYPE"
        exit 1
    fi
    
    # macOS 버전 확인
    MACOS_VERSION=$(sw_vers -productVersion)
    log_success "macOS 버전 확인: $MACOS_VERSION"
    
    # 아키텍처 확인 (Intel vs Apple Silicon)
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        log_info "Apple Silicon (M1/M2) 프로세서 감지됨"
    else
        log_info "Intel 프로세서 감지됨"
    fi
}

# 2-1. Homebrew 설치
install_homebrew() {
    log_info "2-1단계: Homebrew 설치 중..."
    
    if command -v brew &> /dev/null; then
        log_success "Homebrew가 이미 설치되어 있습니다."
        log_info "Homebrew 버전: $(brew --version | head -n1)"
    else
        log_info "Homebrew를 설치합니다..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Apple Silicon의 경우 PATH 설정
        if [[ "$ARCH" == "arm64" ]]; then
            log_info "Apple Silicon용 PATH 설정 중..."
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        log_success "Homebrew 설치 완료"
    fi
}

# 2-2. 필요한 패키지 설치
install_packages() {
    log_info "2-2단계: 필요한 패키지 설치 중..."
    
    # Homebrew 업데이트
    log_info "Homebrew 업데이트 중..."
    brew update
    
    # Docker Desktop 설치
    if ! command -v docker &> /dev/null; then
        log_info "Docker Desktop 설치 중..."
        brew install --cask docker
        log_success "Docker Desktop 설치 완료"
        log_warning "Docker Desktop을 실행해주세요. (Applications 폴더에서 Docker 앱 실행)"
    else
        log_success "Docker가 이미 설치되어 있습니다."
    fi
    
    # Docker Compose 설치
    if ! command -v docker-compose &> /dev/null; then
        log_info "Docker Compose 설치 중..."
        brew install docker-compose
        log_success "Docker Compose 설치 완료"
    else
        log_success "Docker Compose가 이미 설치되어 있습니다."
    fi
    
    # cliclick 설치 (macOS 자동화 도구)
    if ! command -v cliclick &> /dev/null; then
        log_info "cliclick 설치 중..."
        brew install cliclick
        log_success "cliclick 설치 완료"
    else
        log_success "cliclick이 이미 설치되어 있습니다."
    fi
}

# 3. Docker 서비스 확인 및 실행
check_docker_service() {
    log_info "3단계: Docker 서비스 확인 중..."
    
    # Docker Desktop이 실행 중인지 확인
    if ! docker info &> /dev/null; then
        log_warning "Docker Desktop이 실행되지 않았습니다."
        log_info "Docker Desktop을 시작합니다..."
        
        # Docker Desktop 실행
        open -a Docker
        
        # Docker가 완전히 시작될 때까지 대기
        log_info "Docker Desktop 시작 대기 중... (최대 60초)"
        for i in {1..60}; do
            if docker info &> /dev/null; then
                log_success "Docker Desktop이 성공적으로 시작되었습니다."
                break
            fi
            sleep 1
        done
        
        if ! docker info &> /dev/null; then
            log_error "Docker Desktop 시작에 실패했습니다. 수동으로 실행해주세요."
            exit 1
        fi
    else
        log_success "Docker Desktop이 이미 실행 중입니다."
    fi
}

# 3-1. 서버 이미지 다운로드
download_server_image() {
    log_info "3-1단계: 서버 이미지 다운로드 중..."
    
    # 임시 디렉토리 생성
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Google Drive 파일 URL
    SERVER_FILE_URL="https://drive.google.com/file/d/1PhD7xtKZo5CmOkcIARM7V2BkZzeIr4H3/view?usp=sharing"
    log_info "서버 이미지 파일 다운로드 중..."
    log_info "URL: $SERVER_FILE_URL"
    
    # 통합된 다운로드 함수 사용
    if download_google_drive_file "$SERVER_FILE_URL" "server_image.tar.gz"; then
        log_success "서버 이미지 다운로드 완료"
        
        # 파일 유효성 검사
        if [[ -f "server_image.tar.gz" && -s "server_image.tar.gz" ]]; then
            local file_size=$(du -h server_image.tar.gz | cut -f1)
            log_info "다운로드된 파일 크기: $file_size"
            
            # tar.gz 파일 유효성 검사
            if tar -tzf server_image.tar.gz > /dev/null 2>&1; then
                log_success "서버 이미지 파일 유효성 검사 통과"
            else
                log_error "다운로드된 파일이 유효한 tar.gz 형식이 아닙니다"
                log_info "파일이 손상되었을 수 있습니다. 다시 다운로드해주세요."
                exit 1
            fi
        else
            log_error "다운로드된 파일이 비어있거나 존재하지 않습니다"
            exit 1
        fi
    else
        log_error "서버 이미지 다운로드 실패"
        log_info "수동으로 다운로드한 후 스크립트를 다시 실행하세요."
        exit 1
    fi
}

# 3-2. 이미지 압축 해제 및 Docker 실행
setup_server_container() {
    log_info "3-2단계: 서버 컨테이너 설정 중..."
    
    # 기존 컨테이너가 있다면 제거
    if docker ps -a --format "table {{.Names}}" | grep -q "autoA-MCP"; then
        log_info "기존 autoA-MCP 컨테이너 제거 중..."
        docker rm -f autoA-MCP
    fi
    
    # 이미지 로드
    log_info "Docker 이미지 로드 중..."
    if docker load -i server_image.tar.gz; then
        log_success "Docker 이미지 로드 완료"
    else
        log_error "Docker 이미지 로드 실패"
        exit 1
    fi
    
    # 컨테이너 실행
    log_info "서버 컨테이너 실행 중..."
    if docker run --name autoA-MCP -d -p 58787:8787 autoa-mcp-server:latest; then
        log_success "서버 컨테이너 실행 완료"
    else
        log_error "서버 컨테이너 실행 실패"
        exit 1
    fi
}

# 3-3. 서비스 상태 확인
check_server_status() {
    log_info "3-3단계: 서버 상태 확인 중..."
    
    # 컨테이너 상태 확인
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "autoA-MCP.*Up"; then
        log_success "서버 컨테이너가 정상적으로 실행 중입니다."
        
        # 포트 연결 확인
        if curl -s http://localhost:58787 > /dev/null; then
            log_success "서버가 포트 58787에서 정상 응답합니다."
        else
            log_warning "서버 포트 연결 확인 실패. 잠시 후 다시 시도해주세요."
        fi
    else
        log_error "서버 컨테이너가 정상적으로 실행되지 않았습니다."
        docker logs autoA-MCP
        exit 1
    fi
}

# 4. 에이전트 패키지 다운로드
download_agent_package() {
    log_info "4단계: 에이전트 패키지 다운로드 중..."
    
    # 임시 디렉토리 생성
    AGENT_TEMP_DIR=$(mktemp -d)
    cd "$AGENT_TEMP_DIR"
    
    # Google Drive 파일 URL
    AGENT_FILE_URL="https://drive.google.com/file/d/1cfMLZE5tto4IHQd4VmIfv0a2nR02MTwW/view?usp=sharing"
    log_info "에이전트 패키지 다운로드 중..."
    log_info "URL: $AGENT_FILE_URL"
    
    # 통합된 다운로드 함수 사용
    if download_google_drive_file "$AGENT_FILE_URL" "agent.pkg"; then
        log_success "에이전트 패키지 다운로드 완료"
        
        # 파일 유효성 검사
        if [[ -f "agent.pkg" && -s "agent.pkg" ]]; then
            local file_size=$(du -h agent.pkg | cut -f1)
            log_info "다운로드된 파일 크기: $file_size"
            
            # pkg 파일 유효성 검사
            if file agent.pkg | grep -q "xar archive\|Mac OS X installer package"; then
                log_success "에이전트 패키지 파일 유효성 검사 통과"
            else
                log_warning "다운로드된 파일이 macOS 패키지 형식이 아닐 수 있습니다"
                log_info "파일이 손상되었을 수 있지만 설치를 계속 진행합니다."
            fi
        else
            log_error "다운로드된 파일이 비어있거나 존재하지 않습니다"
            exit 1
        fi
    else
        log_error "에이전트 패키지 다운로드 실패"
        log_info "수동으로 다운로드한 후 스크립트를 다시 실행하세요."
        exit 1
    fi
}

# 4-1. 에이전트 패키지 설치
install_agent_package() {
    log_info "4-1단계: 에이전트 패키지 설치 중..."
    
    # 관리자 권한 확인
    if [[ $EUID -ne 0 ]]; then
        log_info "관리자 권한으로 패키지 설치를 진행합니다..."
        sudo installer -pkg agent.pkg -target /
    else
        installer -pkg agent.pkg -target /
    fi
    
    log_success "에이전트 패키지 설치 완료"
}

# 4-2. 설치된 파일 목록 확인
list_installed_files() {
    log_info "4-2단계: 설치된 파일 목록 확인 중..."
    
    # 일반적인 설치 경로들 확인
    INSTALL_PATHS=("/Applications" "/usr/local/bin" "/opt" "/Library/Application Support")
    
    for path in "${INSTALL_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            log_info "=== $path 디렉토리 내용 ==="
            ls -la "$path" | head -20
            echo ""
        fi
    done
    
    log_success "설치된 파일 목록 확인 완료"
}

# 5. 임시 파일 정리
cleanup_temp_files() {
    log_info "5단계: 임시 파일 정리 중..."
    
    # 임시 디렉토리들 정리
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_success "서버 이미지 임시 파일 정리 완료"
    fi
    
    if [[ -d "$AGENT_TEMP_DIR" ]]; then
        rm -rf "$AGENT_TEMP_DIR"
        log_success "에이전트 패키지 임시 파일 정리 완료"
    fi
    
    log_success "모든 임시 파일 정리 완료"
}

# 메인 실행 함수
main() {
    log_info "=== shell4aws macOS 설치 시작 (통합 버전) ==="
    log_info "설치 시간: $(date)"
    log_info "현재 디렉토리: $(pwd)"
    
    # curl로 실행 중인지 확인
    if [[ "${BASH_SOURCE[0]}" == *"curl"* ]] || [[ -z "${BASH_SOURCE[0]}" ]]; then
        log_warning "curl로 실행 중입니다. 일부 기능이 제한될 수 있습니다."
        log_info "더 나은 경험을 위해 로컬에 스크립트를 다운로드하여 실행하는 것을 권장합니다."
        echo ""
        log_info "로컬 다운로드 방법:"
        echo "   curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/install.sh -o install.sh"
        echo "   chmod +x install.sh"
        echo "   ./install.sh"
        echo ""
        read -p "계속 진행하시겠습니까? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "설치가 취소되었습니다."
            exit 0
        fi
    fi
    
    # 스크립트 디렉토리 저장 (다운로드 헬퍼 경로용)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    log_info "스크립트 디렉토리: $SCRIPT_DIR"
    
    # 설치 전 확인사항
    log_info "설치 전 확인사항:"
    log_info "- 인터넷 연결 상태 확인"
    log_info "- 관리자 권한 필요 (패키지 설치 시)"
    log_info "- 최소 10GB 디스크 공간 필요"
    echo ""
    
    # Google Drive 다운로드 관련 안내
    log_info "📋 Google Drive 파일 다운로드 안내:"
    log_info "   이 설치 과정에서 Google Drive에서 파일을 다운로드합니다."
    log_info "   Google Drive는 큰 파일의 직접 다운로드를 제한할 수 있습니다."
    log_info "   자동 다운로드가 실패하면 수동 다운로드 가이드가 제공됩니다."
    log_info "   통합된 다운로드 기능으로 다양한 방법을 자동으로 시도합니다."
    echo ""
    
    # 사용자 확인
    read -p "설치를 계속하시겠습니까? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "설치가 취소되었습니다."
        exit 0
    fi
    
    # 각 단계 실행 (오류 처리 포함)
    local step=1
    local total_steps=11
    
    # 1단계: macOS 확인
    log_info "=== 단계 $step/$total_steps: macOS 환경 확인 ==="
    check_macos
    ((step++))
    
    # 2-1단계: Homebrew 설치
    log_info "=== 단계 $step/$total_steps: Homebrew 설치 ==="
    install_homebrew
    ((step++))
    
    # 2-2단계: 패키지 설치
    log_info "=== 단계 $step/$total_steps: 필요한 패키지 설치 ==="
    install_packages
    ((step++))
    
    # 3단계: Docker 서비스 확인
    log_info "=== 단계 $step/$total_steps: Docker 서비스 확인 ==="
    check_docker_service
    ((step++))
    
    # 3-1단계: 서버 이미지 다운로드
    log_info "=== 단계 $step/$total_steps: 서버 이미지 다운로드 ==="
    download_server_image
    ((step++))
    
    # 3-2단계: 서버 컨테이너 설정
    log_info "=== 단계 $step/$total_steps: 서버 컨테이너 설정 ==="
    setup_server_container
    ((step++))
    
    # 3-3단계: 서버 상태 확인
    log_info "=== 단계 $step/$total_steps: 서버 상태 확인 ==="
    check_server_status
    ((step++))
    
    # 4단계: 에이전트 패키지 다운로드
    log_info "=== 단계 $step/$total_steps: 에이전트 패키지 다운로드 ==="
    download_agent_package
    ((step++))
    
    # 4-1단계: 에이전트 패키지 설치
    log_info "=== 단계 $step/$total_steps: 에이전트 패키지 설치 ==="
    install_agent_package
    ((step++))
    
    # 4-2단계: 설치된 파일 목록 확인
    log_info "=== 단계 $step/$total_steps: 설치된 파일 목록 확인 ==="
    list_installed_files
    ((step++))
    
    # 5단계: 임시 파일 정리
    log_info "=== 단계 $step/$total_steps: 임시 파일 정리 ==="
    cleanup_temp_files
    ((step++))
    
    # 설치 완료 메시지
    log_success "=== 모든 설치가 완료되었습니다! ==="
    echo ""
    log_info "📋 설치 완료 요약:"
    log_info "✅ macOS 환경 확인 완료"
    log_info "✅ Homebrew 및 필수 패키지 설치 완료"
    log_info "✅ Docker 서비스 실행 완료"
    log_info "✅ 서버 컨테이너 (autoA-MCP) 실행 완료"
    log_info "✅ 에이전트 패키지 설치 완료"
    log_info "✅ Google Drive 파일 다운로드 완료 (통합 기능 사용)"
    echo ""
    log_info "🔗 서버 접속 정보:"
    log_info "   URL: http://localhost:58787"
    log_info "   포트: 58787"
    echo ""
    log_info "🛠️ 유용한 명령어:"
    log_info "   Docker 컨테이너 상태 확인: docker ps"
    log_info "   컨테이너 로그 확인: docker logs autoA-MCP"
    log_info "   컨테이너 재시작: docker restart autoA-MCP"
    log_info "   컨테이너 중지: docker stop autoA-MCP"
    echo ""
    log_info "📚 추가 도움말:"
    log_info "   README.md 파일을 참조하거나 GitHub Issues를 확인하세요."
    echo ""
    log_success "설치가 성공적으로 완료되었습니다! 🎉"
}

# 스크립트 실행
main "$@" 