#!/bin/bash

# shell4aws - macOS 설치 스크립트
# AWS EC2 설정을 위한 macOS 환경 구성
# 작성자: shell4aws 팀
# 버전: 1.0.0

set -e  # 오류 발생 시 스크립트 중단

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

# 색상 정의 (터미널 출력용)
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
    
    # Google Drive 파일 URL (실제 파일 ID로 교체 필요)
    SERVER_FILE_URL="https://drive.google.com/file/d/1PhD7xtKZo5CmOkcIARM7V2BkZzeIr4H3/view?usp=drive_link"
    log_info "서버 이미지 파일 다운로드 중..."
    
    # 다운로드 헬퍼 스크립트 사용
    if [[ -f "../download-helper.sh" ]]; then
        log_info "다운로드 헬퍼 스크립트를 사용합니다..."
        if ../download-helper.sh "$SERVER_FILE_URL" "server_image.tar.gz"; then
            log_success "서버 이미지 다운로드 완료"
        else
            log_error "서버 이미지 다운로드 실패"
            log_info "수동으로 다운로드 후 압축 해제해주세요."
            exit 1
        fi
    else
        # 기본 curl 다운로드 시도
        log_info "기본 curl 다운로드를 시도합니다..."
        if curl -L -o server_image.tar.gz "$SERVER_FILE_URL"; then
            log_success "서버 이미지 다운로드 완료"
        else
            log_error "서버 이미지 다운로드 실패"
            log_info "수동으로 다운로드 후 압축 해제해주세요."
            exit 1
        fi
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
    
    # Google Drive 파일 URL (실제 파일 ID로 교체 필요)
    AGENT_FILE_URL="https://drive.google.com/file/d/1cfMLZE5tto4IHQd4VmIfv0a2nR02MTwW/view?usp=sharing"
    log_info "에이전트 패키지 다운로드 중..."
    
    # 다운로드 헬퍼 스크립트 사용
    if [[ -f "../download-helper.sh" ]]; then
        log_info "다운로드 헬퍼 스크립트를 사용합니다..."
        if ../download-helper.sh "$AGENT_FILE_URL" "agent.pkg"; then
            log_success "에이전트 패키지 다운로드 완료"
        else
            log_error "에이전트 패키지 다운로드 실패"
            log_info "수동으로 다운로드 후 설치해주세요."
            exit 1
        fi
    else
        # 기본 curl 다운로드 시도
        log_info "기본 curl 다운로드를 시도합니다..."
        if curl -L -o agent.pkg "$AGENT_FILE_URL"; then
            log_success "에이전트 패키지 다운로드 완료"
        else
            log_error "에이전트 패키지 다운로드 실패"
            log_info "수동으로 다운로드 후 설치해주세요."
            exit 1
        fi
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
    log_info "=== shell4aws macOS 설치 시작 ==="
    log_info "설치 시간: $(date)"
    log_info "현재 디렉토리: $(pwd)"
    
    # 설치 전 확인사항
    log_info "설치 전 확인사항:"
    log_info "- 인터넷 연결 상태 확인"
    log_info "- 관리자 권한 필요 (패키지 설치 시)"
    log_info "- 최소 10GB 디스크 공간 필요"
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