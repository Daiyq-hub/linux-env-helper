#!/usr/bin/env bash
#
# LinuxEnv Helper - update.sh (更新脚本)
# License: Apache License 2.0

# ═══════════════════════════════════════════════════════════════
# 更新脚本到最新版
#  - Git 安装：git pull 快速更新，失败可强制同步
#  - 非 Git 安装：从 GitHub 下载最新压缩包覆盖
# ═══════════════════════════════════════════════════════════════

config_update() {
    show_section "更新脚本"
    update_script
    echo ""
    pause
}

update_script() {
    local mode="${1:-interactive}"   # interactive | auto
    local repo_url="https://github.com/Daiyq-hub/linux-env-helper.git"
    local is_git=false
    local branch="main"

    if [[ -d "$SCRIPT_DIR/.git" ]] && command_exists git; then
        is_git=true
        branch=$(git -c safe.directory="*" -C "$SCRIPT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\r' || echo main)
        [[ -z "$branch" || "$branch" == "HEAD" ]] && branch="main"
        local origin_url
        origin_url=$(git -c safe.directory="*" -C "$SCRIPT_DIR" remote get-url origin 2>/dev/null || true)
        [[ -n "$origin_url" ]] && repo_url="$origin_url"
    fi

    local latest=""
    latest=$(get_remote_version)
    local need_update=false

    msg_info "当前版本: ${BRIGHT_WHITE}${SCRIPT_VERSION}${NC}"
    if [[ -n "$latest" ]]; then
        msg_info "最新版本: ${BRIGHT_WHITE}${latest}${NC}"
    else
        msg_warning "无法获取远程版本号，将直接比对代码"
    fi

    if [[ "$is_git" == "true" ]]; then
        local remote_head local_head
        remote_head=$(git -c safe.directory="*" ls-remote "$repo_url" HEAD 2>/dev/null | awk '{print $1}' | head -1 || true)
        local_head=$(git -c safe.directory="*" -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null || true)
        if [[ -n "$remote_head" && -n "$local_head" && "$remote_head" != "$local_head" ]]; then
            need_update=true
        fi
    elif [[ -n "$latest" && "$latest" != "$SCRIPT_VERSION" ]]; then
        need_update=true
    fi

    if [[ "$need_update" == "false" ]]; then
        msg_success "当前已是最新版本"
        if [[ "$mode" != "auto" ]]; then
            if confirm "是否仍然强制同步最新代码?"; then
                _do_git_update "$is_git" "$branch" || return 1
            fi
        elif [[ "$is_git" == "true" ]]; then
            msg_info "尝试同步远端代码..."
            if git -c safe.directory="*" -C "$SCRIPT_DIR" pull --ff-only --quiet 2>/dev/null; then
                msg_success "脚本已是最新"
            else
                msg_warning "同步失败，可稍后重试"
            fi
        fi
        return 0
    fi

    if [[ "$mode" != "auto" ]] && ! confirm "检测到新版本，是否立即更新?"; then
        msg_info "已取消更新"
        return 0
    fi

    if ! _do_git_update "$is_git" "$branch"; then
        _do_tarball_update "$latest"
    fi
}

_do_git_update() {
    local is_git="$1" branch="$2"
    if [[ "$is_git" != "true" ]]; then
        return 1
    fi

    msg_info "正在通过 Git 拉取最新代码..."
    if git -c safe.directory="*" -C "$SCRIPT_DIR" pull --ff-only --quiet; then
        msg_success "Git 更新成功"
    else
        msg_warning "快速更新失败（可能存在本地修改），需要强制同步"
        git -c safe.directory="*" -C "$SCRIPT_DIR" fetch --quiet --depth 1 origin 2>/dev/null || true
        if git -c safe.directory="*" -C "$SCRIPT_DIR" reset --hard --quiet "origin/${branch}" 2>/dev/null || \
           git -c safe.directory="*" -C "$SCRIPT_DIR" reset --hard --quiet origin/main 2>/dev/null; then
            msg_success "强制同步完成"
        else
            msg_error "Git 更新失败"
            return 1
        fi
    fi
    msg_success "更新完成，请重新运行 ${BRIGHT_GREEN}leh${NC}"
    exit 0
}

_do_tarball_update() {
    local latest="$1"
    msg_info "未检测到 Git 仓库，改用压缩包方式更新..."
    update_project_tarball "$latest"
    return $?
}

register_main_menu "更新脚本" "config_update"
