#!/usr/bin/env bash
#
# LinuxEnv Helper - UI 交互层
# License: Apache License 2.0

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# 终端颜色
# ═══════════════════════════════════════════════════════════════

declare -A COLORS=(
    [black]=$'\033[30m'
    [red]=$'\033[31m'
    [green]=$'\033[32m'
    [yellow]=$'\033[33m'
    [blue]=$'\033[34m'
    [magenta]=$'\033[35m'
    [cyan]=$'\033[36m'
    [gray]=$'\033[37m'
    [white]=$'\033[97m'
    [bright_red]=$'\033[91m'
    [bright_green]=$'\033[92m'
    [bright_yellow]=$'\033[93m'
    [bright_blue]=$'\033[94m'
    [bright_magenta]=$'\033[95m'
    [bright_cyan]=$'\033[96m'
    [bright_white]=$'\033[1;97m'
    [bold]=$'\033[1m'
    [reset]=$'\033[0m'
)

readonly BLACK="${COLORS[black]}"
readonly RED="${COLORS[red]}"
readonly GREEN="${COLORS[green]}"
readonly YELLOW="${COLORS[yellow]}"
readonly BLUE="${COLORS[blue]}"
readonly MAGENTA="${COLORS[magenta]}"
readonly CYAN="${COLORS[cyan]}"
readonly GRAY="${COLORS[gray]}"
readonly WHITE="${COLORS[white]}"
readonly BRIGHT_RED="${COLORS[bright_red]}"
readonly BRIGHT_GREEN="${COLORS[bright_green]}"
readonly BRIGHT_YELLOW="${COLORS[bright_yellow]}"
readonly BRIGHT_BLUE="${COLORS[bright_blue]}"
readonly BRIGHT_MAGENTA="${COLORS[bright_magenta]}"
readonly BRIGHT_CYAN="${COLORS[bright_cyan]}"
readonly BRIGHT_WHITE="${COLORS[bright_white]}"
readonly NC="${COLORS[reset]}"
readonly BOLD="${COLORS[bold]}"

export RED GREEN YELLOW BLUE MAGENTA CYAN GRAY WHITE BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW BRIGHT_BLUE BRIGHT_MAGENTA BRIGHT_CYAN BRIGHT_WHITE NC BOLD

# ═══════════════════════════════════════════════════════════════
# 消息输出（符号化风格）
# ═══════════════════════════════════════════════════════════════

msg_info()     { echo -e "  ${BLUE}ℹ${NC} $1" >&2; }
msg_error()    { echo -e "  ${RED}✘${NC} $1" >&2; }
msg_success()  { echo -e "  ${GREEN}✔${NC} $1" >&2; }
msg_warning()  { echo -e "  ${YELLOW}⚠${NC} $1" >&2; }
msg_question() { echo -e "  ${MAGENTA}?${NC} $1" >&2; }
msg_star()     { echo -e "  ${BRIGHT_YELLOW}→${NC} $1" >&2; }

msg_prompt() {
    local prompt_text="$1"
    local target_var="${2:-choice}"
    local _input_val=""
    read -r -p "  ${BRIGHT_MAGENTA}❯${NC} ${BRIGHT_CYAN}${prompt_text}: ${NC}" _input_val || exit 0
    printf -v "$target_var" "%s" "$_input_val"
}

msg_prompt_required() {
    local prompt_text="$1"
    local target_var="$2"
    local _res_val=""
    while true; do
        msg_prompt "$prompt_text" _res_val
        if [[ -n "$_res_val" ]]; then
            printf -v "$target_var" "%s" "$_res_val"
            return 0
        fi
        msg_error "输入不能为空，请重新输入"
    done
}

confirm() {
    local prompt="${1:-确认执行此操作?}"
    local response
    while true; do
        read -r -p "  ${MAGENTA}?${NC} ${BOLD}${WHITE}${prompt}${NC} [y/N]: " response || exit 0
        case "$response" in
            [Yy]*|[Yy][Ee][Ss]) return 0 ;;
            [Nn]*|[Nn][Oo]|"") return 1 ;;
            *) msg_warning "请输入 y 或 n" ;;
        esac
    done
}

action() {
    local prev=$?
    local ok_msg="$1"
    local fail_msg="$2"
    if [[ $prev -eq 0 ]]; then
        msg_success "$ok_msg"
        return 0
    else
        msg_error "$fail_msg"
        return 1
    fi
}

pause() {
    local msg="${1:-按回车键继续...}"
    echo "" >&2
    read -r -p "  ${WHITE}${msg}${NC}" || exit 0
}

# ═══════════════════════════════════════════════════════════════
# 文本工具
# ═══════════════════════════════════════════════════════════════

get_term_width() {
    tput cols 2>/dev/null || echo 80
}

