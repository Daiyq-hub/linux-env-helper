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
# 消息输出
# ═══════════════════════════════════════════════════════════════

msg_info()     { echo -e "  ${BLUE}[INFO]${NC} $1" >&2; }
msg_error()    { echo -e "  ${RED}[FAIL]${NC} $1" >&2; }
msg_success()  { echo -e "  ${GREEN}[ OK ]${NC} $1" >&2; }
msg_warning()  { echo -e "  ${YELLOW}[WARN]${NC} $1" >&2; }
msg_question() { echo -e "  [ ${MAGENTA}??${NC} ] $1" >&2; }
msg_star()     { echo -e "  ${BRIGHT_YELLOW}*${NC} $1" >&2; }

msg_prompt() {
    local prompt_text="$1"
    local target_var="${2:-choice}"
    local _input_val=""
    read -r -p "  ${BRIGHT_MAGENTA}➤${NC} ${BRIGHT_CYAN}${prompt_text}: ${NC}" _input_val
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
        read -r -p "  [ ${MAGENTA}??${NC} ] ${BOLD}${WHITE}${prompt}${NC} [y/N]: " response
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
    local msg="${1:-按任意键继续...}"
    echo "" >&2
    read -r -n 1 -p "  ${WHITE}${msg}${NC}"
    echo "" >&2
}

# ═══════════════════════════════════════════════════════════════
# 文本工具
# ═══════════════════════════════════════════════════════════════

get_term_width() {
    tput cols 2>/dev/null || echo 80
}

str_display_width() {
    local s="$1"
    local chars cjk
    local plain
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
    printf "${char}%.0s" $(seq 1 "$width")
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
        local cw
        cw=$(str_display_width "$c")
        local pad=$((w - cw))
        [[ $pad -lt 0 ]] && pad=0
        line+="$c$(printf '%*s' "$pad" '')"
    done
    echo -e "$line"
}

# ═══════════════════════════════════════════════════════════════
# 界面渲染
# ═══════════════════════════════════════════════════════════════

clear_screen() {
    printf '\033[H\033[J'
}

show_section() {
    echo ""
    echo -e "  ${BOLD}${CYAN}▸ $1${NC}"
    echo -e "  ${CYAN}────────────────────────────────────────────────────────${NC}"
}

show_header() {
    local title="$1"
    local width="${2:-60}"
    local color="${3:-$BRIGHT_GREEN}"
    echo ""
    echo -e "  ${GREEN}╭$(printf '─%.0s' $(seq 1 $((width - 2))))╮${NC}"
    ui_print_centered_row "$width" "${BOLD}${color}" "$title"
    echo -e "  ${GREEN}╰$(printf '─%.0s' $(seq 1 $((width - 2))))╯${NC}"
    echo ""
}

show_banner_rich() {
    local title="$1"
    local subtitle="${2:-}"
    local desc="${3:-}"
    local footer="${4:-}"
    local width="${5:-60}"

    echo ""
    echo -e "  ${GREEN}╭$(printf '─%.0s' $(seq 1 $((width - 2))))╮${NC}"
    ui_print_centered_row "$width" "${BOLD}${BRIGHT_GREEN}" "$title"
    [[ -n "$subtitle" ]] && ui_print_centered_row "$width" "${WHITE}" "$subtitle"
    [[ -n "$desc" ]] && ui_print_centered_row "$width" "${CYAN}" "$desc"
    [[ -n "$footer" ]] && {
        echo -e "  ${GREEN}├$(printf '─%.0s' $(seq 1 $((width - 2))))┤${NC}"
        ui_print_centered_row "$width" "${GRAY}" "$footer"
    }
    echo -e "  ${GREEN}╰$(printf '─%.0s' $(seq 1 $((width - 2))))╯${NC}"
    echo ""
}

ui_set_borders() {
    local width="$1"
    top_border="$(printf '─%.0s' $(seq 1 $((width - 2))))"
    mid_border="$(printf '─%.0s' $(seq 1 $((width - 2))))"
    bottom_border="$(printf '─%.0s' $(seq 1 $((width - 2))))"
}

ui_print_centered_row() {
    local width="$1" color="$2" text="$3"
    local tw cw lp rp
    tw=$(str_display_width "$text")
    lp=$(( (width - 2 - tw) / 2 ))
    rp=$(( width - 2 - tw - lp ))
    echo -e "  ${GREEN}│${NC}$(printf '%*s' "$lp" '')${color}${text}${NC}$(printf '%*s' "$rp" '')${GREEN}│${NC}"
}

ui_print_blank_row() {
    local width="$1"
    echo -e "  ${GREEN}│${NC}$(printf '%*s' $((width - 2)) '')${GREEN}│${NC}"
}

ui_print_footer() {
    local width="$1" left_text="$2" right_text="$3"
    local lw rw pad
    lw=$(str_display_width "$left_text")
    rw=$(str_display_width "$right_text")
    pad=$((width - 4 - lw - rw))
    [[ $pad -lt 0 ]] && pad=0
    echo -e "  ${GREEN}│${NC}  ${left_text}$(printf '%*s' "$pad" '')  ${right_text}  ${GREEN}│${NC}"
}

ui_render_grid() {
    local cols="$1" item_width="$2" total_width="$3" color="$4"
    shift 4
    local items=("$@")
    local count=${#items[@]}
    local rows=$(( (count + cols - 1) / cols ))
    local r c i
    for ((r = 0; r < rows; r++)); do
        local line="  ${GREEN}│${NC}  "
        for ((c = 0; c < cols; c++)); do
            i=$((r + c * rows))
            if (( i < count )); then
                line+="${color}$(printf '%2d. ' "$((i + 1))")${NC}${items[$i]}$(printf '%*s' $((item_width - 4 - $(str_display_width "${items[$i]}") )) '')"
            fi
        done
        line+="  ${GREEN}│${NC}"
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
    local i

    clear_screen
    echo ""
    show_banner_rich \
        "🐧 $SCRIPT_NAME v$SCRIPT_VERSION" \
        "适用系统: Ubuntu / Debian" \
        "脚本作用: Linux 环境一键配置" \
        "https://github.com/Daiyq-hub/linux-env-helper" \
        60

    echo -e "  ${GREEN}────────────────────────────────────────────────────────${NC}"
    for ((i = 0; i < count; i++)); do
        printf "  %2d. %s\n" "$((i + 1))" "${items[$i]}"
    done
    echo -e "  ${GREEN}────────────────────────────────────────────────────────${NC}"
    echo -e "  $(_get_menu_path_display)                    ${GREEN}[q] 退出脚本${NC}"
    echo ""
}

show_submenu() {
    local title="$1"
    shift
    local items=("$@")
    local count=${#items[@]}
    local i

    clear_screen
    echo ""
    show_header "$title" 52
    for ((i = 0; i < count; i++)); do
        printf "  %2d. %s\n" "$((i + 1))" "${items[$i]}"
    done
    echo ""
    echo -e "  ${GREEN}────────────────────────────────────────────────${NC}"
    echo -e "  $(_get_menu_path_display)          ${GREEN}0. 返回上级    [q] 退出脚本${NC}"
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
    read -r -sp "  ${GREEN}->${NC} ${prompt}: " "$var_name"
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
