#!/bin/bash
set -euo pipefail

# =========================================
# Wuthering Waves 資源外移選單式腳本
# =========================================

DEFAULT_VOLUME_NAME="T7"
DEFAULT_EXTERNAL_ROOT="WuwaData"
DEFAULT_APP_CONTAINER_ID="com.kurogame.wutheringwaves.global"

VERSION=""
VOLUME_NAME="${DEFAULT_VOLUME_NAME}"
EXTERNAL_ROOT="${DEFAULT_EXTERNAL_ROOT}"
APP_CONTAINER_ID="${DEFAULT_APP_CONTAINER_ID}"

HOME_DIR="$HOME"

log() {
  echo
  echo "==> $1"
}

ok() {
  echo "✅ $1"
}

warn() {
  echo "⚠️  $1"
}

err() {
  echo "❌ $1"
}

pause() {
  echo
  read -r -p "按 Enter 繼續..."
}

prompt_with_default() {
  local text="$1"
  local default="$2"
  local input
  read -r -p "${text} [預設: ${default}]: " input
  if [[ -z "${input}" ]]; then
    echo "${default}"
  else
    echo "${input}"
  fi
}

prompt_required() {
  local text="$1"
  local input
  while true; do
    read -r -p "${text}: " input
    if [[ -n "${input}" ]]; then
      echo "${input}"
      return
    fi
    echo "這個欄位不能空白。"
  done
}

