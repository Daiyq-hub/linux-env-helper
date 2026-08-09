#!/usr/bin/env bash
#
# Copyright 2026 Hunan Yijing Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📝 模块描述 : 视觉样式、排版与视觉交互组件
#  📁 文件路径 : lib/common.sh
#  👤 作者信息 : mingy
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


# ═══════════════════════════════════════════════════════════════
# 严格模式与初始化
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# ANSI终端颜色定义
# ═══════════════════════════════════════════════════════════════

declare -A COLORS=(
    [reset]=$'\033[0m'
    [clear]=$'\033[0m'

    [bold]=$'\033[1m'
    [dim]=$'\033[2m'
    [italic]=$'\033[3m'
    [underline]=$'\033[4m'
    [blink]=$'\033[5m'
    [reverse]=$'\033[7m'
    [hidden]=$'\033[8m'
    [strike]=$'\033[9m'

    [black]=$'\033[30m'
    [red]=$'\033[31m'
    [green]=$'\033[32m'
    [yellow]=$'\033[33m'
    [blue]=$'\033[34m'
    [magenta]=$'\033[35m'
    [cyan]=$'\033[36m'
    [white]=$'\033[37m'
    [gray]=$'\033[90m'

    [bright_black]=$'\033[90m'
    [bright_red]=$'\033[91m'
    [bright_green]=$'\033[92m'
    [bright_yellow]=$'\033[93m'
    [bright_blue]=$'\033[94m'
    [bright_magenta]=$'\033[95m'
    [bright_cyan]=$'\033[96m'
    [bright_white]=$'\033[97m'

    [bg_black]=$'\033[40m'
    [bg_red]=$'\033[41m'
    [bg_green]=$'\033[42m'
    [bg_yellow]=$'\033[43m'
    [bg_blue]=$'\033[44m'
    [bg_magenta]=$'\033[45m'
    [bg_cyan]=$'\033[46m'
    [bg_white]=$'\033[47m'

    [bg_bright_black]=$'\033[100m'
    [bg_bright_red]=$'\033[101m'
    [bg_bright_green]=$'\033[102m'
    [bg_bright_yellow]=$'\033[103m'
    [bg_bright_blue]=$'\033[104m'
    [bg_bright_magenta]=$'\033[105m'
    [bg_bright_cyan]=$'\033[106m'
    [bg_bright_white]=$'\033[107m'
)

readonly RED="${COLORS[red]}"
readonly GREEN="${COLORS[green]}"
readonly YELLOW="${COLORS[yellow]}"
readonly BLUE="${COLORS[blue]}"
readonly MAGENTA="${COLORS[magenta]}"
readonly CYAN="${COLORS[cyan]}"
readonly WHITE="${COLORS[white]}"
readonly GRAY="${COLORS[gray]}"

readonly BRIGHT_RED="${COLORS[bright_red]}"
readonly BRIGHT_GREEN="${COLORS[bright_green]}"
readonly BRIGHT_YELLOW="${COLORS[bright_yellow]}"
readonly BRIGHT_BLUE="${COLORS[bright_blue]}"
readonly BRIGHT_MAGENTA="${COLORS[bright_magenta]}"
readonly BRIGHT_CYAN="${COLORS[bright_cyan]}"
readonly BRIGHT_WHITE="${COLORS[bright_white]}"

readonly NC="${COLORS[reset]}"
readonly BOLD="${COLORS[bold]}"

export GREEN RED YELLOW BLUE MAGENTA CYAN GRAY WHITE BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW BRIGHT_BLUE BRIGHT_MAGENTA BRIGHT_CYAN BRIGHT_WHITE NC BOLD

# ═══════════════════════════════════════════════════════════════
# 状态消息输出
# ═══════════════════════════════════════════════════════════════

msg_info() { echo -e "  ${BLUE}[INFO]${NC} $1" >&2; }
msg_error() { echo -e "  ${RED}[FAIL]${NC} $1" >&2; }
msg_success() { echo -e "  ${GREEN}[ OK ]${NC} $1" >&2; }
msg_warning() { echo -e "  ${YELLOW}[WARN]${NC} $1" >&2; }
msg_question() { echo -e "  [ ${MAGENTA}??${NC} ] $1" >&2; }
msg_star() { echo -e "  ${BRIGHT_YELLOW}*${NC} $1" >&2; }
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

# ═══════════════════════════════════════════════════════════════
# 命令状态检查
# ═══════════════════════════════════════════════════════════════

