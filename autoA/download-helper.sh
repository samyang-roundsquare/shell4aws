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

# 방법 1: curl을 사용한 직접 다운로드
download_with_curl() {
    local file_id="$1"
    local output_file="$2"
    local url="https://drive.google.com/uc?export=download&id=$file_id"
    
    log_info "curl을 사용하여 다운로드 시도 중..."
    
    if curl -L -o "$output_file" "$url"; then
        log_success "curl 다운로드 성공"
        return 0
    else
        log_warning "curl 다운로드 실패"
        return 1
    fi
}

# 방법 2: wget을 사용한 다운로드
download_with_wget() {
    local file_id="$1"
    local output_file="$2"
    local url="https://drive.google.com/uc?export=download&id=$file_id"
    
    log_info "wget을 사용하여 다운로드 시도 중..."
    
    if command -v wget &> /dev/null; then
        if wget -O "$output_file" "$url"; then
            log_success "wget 다운로드 성공"
            return 0
        else
            log_warning "wget 다운로드 실패"
            return 1
        fi
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

# 방법 4: 수동 다운로드 안내
manual_download_guide() {
    local url="$1"
    local output_file="$2"
    
    log_warning "자동 다운로드에 실패했습니다. 수동 다운로드를 진행해주세요."
    echo ""
    echo "수동 다운로드 방법:"
    echo "1. 다음 URL로 이동: $url"
    echo "2. 파일을 다운로드하여 '$output_file'로 저장"
    echo "3. 다운로드 완료 후 스크립트를 다시 실행하세요"
    echo ""
    
    # 브라우저에서 URL 열기
    if command -v open &> /dev/null; then
        log_info "브라우저에서 다운로드 페이지를 엽니다..."
        open "$url"
    fi
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
    
    # 다양한 다운로드 방법 시도
    local methods=("download_with_curl" "download_with_wget" "download_with_gdown")
    
    for method in "${methods[@]}"; do
        if $method "$file_id" "$output_file"; then
            # 파일 크기 확인
            if [[ -f "$output_file" && -s "$output_file" ]]; then
                local file_size=$(du -h "$output_file" | cut -f1)
                log_success "다운로드 완료! 파일 크기: $file_size"
                return 0
            else
                log_warning "다운로드된 파일이 비어있거나 손상되었습니다"
                rm -f "$output_file"
            fi
        fi
    done
    
    # 모든 자동 방법이 실패한 경우 수동 다운로드 안내
    manual_download_guide "$url" "$output_file"
    return 1
}

# 사용법 출력
usage() {
    echo "사용법: $0 <Google_Drive_URL> <output_filename>"
    echo ""
    echo "예시:"
    echo "  $0 'https://drive.google.com/file/d/1ABC123/view' 'server_image.tar.gz'"
    echo "  $0 'https://drive.google.com/file/d/1XYZ789/view' 'agent.pkg'"
    echo ""
    echo "이 스크립트는 다양한 방법으로 Google Drive 파일을 다운로드합니다:"
    echo "1. curl (기본)"
    echo "2. wget (가능한 경우)"
    echo "3. gdown (Python 패키지, 자동 설치)"
    echo "4. 수동 다운로드 안내 (모든 자동 방법 실패 시)"
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