## 📋 개요
이 프로젝트는 AWS EC2 환경에서 필요한 설정과 도구들을 자동화하여 설치하고 구성하는 스크립트들을 제공합니다.

## 🍎 macOS 설치 가이드

### 빠른 시작
macOS 사용자는 다음 명령어로 자동 설치를 진행할 수 있습니다:

#### 방법 1: curl로 직접 실행 (간단하지만 제한적)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/install.sh)"
```

#### 방법 2: 로컬 다운로드 후 실행 (권장)
```bash
# 스크립트 다운로드
curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/install.sh -o install.sh

# 실행 권한 부여
chmod +x install.sh

# 스크립트 실행
./install.sh
```

**💡 실행 방법별 차이점:**
- **curl 직접 실행**: 간단하지만 브라우저 자동 실행 및 수동 다운로드 가이드 제한
- **로컬 실행**: 모든 기능 정상 작동, 브라우저 자동 실행, 상세한 수동 다운로드 가이드

**💡 통합 버전의 장점:**
- 단일 파일로 모든 기능 포함
- `curl`로 직접 실행 가능
- Google Drive 다운로드 문제 자동 해결
- 외부 의존성 없음
- 기존 파일 자동 재사용 (다운로드 스킵)

### 수동 설치
1. 저장소를 클론합니다:
```bash
git clone https://github.com/samyang-roundsquare/shell4aws.git
cd shell4aws/autoA
```

2. 설치 스크립트를 실행합니다:
```bash
./install.sh
```

## 🔧 설치 과정

### 1단계: macOS 환경 확인
- macOS 버전 및 아키텍처(Intel/Apple Silicon) 확인
- 호환성 검증

### 2단계: 기본 도구 설치
- **Homebrew**: macOS 패키지 관리자
- **Docker Desktop**: 컨테이너 플랫폼
- **Docker Compose**: 다중 컨테이너 관리
- **cliclick**: macOS 자동화 도구

### 3단계: 서버 구성
- Docker 서비스 상태 확인 및 실행
- 기존 `server_image.tar.gz` 파일 확인 및 재사용
- 서버 이미지 다운로드 (기존 파일이 없을 경우)
- Docker 컨테이너 실행 (`autoA-MCP`)
- 서비스 상태 확인 (포트 58787)

### 4단계: 에이전트 설치
- 기존 `agent.pkg` 파일 확인 및 재사용
- 에이전트 패키지 다운로드 (기존 파일이 없을 경우)
- 관리자 권한으로 패키지 설치
- 설치된 파일 목록 확인

**💡 기존 파일 재사용 기능:**
- 현재 디렉토리에 `server_image.tar.gz` 또는 `agent.pkg` 파일이 있으면 다운로드를 스킵합니다
- 파일 크기와 유효성을 검사하여 손상된 파일은 자동으로 다시 다운로드합니다
- HTML 페이지로 다운로드된 경우 자동으로 감지하고 재다운로드합니다

### 5단계: 정리
- 임시 파일 및 다운로드 파일 정리

## 🚀 설치 후 확인사항

### 서버 상태 확인
```bash
# Docker 컨테이너 상태 확인
docker ps

# 서버 로그 확인
docker logs autoA-MCP

# 웹 브라우저에서 접속
open http://localhost:58787
```

### 유용한 명령어
```bash
# 컨테이너 재시작
docker restart autoA-MCP

# 컨테이너 중지
docker stop autoA-MCP

# 컨테이너 제거
docker rm -f autoA-MCP
```

## ⚠️ 주의사항

### 시스템 요구사항
- macOS 10.15 (Catalina) 이상
- 최소 4GB RAM
- 최소 10GB 사용 가능한 디스크 공간

### 권한 요구사항
- 관리자 권한 (패키지 설치 시)
- Docker Desktop 실행 권한

### 네트워크 요구사항
- 인터넷 연결 (Homebrew, Docker, 파일 다운로드)
- Google Drive 접근 권한
- 큰 파일 다운로드를 위한 안정적인 네트워크 연결

## 🛠️ 문제 해결

### 일반적인 문제들

#### Docker Desktop이 시작되지 않는 경우
```bash
# Docker Desktop 수동 실행
open -a Docker

# 또는 Applications 폴더에서 Docker 앱 실행
```

#### 권한 오류가 발생하는 경우
```bash
# 스크립트에 실행 권한 부여
chmod +x macos-install.sh

# 관리자 권한으로 실행
sudo ./macos-install.sh
```

#### 네트워크 오류가 발생하는 경우
- 방화벽 설정 확인
- 프록시 설정 확인
- DNS 설정 확인

#### Google Drive 파일 다운로드 실패
Google Drive는 큰 파일의 직접 다운로드를 제한할 수 있습니다. 다음과 같은 방법을 시도해보세요:

**자동 해결 방법:**
- 스크립트가 자동으로 여러 다운로드 방법을 시도합니다
- curl, wget, gdown, rclone 등 다양한 도구를 사용합니다

**수동 다운로드 방법:**
1. 제공된 Google Drive URL로 이동
2. '다운로드' 버튼을 클릭
3. 파일을 `autoA` 디렉토리에 저장
4. 스크립트를 다시 실행

**💡 curl 실행 시 주의사항:**
- curl로 직접 실행하면 브라우저 자동 실행이 제한됩니다
- 수동 다운로드 가이드가 제한적으로 작동할 수 있습니다
- 로컬에서 스크립트를 실행하면 모든 기능이 정상 작동합니다

**파일 위치:**
- 서버 이미지: `server_image.tar.gz`
- 에이전트 패키지: `agent.pkg`

**다운로드 URL:**
- 서버 이미지: `https://drive.google.com/file/d/1PhD7xtKZo5CmOkcIARM7V2BkZzeIr4H3/view?usp=sharing`
- 에이전트 패키지: `https://drive.google.com/file/d/1cfMLZE5tto4IHQd4VmIfv0a2nR02MTwW/view?usp=sharing`

### 로그 확인
스크립트 실행 중 오류가 발생하면 다음을 확인하세요:
```bash
# Docker 로그
docker logs autoA-MCP

# 시스템 로그
sudo log show --predicate 'process == "installer"' --last 1h
```

## 📁 프로젝트 구조
```
shell4aws/autoA/
├── install.sh                # macOS 설치 스크립트 (통합 버전)
└── README.md                 # 프로젝트 문서
```

### 통합된 설치 스크립트 기능
`install.sh`는 모든 기능이 통합된 완전한 설치 스크립트입니다:

**Google Drive 다운로드 기능:**
1. **curl** - 확인 토큰 처리 포함
2. **wget** - 확인 토큰 처리 포함  
3. **gdown** - Python 패키지 (자동 설치)
4. **rclone** - 고급 방법 (자동 설치)
5. **수동 다운로드** - 모든 자동 방법 실패 시

**주요 기능:**
- Google Drive의 직접 액세스 제한 우회
- 파일 유효성 검사
- 자동 오류 복구
- 상세한 사용자 안내
- 단일 파일로 모든 기능 통합

## 🤝 기여하기
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스
이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 지원
문제가 발생하거나 질문이 있으시면:
- GitHub Issues를 통해 문의
- 이메일: [your-email@example.com]

---
**참고**: 이 스크립트는 macOS 환경에서 테스트되었습니다. 다른 운영체제에서는 작동하지 않을 수 있습니다.