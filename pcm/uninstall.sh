#!/bin/bash

# 온라인 원라인 제거(언인스톨) 방법:
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh)"
#
# 위 명령을 터미널에 입력하면 최신 uninstall.sh가 자동으로 다운로드되어 실행됩니다.
# (인자 없이 실행 시 PCAliveCheck와 EdgeNode가 모두 삭제됩니다)
#
# 단일 패키지만 삭제하려면 아래처럼 사용하세요:
#   curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh | bash -s -- ai.hcbu-roundsquare.pcalivecheck
#   curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh | bash -s -- ai.hcbu-roundsquare.edgenode

# 사용법: sudo ./uninstall.sh [<package-id>]
# 예시 1 (PCAliveCheck): sudo ./uninstall.sh ai.hcbu-roundsquare.pcalivecheck
# 예시 2 (EdgeNode): sudo ./uninstall.sh ai.hcbu-roundsquare.edgenode
# 패키지 ID를 생략하면 PCAliveCheck 기본값(ai.hcbu-roundsquare.pcalivecheck) 사용
# 패키지 파일은 각 프로젝트의 packages/pkg/ 디렉토리에 생성됩니다.
# 소스 파일은 각 프로젝트의 src/ 디렉토리에 있습니다.

# 기본 패키지 ID 설정 (PCAliveCheck)
if [ -z "$1" ]; then
  echo "패키지 ID가 지정되지 않아 PCAliveCheck와 EdgeNode를 모두 삭제합니다."
  curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh | bash -s -- ai.hcbu-roundsquare.pcalivecheck
  curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh | bash -s -- ai.hcbu-roundsquare.edgenode
  exit 0
fi
PKGID="$1"

if [ -z "$PKGID" ]; then
  echo "사용법: sudo $0 [<package-id>]"
  echo "설치된 패키지 목록은:"
  echo "  - PCAliveCheck: pkgutil --pkgs | grep hcbu-roundsquare.pcalivecheck"
  echo "  - EdgeNode: pkgutil --pkgs | grep hcbu-roundsquare.edgenode"
  echo "패키지 파일은 각 프로젝트의 packages/pkg/ 디렉토리에 있습니다."
  echo "소스 파일은 각 프로젝트의 src/ 디렉토리에 있습니다."
  exit 1
fi

echo "패키지 아이디: $PKGID"

# 패키지가 실제로 설치되어 있는지 확인
if ! pkgutil --pkg-info "$PKGID" >/dev/null 2>&1; then
  echo "오류: 패키지 '$PKGID'가 설치되어 있지 않습니다."
  # exit 1
fi

# 1. 설치 파일 목록 추출
echo "설치 파일 목록 추출 중..."
FILE_LIST=$(pkgutil --only-files --files "$PKGID" 2>/dev/null)
INSTALL_PATH=$(pkgutil --pkg-info "$PKGID" | awk '/^location:/ {print $2}')

if [ -z "$INSTALL_PATH" ]; then
  INSTALL_PATH="/"
fi

echo "설치 경로: $INSTALL_PATH"

# 2. 파일 삭제
echo "설치 파일 삭제 중..."
if [ -n "$FILE_LIST" ]; then
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      TARGET="$INSTALL_PATH/$file"
      if [ -f "$TARGET" ]; then
        echo "삭제: $TARGET"
        sudo rm -f "$TARGET"
      elif [ -L "$TARGET" ]; then
        echo "심볼릭 링크 삭제: $TARGET"
        sudo rm -f "$TARGET"
      fi
    fi
  done <<< "$FILE_LIST"
else
  echo "삭제할 파일이 없습니다."
fi

if [[ "$PKGID" == *"edgenode"* ]]; then
  echo "Edge Node 제거가 완료되었습니다."
else
  echo "PCAliveCheck 제거가 완료되었습니다."
fi
echo "모든 관련 파일과 디렉토리가 삭제되었습니다."