confirm_yes_no() {
  local text="$1"
  local input
  read -r -p "${text} [y/N]: " input
  case "${input}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

rebuild_paths() {
  EXTERNAL_BASE="/Volumes/${VOLUME_NAME}/${EXTERNAL_ROOT}/Resources"
  EXTERNAL_TARGET="${EXTERNAL_BASE}/${VERSION}"

  SOURCE1_BASE="${HOME_DIR}/Library/Containers/${APP_CONTAINER_ID}/Data/Library/Client/Saved/Resources"
  SOURCE2_BASE="${HOME_DIR}/Library/Client/Saved/Resources"

  SOURCE1="${SOURCE1_BASE}/${VERSION}"
  SOURCE2="${SOURCE2_BASE}/${VERSION}"
}

show_config() {
  echo
  echo "========== 目前設定 =========="
  echo "版本號            : ${VERSION:-<未設定>}"
  echo "外接硬碟名稱      : ${VOLUME_NAME}"
  echo "外接資料夾        : ${EXTERNAL_ROOT}"
  echo "App container ID  : ${APP_CONTAINER_ID}"
  if [[ -n "${VERSION}" ]]; then
    echo
    echo "外接目標          : ${EXTERNAL_TARGET}"
    echo "入口 1            : ${SOURCE1}"
    echo "入口 2            : ${SOURCE2}"
  fi
  echo "=============================="
}

setup_config() {
  echo
  echo "請輸入設定"
  VERSION="$(prompt_required "版本號（例如 3.2.0）")"
  VOLUME_NAME="$(prompt_with_default "外接硬碟名稱" "${VOLUME_NAME}")"
  EXTERNAL_ROOT="$(prompt_with_default "外接資料夾名稱" "${EXTERNAL_ROOT}")"
  APP_CONTAINER_ID="$(prompt_with_default "App container ID" "${APP_CONTAINER_ID}")"
  rebuild_paths
  ok "設定完成"
}

ensure_config_ready() {
  if [[ -z "${VERSION}" ]]; then
    warn "目前還沒設定版本號。"
    setup_config
  else
    rebuild_paths
  fi
}

check_volume() {
  if [[ ! -d "/Volumes/${VOLUME_NAME}" ]]; then
    err "找不到外接硬碟：/Volumes/${VOLUME_NAME}"
    return 1
  fi
  ok "已找到外接硬碟：/Volumes/${VOLUME_NAME}"
}

ensure_dirs() {
  mkdir -p "${EXTERNAL_TARGET}"
  mkdir -p "${SOURCE1_BASE}"
  mkdir -p "${SOURCE2_BASE}"
}

sync_if_real_dir() {
  local src="$1"
  local label="$2"

  if [[ -L "${src}" ]]; then
    warn "${label} 已經是 symlink，略過 rsync"
    return
  fi

  if [[ -d "${src}" ]]; then
    log "同步 ${label} 到外接硬碟"
    rsync -avh "${src}/" "${EXTERNAL_TARGET}/"
    ok "${label} 已同步到 ${EXTERNAL_TARGET}"
  else
    warn "${label} 不存在，略過 rsync"
  fi
}

replace_with_symlink() {
  local src="$1"
  local label="$2"

  if [[ -L "${src}" ]]; then
    local current_target
    current_target="$(readlink "${src}")" || true

    if [[ "${current_target}" == "${EXTERNAL_TARGET}" ]]; then
      ok "${label} 已正確指向 ${EXTERNAL_TARGET}"
      return
    else
      warn "${label} 是舊 symlink，將重建"
      rm -f "${src}"
    fi
  elif [[ -e "${src}" ]]; then
    warn "${label} 是實體資料夾或檔案，將移除後改成 symlink"
    rm -rf "${src}"
  fi

  ln -s "${EXTERNAL_TARGET}" "${src}"
  ok "${label} 已建立 symlink"
}

verify_one() {
  local src="$1"
  local label="$2"

  if [[ -L "${src}" ]]; then
    local target
    target="$(readlink "${src}")" || true
    if [[ "${target}" == "${EXTERNAL_TARGET}" ]]; then
      ok "${label} 正常 -> ${target}"
    else
      warn "${label} 是 symlink，但指向 ${target}"
    fi
  elif [[ -e "${src}" ]]; then
    warn "${label} 存在，但不是 symlink"
  else
    warn "${label} 不存在"
  fi
}

create_or_update_symlink() {
  ensure_config_ready
  show_config
  echo
  echo "執行前請確認："
  echo "- 遊戲已完全關閉"
  echo "- Launcher 已完全關閉"
  echo "- App Store 已完全關閉"
  echo

  if ! confirm_yes_no "開始建立 / 更新 symlink"; then
    echo "已取消。"
    return
  fi

  check_volume || return

  log "建立必要資料夾"
  ensure_dirs
  ok "外接目標資料夾已準備完成"

  sync_if_real_dir "${SOURCE1}" "Container 路徑"
  sync_if_real_dir "${SOURCE2}" "使用者 Library 路徑"

  log "建立 symlink"
  replace_with_symlink "${SOURCE1}" "Container 路徑"
  replace_with_symlink "${SOURCE2}" "使用者 Library 路徑"

  log "驗證結果"
  verify_one "${SOURCE1}" "Container 路徑"
  verify_one "${SOURCE2}" "使用者 Library 路徑"

  echo
  ok "完成。現在可以開遊戲測試。"
}

show_one_status() {
  local path="$1"
  local label="$2"

  echo
  echo "[${label}]"
  echo "路徑：${path}"

  if [[ -L "${path}" ]]; then
    local target
    target="$(readlink "${path}")" || true
    echo "類型：symlink"
    echo "指向：${target}"
  elif [[ -d "${path}" ]]; then
    echo "類型：實體資料夾"
  elif [[ -e "${path}" ]]; then
    echo "類型：其他檔案"
  else
    echo "狀態：不存在"
  fi
}

check_status() {
  ensure_config_ready
  show_config
  echo

  if [[ -d "${EXTERNAL_TARGET}" ]]; then
    ok "外接目標存在：${EXTERNAL_TARGET}"
  else
    warn "外接目標不存在：${EXTERNAL_TARGET}"
  fi

  show_one_status "${SOURCE1}" "Container 路徑"
  show_one_status "${SOURCE2}" "使用者 Library 路徑"

  echo
  echo "你也可以手動執行："
  echo "ls -ld \"${SOURCE1}\""
  echo "ls -ld \"${SOURCE2}\""
}

remove_one_symlink() {
  local src="$1"
  local label="$2"
  local parent_dir
  parent_dir="$(dirname "${src}")"

  mkdir -p "${parent_dir}"

  if [[ -L "${src}" ]]; then
    local target
    target="$(readlink "${src}")" || true
    rm -f "${src}"
    mkdir -p "${src}"
    ok "${label} 已移除 symlink，並重建空資料夾"
    echo "   原本指向：${target}"
  elif [[ -d "${src}" ]]; then
    warn "${label} 已經是實體資料夾，未變更"
  elif [[ -e "${src}" ]]; then
    warn "${label} 是其他檔案，未變更"
  else
    mkdir -p "${src}"
    ok "${label} 原本不存在，已建立空資料夾"
  fi
}

remove_symlink_only() {
  ensure_config_ready
  show_config
  echo
  echo "這個動作會："
  echo "- 移除兩個入口的 symlink"
  echo "- 在原位置重建空資料夾"
  echo "- 不會刪除外接硬碟上的資料"
  echo

  if ! confirm_yes_no "確定要移除 symlink"; then
    echo "已取消。"
    return
  fi

  remove_one_symlink "${SOURCE1}" "Container 路徑"
  remove_one_symlink "${SOURCE2}" "使用者 Library 路徑"

  echo
  ok "symlink 已移除。"
}

menu() {
  clear
  echo "========================================="
  echo " Wuthering Waves 資源外移選單式腳本"
  echo "========================================="
  echo "1) 建立 / 更新 symlink"
  echo "2) 檢查目前狀態"
  echo "3) 移除 symlink（不刪外接資料）"
  echo "4) 重新設定版本號與路徑"
  echo "5) 顯示目前設定"
  echo "6) 離開"
  echo "========================================="
}

main() {
  rebuild_paths

  while true; do
    menu
    read -r -p "請選擇功能 [1-6]: " choice

    case "${choice}" in
      1)
        create_or_update_symlink
        pause
        ;;
      2)
        check_status
        pause
        ;;
      3)
        remove_symlink_only
        pause
        ;;
      4)
        setup_config
        pause
        ;;
      5)
        ensure_config_ready
        show_config
        pause
        ;;
      6)
        echo "已離開。"
        exit 0
        ;;
      *)
        echo "無效選項，請輸入 1 到 6。"
        pause
        ;;
    esac
  done
}

main