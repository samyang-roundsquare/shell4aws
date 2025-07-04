#!/bin/bash

# Google Drive 파일 다운로드 헬퍼 스크립트
# 다양한 방법으로 Google Drive 파일을 다운로드합니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 방법 5: 수동 다운로드 안내 (개선된 버전)
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
    echo ""
    
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
        log_success "파일이 확인되었습니다! 크기: $file_size"
        return 0
    else
        log_error "파일을 찾을 수 없습니다: $output_file"
        return 1
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
    local methods=("download_with_curl" "download_with_wget" "download_with_gdown" "download_with_rclone")
    
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
    manual_download_guide "$url" "$output_file" "$file_id"
}

# 사용법 출력
usage() {
    echo "사용법: $0 <Google_Drive_URL> <output_filename>"
    echo ""
    echo "예시:"
    echo "  $0 'https://drive.google.com/file/d/1PhD7xtKZo5CmOkcIARM7V2BkZzeIr4H3/view?usp=sharing' 'server_image.tar.gz'"
    echo "  $0 'https://drive.google.com/file/d/1cfMLZE5tto4IHQd4VmIfv0a2nR02MTwW/view?usp=sharing' 'agent.pkg'"
    echo ""
    echo "이 스크립트는 다양한 방법으로 Google Drive 파일을 다운로드합니다:"
    echo "1. curl (확인 토큰 처리 포함)"
    echo "2. wget (확인 토큰 처리 포함)"
    echo "3. gdown (Python 패키지, 자동 설치)"
    echo "4. rclone (고급 방법, 자동 설치)"
    echo "5. 수동 다운로드 안내 (모든 자동 방법 실패 시)"
    echo ""
    echo "💡 Google Drive 파일 다운로드 문제 해결:"
    echo "   - 큰 파일의 경우 Google Drive에서 직접 다운로드가 제한될 수 있습니다"
    echo "   - 이 스크립트는 다양한 방법을 시도하여 최대한 자동화합니다"
    echo "   - 모든 방법이 실패하면 수동 다운로드 가이드를 제공합니다"
}

# 메인 실행
main() {
    if [[ $# -ne 2 ]]; then
        usage
        exit 1
    fi
    
    local url="$1"
    local output_file="$2"
    
    # URL 유효성 검사
    if [[ ! "$url" =~ google\.com ]]; then
        log_error "Google Drive URL이 아닙니다: $url"
        exit 1
    fi
    
    # 다운로드 실행
    if download_google_drive_file "$url" "$output_file"; then
        log_success "다운로드가 성공적으로 완료되었습니다!"
        exit 0
    else
        log_error "다운로드에 실패했습니다."
        exit 1
    fi
}

# 스크립트 실행
main "$@" 