# 3. 디렉토리 삭제 (하위부터 역순으로)
echo "빈 디렉토리 삭제 중..."
DIR_LIST=$(pkgutil --only-dirs --files "$PKGID" 2>/dev/null | tail -r)
if [ -n "$DIR_LIST" ]; then
  while IFS= read -r dir; do
    if [ -n "$dir" ]; then
      TARGET="$INSTALL_PATH/$dir"
      if [ -d "$TARGET" ]; then
        if [ -z "$(ls -A "$TARGET" 2>/dev/null)" ]; then
          echo "빈 디렉토리 삭제: $TARGET"
          sudo rmdir "$TARGET" 2>/dev/null || true
        else
          echo "비어있지 않은 디렉토리 (유지): $TARGET"
        fi
      fi
    fi
  done <<< "$DIR_LIST"
else
  echo "삭제할 디렉토리가 없습니다."
fi

# 4. Edge Node 관련 서비스 중지 및 정리 (EdgeNode 전용)
if [[ "$PKGID" == *"edgenode"* ]]; then
  # Edge Node 서비스 중지 (모든 사용자)
  echo "Edge Node 서비스 중지 중..."
  for user_home in /Users/*; do
    if [ -d "$user_home" ] && [ -d "$user_home/.autoA_edge" ]; then
      user_name=$(basename "$user_home")
      echo "사용자 $user_name의 Edge Node 서비스 중지 중..."
      
      # LaunchAgent 언로드
      launchctl unload "/Library/LaunchAgents/ai.hcbu-roundsquare.edgenode.plist" 2>/dev/null || true
      
      # yarn stop 실행
      cd "$user_home/.autoA_edge" 2>/dev/null
      if [ $? -eq 0 ] && [ -f "package.json" ]; then
        echo "yarn stop 실행 중: $user_home/.autoA_edge"
        # 환경 변수 설정
        export HOME="$user_home"
        export USER="$user_name"
        export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
        
        # yarn stop 실행
        sudo -u "$user_name" -E yarn stop 2>/dev/null || true
        
        # 추가로 프로세스 확인 및 강제 종료
        if [ -f ".edge_node.pid" ]; then
          PID=$(cat .edge_node.pid)
          if ps -p "$PID" > /dev/null 2>&1; then
            echo "강제 종료 중 (PID: $PID)"
            kill -9 "$PID" 2>/dev/null || true
          fi
          rm -f .edge_node.pid
        fi
      fi
    fi
  done

  # .autoA_edge 디렉토리 완전 삭제 (모든 사용자)
  echo ".autoA_edge 디렉토리 삭제 중..."
  for user_home in /Users/*; do
    if [ -d "$user_home" ] && [ -d "$user_home/.autoA_edge" ]; then
      echo "삭제: $user_home/.autoA_edge"
      sudo rm -rf "$user_home/.autoA_edge"
    fi
  done

  # Shared 디렉토리도 삭제
  if [ -d "/Users/Shared/.autoA_edge" ]; then
    echo "삭제: /Users/Shared/.autoA_edge"
    sudo rm -rf "/Users/Shared/.autoA_edge"
  fi

  # node_modules 삭제 (모든 사용자)
  for user_home in /Users/*; do
    if [ -d "$user_home/.autoA_edge/node_modules" ]; then
      echo "삭제: $user_home/.autoA_edge/node_modules"
      sudo rm -rf "$user_home/.autoA_edge/node_modules"
    fi
  done

  # EdgeNode 관련 로그 파일 삭제
  for log_file in edgenode.install.log edgenode.err.log edgenode.out.log; do
    if [ -f "/tmp/$log_file" ]; then
      echo "삭제: /tmp/$log_file"
      sudo rm -f "/tmp/$log_file"
    fi
  done
else
  # PCAliveCheck 관련 로그 파일 삭제
  for log_file in pcalivecheck.install.log pcalivecheck.err.log pcalivecheck.out.log; do
    if [ -f "/tmp/$log_file" ]; then
      echo "삭제: /tmp/$log_file"
      sudo rm -f "/tmp/$log_file"
    fi
  done
  # .autoA_env 파일 삭제 (주석 처리됨)
  # if [ -f "$HOME/.autoA_env" ]; then
  #   echo "삭제: $HOME/.autoA_env"
  #   rm -f "$HOME/.autoA_env"
  # fi
fi

# 5. Receipt 삭제
echo "설치 기록(Receipt) 삭제 중..."
if sudo pkgutil --forget "$PKGID"; then
  echo "패키지 '$PKGID' 삭제가 완료되었습니다!"
else
  echo "오류: Receipt 삭제에 실패했습니다."
  # exit 1
fi