action() {
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        msg_success "$1"
        return 0
    else
        msg_error "$2"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# 排版与渲染工具
# ═══════════════════════════════════════════════════════════════

get_term_width() {
    local width
    width=$(tput cols 2>/dev/null) || width=80
    [[ $width -gt 100 ]] && width=100
    echo "$width"
}

draw_line() {
    local char="${1:--}"
    local color="${2:-}"

    local width
    width=$(get_term_width)
    local line_w=$((width - 6))
    [[ $line_w -gt 60 ]] && line_w=60
    [[ $line_w -lt 40 ]] && line_w=40
    
    {
        printf "  "
        [[ -n "$color" ]] && printf "%b" "$color"
        local i
        for ((i=0; i<line_w; i++)); do printf "%s" "$char"; done
        [[ -n "$color" ]] && printf "%b" "${NC}"
        echo ""
    } >&2
}

str_display_width() {
    local str="$1"
    local pure_str
    pure_str=$(echo -e "$str" | sed 's/\x1b\[[0-9;]*m//g')
    echo -n "$pure_str" | wc -L
}

msg_table_row() {
    local -a widths
    read -ra widths <<< "$1"
    shift
    local table_cols=("$@")
    local row_str="  "
    local i

    for i in "${!table_cols[@]}"; do
        local content="${table_cols[$i]}"
        local width="${widths[$i]:-0}"
        local d_w; d_w=$(str_display_width "$content")
        
        local padding=$((width - d_w))
        [[ $padding -lt 0 ]] && padding=0
        
        if [[ $i -eq $(( ${#table_cols[@]} - 1 )) ]]; then
            row_str+="${content}"
        else
            row_str+="${content}$(printf "%*s" "$padding" " ")"
        fi
    done
    echo -e "$row_str"
}

# ═══════════════════════════════════════════════════════════════
# UI布局辅助
# ═══════════════════════════════════════════════════════════════

ui_set_borders() {
    local w=$1
    top_border="╭$(printf '─%.0s' $(seq 1 $((w - 2))))╮"
    mid_border="├$(printf '─%.0s' $(seq 1 $((w - 2))))┤"
    bottom_border="╰$(printf '─%.0s' $(seq 1 $((w - 2))))╯"
}

ui_print_centered_row() {
    local w=$1 color="$2" text="$3"
    local tw; tw=$(str_display_width "$text")
    local lp=$(( (w - 2 - tw) / 2 ))
    local rp=$(( w - 2 - tw - lp ))
    echo -e "  ${GREEN}│${NC}$(printf '%*s' "$lp" ' ')${color}${text}${NC}$(printf '%*s' "$rp" ' ')${GREEN}│${NC}"
}

ui_print_blank_row() {
    local w=$1
    echo -e "  ${GREEN}│${NC}$(printf '%*s' $((w - 2)) ' ')${GREEN}│${NC}"
}

ui_print_footer() {
    local total_width=$1 left_text="$2" right_text="$3"
    local left_color="${4:-$WHITE}" right_color="${5:-$BRIGHT_GREEN}"
    
    local left_w; left_w=$(str_display_width "$left_text")
    local right_w; right_w=$(str_display_width "$right_text")
    
    local padding=$((total_width - 6 - left_w - right_w))
    [[ $padding -lt 0 ]] && padding=0
    
    echo -e "  ${GREEN}│${NC}  ${left_color}${left_text}${NC}$(printf '%*s' "$padding" ' ')${right_color}${right_text}${NC}  ${GREEN}│${NC}"
}

ui_render_grid() {
    local grid_cols=$1 item_width=$2 total_width=$3 num_color=$4
    shift 4
    local grid_items=("$@")
    local count=${#grid_items[@]}
    local mid=$(( (count + grid_cols - 1) / grid_cols ))
    local r c
    
    for ((r=0; r<mid; r++)); do
        local line="" pure_line=""
        for ((c=0; c<grid_cols; c++)); do
            local idx=$((r + c*mid))
            if [[ $idx -lt $count ]]; then
                local num=$((idx+1)) name="${grid_items[$idx]}"
                local num_fmt; num_fmt=$(printf "%2d" "$num")
                local item_str="  ${num_color}${num_fmt}.${NC} ${name}"
                local pure_item="  ${num_fmt}. ${name}"
                
                local w; w=$(str_display_width "$pure_item")
                local pad=$((item_width - w))
                [[ $pad -lt 0 ]] && pad=0
                line+="${item_str}$(printf '%*s' "$pad" ' ')"
                pure_line+="${pure_item}$(printf '%*s' "$pad" ' ')"
            else
                line+="$(printf '%*s' "$item_width" ' ')"
                pure_line+="$(printf '%*s' "$item_width" ' ')"
            fi
        done
        local t_w; t_w=$(str_display_width "$pure_line")
        local p=$((total_width - 2 - t_w))
        [[ $p -lt 0 ]] && p=0
        echo -e "  ${GREEN}│${NC}${line}$(printf '%*s' "$p" ' ')${GREEN}│${NC}"
    done
}

show_header() {
    local title="$1"
    local width="${2:-0}"
    local color="${3:-$GREEN}"
    
    local top_border bottom_border
    if [[ $width -gt 0 ]]; then
        ui_set_borders "$width"
        echo ""
        echo -e "  ${color}${top_border}${NC}"
        ui_print_centered_row "$width" "${BOLD}" "$title"
        echo -e "  ${color}${bottom_border}${NC}"
    else
        local tw; tw=$(str_display_width "$title")
        local border_w=$((tw + 4))
        local border; border=$(printf '─%.0s' $(seq 1 $border_w))
        echo ""
        echo -e "  ${color}╭${border}╮${NC}"
        echo -e "  ${color}│${NC}  ${BOLD}${title}${NC}  ${color}│${NC}"
        echo -e "  ${color}╰${border}╯${NC}"
    fi
}

show_banner_rich() {
    local title="${1:-}"
    local desc1="${2:-}"
    local desc2="${3:-}"
    local author="${4:-}"
    local total_w="${5:-60}"
    local is_connector="${6:-0}"

    local top_border mid_border bottom_border
    ui_set_borders "$total_w"

    echo ""
    echo -e "  ${GREEN}${top_border}${NC}"
    ui_print_blank_row "$total_w"
    [[ -n "$title" ]] && ui_print_centered_row "$total_w" "${BOLD}${BRIGHT_CYAN}" "$title"
    ui_print_blank_row "$total_w"
    [[ -n "$desc1" ]] && ui_print_centered_row "$total_w" "${BRIGHT_GREEN}" "$desc1"
    [[ -n "$desc2" ]] && ui_print_centered_row "$total_w" "${BRIGHT_GREEN}" "$desc2"
    ui_print_blank_row "$total_w"
    [[ -n "$author" ]] && ui_print_centered_row "$total_w" "${BRIGHT_YELLOW}" "$author"
    ui_print_blank_row "$total_w"
    
    if [[ "$is_connector" == "1" ]]; then
        echo -e "  ${GREEN}${mid_border}${NC}"
    else
        echo -e "  ${GREEN}${bottom_border}${NC}"
    fi
}

show_section() {
    local title="$1"
    local current="${2:-}"
    local total="${3:-}"
    
    local display_title="$title"
    if [[ -n "$current" && -n "$total" ]]; then
        display_title="阶段 $current/$total: $title"
    fi

    local width; width=$(get_term_width)
    local line_w=$((width - 6))
    [[ $line_w -gt 60 ]] && line_w=60
    [[ $line_w -lt 40 ]] && line_w=40
    
    local border; border=$(printf '─%.0s' $(seq 1 $line_w))
    {
        echo ""
        echo -e "  ${BRIGHT_GREEN}▸ ${BOLD}${display_title}${NC}"
        echo -e "  ${border}"
    } >&2
}


# ═══════════════════════════════════════════════════════════════
# 全局显示控制
# ═══════════════════════════════════════════════════════════════

clear_screen() {
    hash -r 2>/dev/null || true
    clear 2>/dev/null || printf "\033c" 2>/dev/null || true
}

pause() {
    local msg="${1:-按任意键继续...}"
    echo "" >&2
    read -r -n 1 -p "  ${WHITE}${msg}${NC}"
    echo "" >&2
}

# ═══════════════════════════════════════════════════════════════
# 进度条渲染
# ═══════════════════════════════════════════════════════════════

show_progress() {
    local current=$1
    local total=$2
    local width=40
    [[ $total -eq 0 ]] && total=100
    [[ $current -gt $total ]] && current=$total
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    printf "\r\033[K  [" >&2
    printf "%${filled}s" "" | tr " " "#" >&2
    printf "%${empty}s" "" | tr " " "-" >&2
    printf "] %3d%%" "$percentage" >&2
}

#!/usr/bin/env bash
#
# Copyright 2026 Hunan Yijing Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📝 模块描述 : 用户交互与输入验证组件
#  📁 文件路径 : lib/io.sh
#  👤 作者信息 : mingy
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


# ═══════════════════════════════════════════════════════════════
# 用户交互输入
# ═══════════════════════════════════════════════════════════════

read_password() {
    local prompt="$1"
    local var_name="$2"
    read -r -sp "  ${GREEN}->${NC} ${prompt}: " "${var_name?}"
    echo ""
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

# ═══════════════════════════════════════════════════════════════
# 输入格式验证
# ═══════════════════════════════════════════════════════════════

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

    if [[ $port =~ ^[0-9]+$ ]] && [[ $port -ge 1 ]] && [[ $port -le 65535 ]]; then
        return 0
    else
        msg_error "请输入有效的端口号(1-65535)"
        return 1
    fi
}


#!/usr/bin/env bash
#
# Copyright 2026 Hunan Yijing Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📝 模块描述 : 现代化菜单系统与注册机制
#  📁 文件路径 : lib/menu.sh
#  👤 作者信息 : mingy
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


# ═══════════════════════════════════════════════════════════════
# 菜单注册与路径管理
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
# 内部辅助函数
# ═══════════════════════════════════════════════════════════════

_get_menu_path_display() {
    local path="${WHITE}主菜单${NC}"
    if [[ ${#MENU_PATH[@]} -gt 0 ]]; then
        local p
        for p in "${MENU_PATH[@]}"; do
            path+=" ${GRAY}>${NC} ${WHITE}${p}${NC}"
        done
    fi
    echo -e "${BRIGHT_YELLOW}↳${NC} ${path}"
}

# ═══════════════════════════════════════════════════════════════
# 主菜单渲染
# ═══════════════════════════════════════════════════════════════

show_main_menu() {
    local items=("${MAIN_MENU_ITEMS[@]}")
    local count=${#items[@]}
    local term_width; term_width=$(get_term_width)
    
    local cols=2 item_width=32 total_width=68
    [[ $term_width -lt 75 ]] && { cols=1; item_width=50; total_width=54; }
    
    local path_display; path_display=$(_get_menu_path_display)
    local path_w; path_w=$(str_display_width "$path_display")
    local exit_text="[q] 退出脚本"
    local exit_w; exit_w=$(str_display_width "$exit_text")
    
    local min_required_width=$((path_w + exit_w + 10))
    [[ $total_width -lt $min_required_width ]] && total_width=$min_required_width

    local top_border mid_border bottom_border
    ui_set_borders "$total_width"

    clear_screen
    echo ""
    
    show_banner_rich \
        "🐧 $SCRIPT_NAME v$SCRIPT_VERSION" \
        "适用系统: Ubuntu / Kali Linux" \
        "脚本作用: Linux 基础环境配置 " \
        "✨ Developed by mingy@蚁景科技 ✨" \
        "$total_width" 1

    ui_render_grid "$cols" "$item_width" "$total_width" "$BRIGHT_GREEN" "${items[@]}"
    
    echo -e "  ${GREEN}${mid_border}${NC}"
    ui_print_footer "$total_width" "$path_display" "$exit_text" "$WHITE" "$BRIGHT_GREEN"
    echo -e "  ${GREEN}${bottom_border}${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
# 子菜单
# ═══════════════════════════════════════════════════════════════

show_submenu() {
    local title="$1"
    shift
    local items=("$@")
    local count=${#items[@]}
    local term_width; term_width=$(get_term_width)
    
    local cols=1 item_width=40 total_width=50
    if [[ $count -gt 10 && $term_width -ge 75 ]]; then
        cols=2; item_width=32; total_width=68
    else
        local max_len; max_len=$(str_display_width "$title")
        local item
        for item in "${items[@]}"; do
            local w; w=$(str_display_width "  10. $item")
            [[ $w -gt $max_len ]] && max_len=$w
        done
        total_width=$((max_len + 12))
        [[ $total_width -lt 50 ]] && total_width=50
        [[ $total_width -gt 76 ]] && total_width=76
        item_width=$((total_width - 4))
    fi

    local path_display; path_display=$(_get_menu_path_display)
    local path_w; path_w=$(str_display_width "$path_display")
    
    local min_required_width=$((path_w + 8))
    if [[ $total_width -lt $min_required_width ]]; then
        total_width=$min_required_width
        item_width=$((cols == 1 ? total_width - 4 : (total_width - 4) / 2))
    fi

    local top_border mid_border bottom_border
    ui_set_borders "$total_width"

    clear_screen
    echo ""
    echo -e "  ${GREEN}${top_border}${NC}"
    ui_print_centered_row "$total_width" "${BOLD}${BRIGHT_GREEN}" "$title"
    echo -e "  ${GREEN}${mid_border}${NC}"
    
    local padding=$((total_width - 6 - path_w))
    [[ $padding -lt 0 ]] && padding=0
    echo -e "  ${GREEN}│${NC}  ${WHITE}${path_display}${NC}$(printf '%*s' "$padding" ' ')  ${GREEN}│${NC}"
    ui_print_blank_row "$total_width"
    
    ui_render_grid "$cols" "$item_width" "$total_width" "$BRIGHT_CYAN" "${items[@]}"
    
    ui_print_blank_row "$total_width"
    echo -e "  ${GREEN}${mid_border}${NC}"
    
    ui_print_footer "$total_width" "0. 返回上级菜单" "[q] 退出脚本" "$WHITE" "$BRIGHT_GREEN"
    echo -e "  ${GREEN}${bottom_border}${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
# 菜单调度
# ═══════════════════════════════════════════════════════════════

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
    
    if [[ $idx -lt 0 || $idx -ge $count ]]; then
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
