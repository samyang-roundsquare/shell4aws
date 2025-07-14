# PCAliveCheck & EdgeNode Installation Guide

This guide provides instructions for installing and configuring PCAliveCheck and EdgeNode on macOS. The packages include scripts for installation, configuration, and uninstallation.

## Prerequisites
- macOS 10.14 or later
- Administrator privileges
- Terminal application
- Stable internet connection
- Node.js 14+ (for EdgeNode)

## System Configuration

Before running the installation scripts, you need to enable the necessary system settings for the service to work properly:

1. **Enable Accessibility Permissions**:
   - Open System Settings > Privacy & Security > Privacy > Accessibility
   - Click the + button and add Terminal or iTerm
   - Ensure the checkbox is checked for the terminal application

2. **Allow Background Processes**:
   - Open System Settings > General > Login Items
   - Ensure PCAliveCheck is allowed to run in the background

## Installation

### One-line Installation
Run the following command in Terminal to install both PCAliveCheck and EdgeNode:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/install.sh)"
```

### Manual Installation
1. Run the configuration script:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/config.sh)"
   ```
2. Download and install PCAliveCheck:
   ```bash
   curl -O https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/pkg/PCAliveCheck-Installer.pkg
   sudo installer -pkg PCAliveCheck-Installer.pkg -target /
   ```
3. Download and install EdgeNode:
   ```bash
   curl -O https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/pkg/EdgeNode-Installer.pkg
   sudo installer -pkg EdgeNode-Installer.pkg -target /
   ```
4. The services will start automatically after installation.

## Script Details

### install.sh
This script handles the installation of both PCAliveCheck and EdgeNode components.

**Features:**
- Runs pre-installation configuration
- Downloads and installs both PCAliveCheck and EdgeNode packages
- Verifies system requirements
- Sets up necessary system configurations
- Starts both services

## 제거(언인스톨) 방법

### uninstall.sh 스크립트 사용법

`uninstall.sh` 스크립트는 PCAliveCheck 또는 EdgeNode를 완전히 삭제할 때 사용합니다. 반드시 **관리자 권한(sudo)** 으로 실행해야 하며, 아래와 같이 패키지 ID를 인자로 전달합니다.

#### 온라인 원라인 실행 (권장)
```bash
# 두 패키지 모두 삭제 (인자 없이 실행)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh)"
```
- 위 명령은 PCAliveCheck와 EdgeNode를 모두 삭제합니다.
- 내부적으로 uninstall.sh가 curl로 두 번 재호출되어 두 패키지가 순차적으로 삭제됩니다.
- 이 방식은 어떤 환경(터미널, 파이프, 임시파일 등)에서도 안전하게 동작합니다.

#### 단일 패키지 삭제 (인자 필요)
- bash -c 방식은 인자 전달이 불가하므로, 단일 패키지 삭제는 아래처럼 사용하세요:
```bash
curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh | bash -s -- ai.hcbu-roundsquare.pcalivecheck
curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh | bash -s -- ai.hcbu-roundsquare.edgenode
```
- `| bash -s -- <패키지ID>` 방식으로 인자를 전달해야 원하는 패키지가 삭제됩니다.
- **인자를 생략하면 PCAliveCheck와 EdgeNode가 모두 삭제**됩니다.

#### 설치된 패키지 ID 확인 방법
```bash
pkgutil --pkgs | grep hcbu-roundsquare
```

### 삭제 동작 상세 설명

- **설치 파일 및 심볼릭 링크 삭제**:
  - 패키지로 설치된 모든 파일과 심볼릭 링크를 자동으로 찾아 삭제합니다.
- **빈 디렉토리 정리**: 
  - 설치 경로 내에 남아있는 빈 디렉토리를 하위부터 역순으로 삭제합니다.
- **EdgeNode 전용 추가 정리**:
  - 모든 사용자(`/Users/*`)의 `.autoA_edge` 디렉토리 및 내부 `node_modules` 삭제
  - EdgeNode 관련 LaunchAgent 중지 및 `yarn stop` 실행, 프로세스 강제 종료
  - `/Users/Shared/.autoA_edge` 디렉토리 삭제
  - EdgeNode 관련 로그(`/tmp/edgenode.*.log`) 삭제
- **PCAliveCheck 전용 추가 정리**:
  - PCAliveCheck 관련 로그(`/tmp/pcalivecheck.*.log`) 삭제
- **설치 기록(Receipt) 삭제**:
  - `sudo pkgutil --forget <패키지ID>` 명령으로 macOS의 패키지 설치 기록도 완전히 삭제합니다.

### 주의사항 및 권장 사항
- 반드시 **sudo**로 실행해야 모든 파일/디렉토리 삭제가 정상적으로 동작합니다.
- EdgeNode 삭제 시, 모든 사용자의 홈 디렉토리 내 `.autoA_edge` 폴더가 삭제되므로, 중요한 데이터가 있다면 미리 백업하세요.
- 삭제 후에도 일부 사용자 데이터나 로그가 남아있을 수 있으니, 필요시 수동으로 확인하세요.
- 삭제 과정에서 오류가 발생해도 대부분 무시하고 계속 진행합니다. (예: 이미 삭제된 파일/디렉토리)

### 예시 출력
```
패키지 아이디: ai.hcbu-roundsquare.edgenode
설치 파일 목록 추출 중...
설치 경로: /
설치 파일 삭제 중...
삭제: /usr/local/bin/edgenode
...
Edge Node 서비스 중지 중...
사용자 user1의 Edge Node 서비스 중지 중...
yarn stop 실행 중: /Users/user1/.autoA_edge
...
삭제: /Users/user1/.autoA_edge
삭제: /Users/Shared/.autoA_edge
삭제: /tmp/edgenode.install.log
...
설치 기록(Receipt) 삭제 중...
패키지 'ai.hcbu-roundsquare.edgenode' 삭제가 완료되었습니다!
```

---

## Troubleshooting

### Checking Logs
- **PCAliveCheck Logs**:
  - System logs: `log show --predicate 'process == "pcAliveCheck"' --last 10m`
  - Application logs: `/tmp/pcalivecheck.out.log`
  - Error logs: `/tmp/pcalivecheck.err.log`

- **EdgeNode Logs**:
  - Application logs: `/tmp/edgenode.out.log`
  - Error logs: `/tmp/edgenode.err.log`
  - Installation logs: `/tmp/edgenode.install.log`

### Common Issues
1. **Permission Errors**:
   - Run `chmod +x` on the script files before execution
   - Ensure you have administrator privileges
   - Check file ownership in `~/.autoA_edge` for EdgeNode

2. **Service Not Running**:
   - For PCAliveCheck:
     - Check status: `launchctl list | grep pcalivecheck`
     - Restart: `launchctl load ~/Library/LaunchAgents/ai.hcbu-roundsquare.pcalivecheck.plist`
   - For EdgeNode:
     - Check status: `ps aux | grep node`
     - Restart: `cd ~/.autoA_edge && yarn start`

3. **Accessibility Permissions**:
   - Go to System Settings > Privacy & Security > Privacy > Accessibility
   - Ensure your terminal application has permission
   - For EdgeNode, also check Full Disk Access permissions

## License and Support
- This software is provided by HCBU.
- Unauthorized copying and distribution is prohibited.
- For support or feature requests, please contact the development team.

---

## Version Information
- PCAliveCheck: 1.0.0
- EdgeNode: 1.0.0
- Last Updated: 2025-07-13