str_display_width() {
    local s="$1"
    local plain chars cjk
    plain=$(printf '%s' "$s" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g')
    chars=$(printf '%s' "$plain" | wc -m)
    cjk=$(printf '%s' "$plain" | grep -oP '[\x{4e00}-\x{9fff}\x{3000}-\x{303f}\x{ff00}-\x{ffef}]' | wc -l)
    echo $((chars + cjk))
}

draw_line() {
    local char="${1:-─}"
    local color="${2:-$GRAY}"
    local width="${3:-50}"
    printf "  %b" "$color"
    printf -- "${char}%.0s" $(seq 1 "$width")
    printf "%b\n" "$NC"
}

msg_table_row() {
    local widths="$1"
    shift
    local cells=("$@")
    local -a ws
    read -ra ws <<< "$widths"
    local line="  "
    local i
    for ((i = 0; i < ${#cells[@]}; i++)); do
        local c="${cells[$i]}"
        local w="${ws[$i]:-0}"
        local cw pad
        cw=$(str_display_width "$c")
        pad=$((w - cw))
        [[ $pad -lt 0 ]] && pad=0
        line+="$c$(printf '%*s' "$pad" '')"
    done
    echo -e "$line"
}

# ═══════════════════════════════════════════════════════════════
# 界面渲染（双线风格）
# ═══════════════════════════════════════════════════════════════

clear_screen() {
    printf '\033[H\033[J'
}

show_section() {
    echo ""
    echo -e "  ${BOLD}${CYAN}${1}${NC}"
    echo -e "  ${GRAY}$(printf '─%.0s' $(seq 1 46))${NC}"
}

show_header() {
    local title="$1"
    local width="${2:-52}"
    echo ""
    echo -e "  ${GRAY}$(printf '━%.0s' $(seq 1 "$width"))${NC}"
    echo -e "  ${BOLD}${BRIGHT_GREEN}  ${title}${NC}"
    echo -e "  ${GRAY}$(printf '━%.0s' $(seq 1 "$width"))${NC}"
    echo ""
}

show_banner_rich() {
    local title="$1"
    local subtitle="${2:-}"
    local desc="${3:-}"
    local footer="${4:-}"
    local width="${5:-56}"

    local inner=$((width - 4))
    local top bottom
    top=$(printf '  ╔'; printf '═%.0s' $(seq 1 "$inner"); printf '╗')
    bottom=$(printf '  ╚'; printf '═%.0s' $(seq 1 "$inner"); printf '╝')

    _banner_row() {
        local text="$1" color="${2:-$NC}"
        local tw pad right
        tw=$(str_display_width "$text")
        pad=$(( (inner - tw) / 2 ))
        [[ $pad -lt 0 ]] && pad=0
        right=$(( inner - tw - pad ))
        printf '  ║%s%b%s%b%s║\n' \
            "$(printf '%*s' "$pad" '')" \
            "$color" "$text" "$NC" \
            "$(printf '%*s' "$right" '')"
    }

    echo ""
    echo -e "$top"
    _banner_row "$title" "${BOLD}${BRIGHT_GREEN}"
    [[ -n "$subtitle" ]] && _banner_row "$subtitle" "${WHITE}"
    [[ -n "$desc" ]] && _banner_row "$desc" "${CYAN}"
    echo -e "$bottom"
    [[ -n "$footer" ]] && echo -e "  ${GRAY}${footer}${NC}"
    echo ""
}

ui_set_borders() { :; }
ui_print_centered_row() { :; }
ui_print_blank_row() { :; }
ui_print_footer() { :; }

ui_render_grid() {
    local cols="$1" item_width="$2" total_width="$3" color="$4"
    shift 4
    local items=("$@")
    local count=${#items[@]}
    local rows=$(( (count + cols - 1) / cols ))
    local r c i

    for ((r = 0; r < rows; r++)); do
        local line="  "
        for ((c = 0; c < cols; c++)); do
            i=$((r + c * rows))
            if (( i < count )); then
                local num label iw pad
                printf -v num "%02d" "$((i + 1))"
                label="${items[$i]}"
                iw=$(str_display_width "$label")
                pad=$((item_width - 5 - iw))
                [[ $pad -lt 0 ]] && pad=0
                line+="${color}[${num}]${NC} ${label}$(printf '%*s' "$pad" '')  "
            fi
        done
        echo -e "$line"
    done
}

# ═══════════════════════════════════════════════════════════════
# 菜单注册与调度
# ═══════════════════════════════════════════════════════════════

MAIN_MENU_ITEMS=()
MAIN_MENU_HANDLERS=()
MENU_PATH=()

push_path() { MENU_PATH+=("$1"); }
pop_path() {
    [[ ${#MENU_PATH[@]} -gt 0 ]] && unset 'MENU_PATH[${#MENU_PATH[@]}-1]'
}

register_main_menu() {
    MAIN_MENU_ITEMS+=("$1")
    MAIN_MENU_HANDLERS+=("$2")
}

# ═══════════════════════════════════════════════════════════════
# 主菜单按名称首字母排序
#  - "配置Xxx" 按 Xxx 的首字母排序（如 配置ARL → A）
#  - 中文名称按拼音首字母映射（查看→C / 更新→G / 基础/监控→J / 系统→X / 一键→Y）
# ═══════════════════════════════════════════════════════════════

_menu_sort_key() {
    local label="$1"
    local name="${label#配置}"
    local first="${name:0:1}"
    case "$first" in
        [A-Za-z]) printf '%s' "$first" | tr 'A-Z' 'a-z' ;;
        查) printf 'c' ;;
        更) printf 'g' ;;
        基|监) printf 'j' ;;
        系) printf 'x' ;;
        一) printf 'y' ;;
        *) printf 'z' ;;
    esac
}

sort_main_menu() {
    local -a lines sorted
    local i item handler

    for ((i = 0; i < ${#MAIN_MENU_ITEMS[@]}; i++)); do
        item="${MAIN_MENU_ITEMS[$i]}"
        handler="${MAIN_MENU_HANDLERS[$i]}"
        lines+=("$(_menu_sort_key "$item")|$item|$handler")
    done

    mapfile -t sorted < <(printf '%s\n' "${lines[@]}" | LC_ALL=C sort -f)

    MAIN_MENU_ITEMS=()
    MAIN_MENU_HANDLERS=()
    local line key
    for line in "${sorted[@]}"; do
        IFS='|' read -r key item handler <<< "$line"
        MAIN_MENU_ITEMS+=("$item")
        MAIN_MENU_HANDLERS+=("$handler")
    done
}

_get_menu_path_display() {
    local path="主菜单"
    local p
    for p in "${MENU_PATH[@]}"; do
        path+=" > ${p}"
    done
    echo -e "${BRIGHT_YELLOW}↳${NC} ${path}"
}

show_main_menu() {
    local items=("${MAIN_MENU_ITEMS[@]}")
    local count=${#items[@]}

    clear_screen
    show_banner_rich \
        "🐧 $SCRIPT_NAME v$SCRIPT_VERSION" \
        "适用于 Ubuntu / Debian 服务器" \
        "交互式菜单 · 一键配置 · 命令行模式" \
        "https://github.com/Daiyq-hub/linux-env-helper" \
        56

    echo -e "  ${BOLD}${CYAN}功能模块${NC}"
    echo -e "  ${GRAY}$(printf '─%.0s' $(seq 1 52))${NC}"
    ui_render_grid 2 32 66 "${BRIGHT_CYAN}" "${items[@]}"
    echo -e "  ${GRAY}$(printf '─%.0s' $(seq 1 52))${NC}"
    echo -e "  $(_get_menu_path_display)    ${GREEN}[q] 退出${NC}"
    echo ""
}

show_submenu() {
    local title="$1"
    shift
    local items=("$@")
    local count=${#items[@]}

    clear_screen
    echo ""
    echo -e "  ${BOLD}${BRIGHT_CYAN}${title}${NC}"
    echo -e "  ${GRAY}$(printf '─%.0s' $(seq 1 46))${NC}"
    ui_render_grid 1 42 60 "${BRIGHT_CYAN}" "${items[@]}"
    echo -e "  ${GRAY}$(printf '─%.0s' $(seq 1 46))${NC}"
    echo -e "  $(_get_menu_path_display)    ${GREEN}[0] 返回上级   [q] 退出${NC}"
    echo ""
}

handle_main_menu() {
    local choice="$1"

    [[ $choice == "q" || $choice == "Q" ]] && return 255

    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        msg_error "请输入有效的数字"
        pause
        return 0
    fi

    local idx=$((choice - 1))
    local count=${#MAIN_MENU_ITEMS[@]}

    if (( idx < 0 || idx >= count )); then
        msg_error "选项超出范围 (1-$count)"
        pause
        return 0
    fi

    local handler="${MAIN_MENU_HANDLERS[$idx]}"
    if ! declare -f "$handler" > /dev/null; then
        msg_error "处理函数未找到: $handler"
        pause
        return 0
    fi

    push_path "${MAIN_MENU_ITEMS[$idx]}"
    $handler
    local ret=$?
    pop_path

    return $ret
}

# ═══════════════════════════════════════════════════════════════
# 输入校验
# ═══════════════════════════════════════════════════════════════

read_password() {
    local prompt="$1"
    local var_name="$2"
    read -r -sp "  ${GREEN}->${NC} ${prompt}: " "$var_name" || exit 0
    echo ""
}

validate_ip() {
    local ip=$1
    local regex='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'
    if [[ $ip =~ $regex ]]; then
        return 0
    else
        msg_error "请输入正确的IP地址格式"
        return 1
    fi
}

validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 )); then
        return 0
    else
        msg_error "请输入有效的端口号(1-65535)"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# 进度条
# ═══════════════════════════════════════════════════════════════

show_progress() {
    local current="$1"
    local total="$2"
    local percent=$((current * 100 / total))
    local width=40
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    printf "\r  [%s%s] %3d%%" \
        "$(printf '#%.0s' $(seq 1 $filled))" \
        "$(printf ' %.0s' $(seq 1 $empty))" \
        "$percent"
}
