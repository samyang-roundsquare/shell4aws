#!/bin/bash

# 사용법: sudo ./uninstall.sh [<package-id>]
# 예시: sudo ./uninstall.sh ai.hcbu-roundsquare.pcalivecheck
# 패키지 ID를 생략하면 AppleScript 기본값(ai.hcbu-roundsquare.pcalivecheck) 사용
# 패키지 파일은 AppleScript/packages/pkg/에 생성됩니다.
# 소스 파일은 AppleScript/src/에 있습니다.

PKGID="${1:-ai.hcbu-roundsquare.pcalivecheck}"

if [ -z "$PKGID" ]; then
  echo "사용법: sudo $0 [<package-id>]"
  echo "설치된 패키지 목록은: pkgutil --pkgs | grep hcbu-roundsquare.pcalivecheck"
  echo "패키지 파일은 PCManager/packages/pkg/에 있습니다."
  echo "소스 파일은 PCManager/src/에 있습니다."
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

# 4. log, .env 파일 삭제
sudo rm -f /tmp/ai.hcbu-roundsquare.pcalivecheck.err.log
echo "삭제: /tmp/ai.hcbu-roundsquare.pcalivecheck.err.log"
sudo rm -f /tmp/ai.hcbu-roundsquare.pcalivecheck.out.log
echo "삭제: /tmp/ai.hcbu-roundsquare.pcalivecheck.out.log"
# sudo rm -f $HOME/.autoA_env
# echo "삭제: $HOME/.autoA_env"

# 5. Receipt 삭제
echo "설치 기록(Receipt) 삭제 중..."
if sudo pkgutil --forget "$PKGID"; then
  echo "패키지 '$PKGID' 삭제가 완료되었습니다!"
else
  echo "오류: Receipt 삭제에 실패했습니다."
  # exit 1
fi