#!/usr/bin/env bash
#
# LinuxEnv Helper - jdk.sh
# License: Apache License 2.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ═══════════════════════════════════════════════════════════════
# 全局变量与配置
# ═══════════════════════════════════════════════════════════════

readonly JVM_INSTALL_BASE="/usr/lib/jvm"
readonly JDK_ENV_FILE="/etc/profile.d/jdk.sh"
readonly OPENJDK_MIRROR_BASE="https://mirrors.huaweicloud.com/openjdk"
readonly JDK_BINARIES=("java" "javac" "keytool" "jar" "jarsigner")

readonly ORACLE_JDK_VERSIONS=("jdk1.8.0_421" "jdk-11.0.24" "jdk-17.0.12" "jdk-21.0.4" "jdk-22.0.2" "jdk-23.0.1")
readonly ORACLE_JDK_NAMES=("jdk-8u421-linux-x64.tar.gz" "jdk-11.0.24_linux-x64_bin.tar.gz" "jdk-17.0.12_linux-x64_bin.tar.gz" "jdk-21.0.4_linux-x64_bin.tar.gz" "jdk-22.0.2_linux-x64_bin.tar.gz" "jdk-23_linux-x64_bin.tar.gz")
readonly ORACLE_JDK_LABELS=("Oracle JDK 8 LTS" "Oracle JDK 11 LTS" "Oracle JDK 17 LTS" "Oracle JDK 21 LTS" "Oracle JDK 22 LTS" "Oracle JDK 23 LTS")

# ═══════════════════════════════════════════════════════════════
# JDK配置主菜单
# ═══════════════════════════════════════════════════════════════

config_jdk() {
    while true; do
        show_submenu "JDK配置" \
            "安装OracleJDK" \
            "安装OpenJDK" \
            "切换JDK版本" \
            "删除JDK环境" \
            "查看已安装JDK"

        local choice ret
        msg_prompt "请选择操作 [0-5, q退出]"

        case $choice in
            0) return ;;
            q|Q) exit 0 ;;
            1) push_path "安装OracleJDK"; install_oracle_keyfree; ret=$?; pop_path; [[ $ret -eq 255 ]] && continue ;;
            2) push_path "安装OpenJDK"; config_jdk_openjdk; pop_path; continue ;;
            3) switch_jdk ;;
            4) remove_jdk ;;
            5) list_installed_jdk ;;
            *) msg_error "无效选择" ;;
        esac

        pause
    done
}

# ═══════════════════════════════════════════════════════════════
# 从公共镜像/官网安装 OracleJDK（无需客户端密钥）
# ═══════════════════════════════════════════════════════════════

install_oracle_keyfree() {
    show_section "从公共镜像/官网安装 OracleJDK"

    show_submenu "OracleJDK版本选择" "${ORACLE_JDK_LABELS[@]}"
    local version
    msg_prompt "请选择版本 [1-6, 0返回, q退出]" "version"

    if [[ $version == "q" || $version == "Q" ]]; then
        exit 0
    fi
    if [[ $version == "0" ]]; then
        return 255
    fi

    local index=$((version - 1))
    local url=""
    case $index in
        0) url="https://mirrors.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz" ;;
        1) url="https://download.oracle.com/java/11/latest/jdk-11_linux-x64_bin.tar.gz" ;;
        2) url="https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz" ;;
        3) url="https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz" ;;
        4) url="https://download.oracle.com/java/22/latest/jdk-22_linux-x64_bin.tar.gz" ;;
        5) url="https://download.oracle.com/java/23/latest/jdk-23_linux-x64_bin.tar.gz" ;;
        *) msg_error "无效选择"; return 1 ;;
    esac

    local filename="/tmp/$(basename "$url")"
    [[ -f "$filename" ]] && rm -f "$filename"

    msg_info "正在下载: $url"
    if ! download_file "$url" "$filename"; then
        msg_error "下载失败，请检查网络或换用其他安装方式"
        rm -f "$filename"
        return 1
    fi

    sudo mkdir -p "$JVM_INSTALL_BASE"
    msg_info "正在解压安装到 $JVM_INSTALL_BASE ..."
    if ! sudo tar -xzf "$filename" -C "$JVM_INSTALL_BASE"; then
        msg_error "解压失败"
        rm -f "$filename"
        return 1
    fi
    rm -f "$filename"

    local jdk_dir
    jdk_dir=$(find "$JVM_INSTALL_BASE" -maxdepth 1 -type d -name 'jdk*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}' || true)
    if [[ -z $jdk_dir || ! -x "$jdk_dir/bin/java" ]]; then
        msg_error "未找到解压后的JDK目录"
        return 1
    fi

    configure_jdk_env "$jdk_dir"
    msg_success "JDK 安装完成: $("$jdk_dir/bin/java" -version 2>&1 | head -1)"
}

install_manual_jdk_package() {
    local url="$1"
    local filename="$2"
    local target_dir_name="$3"

    [[ -f "$filename" ]] && rm -f "$filename"

    msg_info "正在从镜像下载: $filename"
    if ! download_file "$url" "$filename"; then
        msg_error "下载失败"
        rm -f "$filename"
        return 1
    fi

    msg_success "下载完成"

    sudo mkdir -p "$JVM_INSTALL_BASE"

    msg_info "正在解压安装到 ${JVM_INSTALL_BASE}/${target_dir_name}"
    [[ -d "$JVM_INSTALL_BASE/$target_dir_name" ]] && sudo rm -rf "$JVM_INSTALL_BASE/$target_dir_name"

    if ! sudo tar -xzf "$filename" -C "$JVM_INSTALL_BASE"; then
        msg_error "解压失败"
        rm -f "$filename"
        return 1
    fi

    rm -f "$filename"

    configure_jdk_env "$JVM_INSTALL_BASE/$target_dir_name"

    msg_success "JDK${target_dir_name}安装并配置成功"
}

# ═══════════════════════════════════════════════════════════════
# OpenJDK配置
# ═══════════════════════════════════════════════════════════════

config_jdk_openjdk() {
    while true; do
        show_submenu "OpenJDK安装选择" \
            "通过APT安装OpenJDK (推荐)" \
            "从华为主机镜像安装 (Legacy)"

        local choice ret
        msg_prompt "请选择安装方式 [0-2, q退出]"

        case $choice in
            0) return ;;
            q|Q) exit 0 ;;
            1) openjdk_apt_menu; ret=$?; [[ $ret -eq 255 ]] && continue ;;
            2) openjdk_mirror_menu; ret=$?; [[ $ret -eq 255 ]] && continue ;;
            *) msg_error "无效选择" ;;
        esac
        pause
    done
}

openjdk_apt_menu() {
    while true; do
        local available=()
        local display_names=()

        msg_info "正在从APT仓库动态扫描OpenJDK版本..."

        local found_versions=""
        if command -v apt-cache >/dev/null 2>&1; then
            found_versions=$(apt-cache pkgnames openjdk- | grep -E '^openjdk-[0-9]+-jdk$' | grep -oE '[0-9]+' | sort -n | uniq)
        fi

        if [[ -z $found_versions ]]; then
            msg_warning "无法自动获取仓库版本，使用预设列表..."
            local fallback_versions=("8" "11" "17" "21" "22" "23")
            for v in "${fallback_versions[@]}"; do
                if is_package_available "openjdk-$v-jdk"; then
                    found_versions="$found_versions $v"
                fi
            done
        fi

        for v in $found_versions; do
            available+=("$v")
            if [[ $v == "8" || $v == "11" || $v == "17" || $v == "21" || $v == "25" ]]; then
                display_names+=("OpenJDK $v LTS")
            else
                display_names+=("OpenJDK $v")
            fi
        done

        if [[ ${#available[@]} -eq 0 ]]; then
            msg_error "仓库中未找到任何openjdk-*-jdk包"
            return
        fi

        show_submenu "OpenJDK(APT)" "${display_names[@]}"

        local choice
        msg_prompt "请选择版本 [0-${#available[@]}, q退出]"
        
        if [[ $choice == "q" || $choice == "Q" ]]; then
            exit 0
        fi
        
        if [[ $choice == "0" ]]; then
            return 255
        fi

        if [[ $choice =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#available[@]} ]]; then
            local idx=$((choice - 1))
            install_openjdk_apt "${available[$idx]}"
            return
        else
            msg_error "无效选择"
        fi
    done
}

openjdk_mirror_menu() {
    while true; do
        show_submenu "OpenJDK(Mirror)" \
            "OpenJDK 11.0.2" \
            "OpenJDK 17.0.2" \
            "OpenJDK 21.0.1" \
            "OpenJDK 22.0.2" \
            "OpenJDK 23"

        local choice
        msg_prompt "请选择版本 [0-5, q退出]"
        case $choice in
            0) return 255 ;;
            q|Q) exit 0 ;;
            1) install_openjdk_mirror "11.0.2"; return ;;
            2) install_openjdk_mirror "17.0.2"; return ;;
            3) install_openjdk_mirror "21.0.1"; return ;;
            4) install_openjdk_mirror "22.0.2"; return ;;
            5) install_openjdk_mirror "23"; return ;;
            *) msg_error "无效选择" ;;
        esac
    done
}

install_openjdk_apt() {
    local version="$1"
    show_section "通过APT安装OpenJDK $version"

    local pkg_name="openjdk-${version}-jdk"

    if ! is_package_available "$pkg_name"; then
        msg_error "软件包 $pkg_name 在当前系统的APT仓库中不可用。"
        msg_info "请尝试执行 'apt update' 更新软件源或检查您的系统版本是否支持该版本。"
        return 1
    fi

    install_package "$pkg_name"
    if action "OpenJDK $version 安装成功" "安装失败"; then
        local jdk_path
        jdk_path=$(find "$JVM_INSTALL_BASE" -name "java-${version}-*" -type d 2>/dev/null | grep -v "common" | head -1)
        [[ -n $jdk_path ]] && configure_jdk_env "$jdk_path"
        return 0
    else
        return 1
    fi
}

install_openjdk_mirror() {
    local version="$1"
    show_section "从镜像安装OpenJDK ${version}"

    local filename="openjdk-${version}_linux-x64_bin.tar.gz"
    local url="${OPENJDK_MIRROR_BASE}/${version}/${filename}"
    local jdk_ver="jdk-${version}"

    install_manual_jdk_package "$url" "$filename" "$jdk_ver"
}

# ═══════════════════════════════════════════════════════════════
# JDK 环境配置
# ═══════════════════════════════════════════════════════════════

configure_jdk_env() {
    local jdk_path="$1"

    msg_info "正在配置系统 Alternatives..."
    local priority=100
    
    local bin
    for bin in "${JDK_BINARIES[@]}"; do
        if [[ -x "$jdk_path/bin/$bin" ]]; then
            sudo update-alternatives --install "/usr/bin/$bin" "$bin" "$jdk_path/bin/$bin" "$priority" >/dev/null 2>&1
            sudo update-alternatives --set "$bin" "$jdk_path/bin/$bin" >/dev/null 2>&1
        fi
    done

    cat > "$JDK_ENV_FILE" << 'EOF'
if [ -x /usr/bin/java ]; then
    export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
    export CLASSPATH=.:$JAVA_HOME/lib
fi
EOF

    export JAVA_HOME="$jdk_path"

    msg_info "环境变量文件已更新: $JDK_ENV_FILE"
}

# ═══════════════════════════════════════════════════════════════
# JDK信息收集(内部工具函数)
# ═══════════════════════════════════════════════════════════════

_collect_installed_jdks() {
    _JDK_NAMES=()
    _JDK_VERSIONS=()
    _JDK_PATHS=()
    _JDK_TYPES=()
    _JDK_CURRENT=()

    local current_java_path=""
    if command -v java &>/dev/null; then
        current_java_path=$(readlink -f "$(command -v java)" 2>/dev/null | sed 's:/bin/java::')
    fi

    if [[ -d $JVM_INSTALL_BASE ]]; then
        for jdk_dir in "$JVM_INSTALL_BASE"/*; do
            [[ -d $jdk_dir ]] || continue
            [[ -L $jdk_dir ]] && continue

            local name version jdk_type is_current

            name=$(basename "$jdk_dir")

            [[ $name == .* ]] && continue

            if [[ -x "$jdk_dir/bin/java" ]]; then
                local ver_output
                ver_output=$("$jdk_dir/bin/java" -version 2>&1)
                version=$(echo "$ver_output" | head -1 | grep -oP '"[^"]+"' | tr -d '"' || echo "unknown")
                if [[ $ver_output == *openjdk* || $ver_output == *OpenJDK* ]]; then
                    jdk_type="OpenJDK"
                else
                    jdk_type="OracleJDK"
                fi
            else
                version="N/A"
                if [[ $name == *openjdk* ]] || [[ $name == java-* ]]; then
                    jdk_type="OpenJDK"
                elif [[ $name == jdk* ]]; then
                    jdk_type="OracleJDK"
                else
                    jdk_type="其他"
                fi
            fi

            is_current="  "
            if [[ -n $current_java_path && "$jdk_dir" == "$current_java_path" ]]; then
                is_current="✔"
            fi

            _JDK_NAMES+=("$name")
            _JDK_VERSIONS+=("$version")
            _JDK_PATHS+=("$jdk_dir")
            _JDK_TYPES+=("$jdk_type")
            _JDK_CURRENT+=("$is_current")
        done
    fi

    while read -r line; do
        local pkg ver
        pkg=$(echo "$line" | awk '{print $2}')
        ver=$(echo "$line" | awk '{print $3}')

        [[ $pkg == *-jdk ]] && continue
        [[ $pkg != *-jre* ]] && continue

        if [[ $pkg == *-headless* ]]; then
            local main_pkg="${pkg/-headless/}"
            local already_has_main=false
            for existing in "${_JDK_NAMES[@]}"; do
                if [[ "$existing" == "$main_pkg"* ]]; then
                    already_has_main=true
                    break
                fi
            done
            [[ "$already_has_main" == "true" ]] && continue
        fi

        if [[ $pkg == openjdk* ]]; then
            local pkg_major
            pkg_major=$(echo "$pkg" | grep -oP '\-\d+\-' | tr -d '-')
            local is_redundant=false
            for existing in "${_JDK_NAMES[@]}"; do
                if [[ "$existing" == *"openjdk"* && "$existing" == *"$pkg_major"* ]]; then
                    is_redundant=true
                    break
                fi
            done
            [[ "$is_redundant" == "true" ]] && continue
        fi

        if [[ -n $pkg ]]; then
            _JDK_NAMES+=("$pkg")
            _JDK_VERSIONS+=("$ver")
            _JDK_PATHS+=("(apt)")
            _JDK_TYPES+=("APT")
            _JDK_CURRENT+=("  ")
        fi
    done < <(dpkg -l 2>/dev/null | grep -E "^ii.*(openjdk|oracle-java)")
}

# ═══════════════════════════════════════════════════════════════
# JDK管理 - 查看已安装JDK
# ═══════════════════════════════════════════════════════════════

_print_jdk_table() {
    local count=${#_JDK_NAMES[@]}
    
    local widths="6 10 28 14 30"
    msg_table_row "$widths" "${BOLD}${BRIGHT_CYAN}序号" "类型" "名称" "版本" "安装路径${NC}"
    draw_line "─"

    local i
    for ((i=0; i<count; i++)); do
        local marker=""
        if [[ "${_JDK_CURRENT[$i]}" == "✔" ]]; then
            marker="${BRIGHT_GREEN}★当前${NC}"
        fi

        local type_display
        case "${_JDK_TYPES[$i]}" in
            OracleJDK)  type_display="${BRIGHT_YELLOW}Oracle${NC}" ;;
            OpenJDK)    type_display="${BRIGHT_BLUE}OpenJDK${NC}" ;;
            APT)        type_display="${BRIGHT_MAGENTA}APT${NC}" ;;
            *)          type_display="${WHITE}${_JDK_TYPES[$i]}${NC}" ;;
        esac

        msg_table_row "$widths" "$((i+1))" "$type_display" "${_JDK_NAMES[$i]}" "${_JDK_VERSIONS[$i]}" "${_JDK_PATHS[$i]} $marker"
    done
}

list_installed_jdk() {
    show_section "已安装的JDK"

    _collect_installed_jdks

    local count=${#_JDK_NAMES[@]}

    if [[ $count -eq 0 ]]; then
        echo ""
        msg_warning "未检测到已安装的JDK"
        return
    fi

    echo ""
    _print_jdk_table
    echo ""

    if [[ -n ${JAVA_HOME:-} ]]; then
        msg_info "当前JAVA_HOME: ${BRIGHT_GREEN}${JAVA_HOME}${NC}"
    else
        msg_warning "未设置JAVA_HOME环境变量"
    fi

    if command -v java &>/dev/null; then
        msg_info "当前java:"
        java -version 2>&1 | sed 's/^/  /'
    fi
}

# ═══════════════════════════════════════════════════════════════
# JDK管理 - 切换JDK版本
# ═══════════════════════════════════════════════════════════════

switch_jdk() {
    show_section "切换JDK版本"

    _collect_installed_jdks

    local switchable_names=()
    local switchable_versions=()
    local switchable_paths=()
    local switchable_types=()
    local switchable_current=()

    local i
    for ((i=0; i<${#_JDK_NAMES[@]}; i++)); do
        if [[ -x "${_JDK_PATHS[$i]}/bin/java" ]]; then
            switchable_names+=("${_JDK_NAMES[$i]}")
            switchable_versions+=("${_JDK_VERSIONS[$i]}")
            switchable_paths+=("${_JDK_PATHS[$i]}")
            switchable_types+=("${_JDK_TYPES[$i]}")
            switchable_current+=("${_JDK_CURRENT[$i]}")
        fi
    done

    local count=${#switchable_names[@]}

    if [[ $count -eq 0 ]]; then
        echo ""
        msg_warning "未检测到可切换的JDK"
        return
    fi

    if [[ $count -eq 1 ]]; then
        echo ""
        msg_warning "仅安装了一个JDK，无需切换"
        msg_info "当前JDK: ${switchable_names[0]} (${switchable_versions[0]})"
        return
    fi

    local total_all=${#_JDK_NAMES[@]}
    local filtered=$((total_all - count))
    if [[ $filtered -gt 0 ]]; then
        echo ""
        msg_info "已过滤 ${filtered} 个不可切换的条目(JRE包、目录不完整等)"
    fi

    echo ""
    local widths="6 10 28 14"
    msg_table_row "$widths" "${BOLD}${BRIGHT_CYAN}序号" "类型" "名称" "版本" "状态${NC}"
    draw_line "─"

    for ((i=0; i<count; i++)); do
        local status_display
        if [[ "${switchable_current[$i]}" == "✔" ]]; then
            status_display="${BRIGHT_GREEN}当前${NC}"
        else
            status_display="${GRAY}--${NC}"
        fi

        local type_display
        case "${switchable_types[$i]}" in
            OracleJDK)  type_display="${BRIGHT_YELLOW}Oracle${NC}" ;;
            OpenJDK)    type_display="${BRIGHT_BLUE}OpenJDK${NC}" ;;
            *)          type_display="${WHITE}${switchable_types[$i]}${NC}" ;;
        esac

        msg_table_row "$widths" "$((i+1))" "$type_display" "${switchable_names[$i]}" "${switchable_versions[$i]}" "$status_display"
    done

    echo ""
    local choice
    msg_prompt "请选择要切换的JDK [1-${count}, 0取消]" "choice"

    if [[ $choice == "0" || -z $choice ]]; then
        msg_info "已取消"
        return
    fi

    if ! [[ $choice =~ ^[0-9]+$ ]] || [[ $choice -lt 1 || $choice -gt $count ]]; then
        msg_error "无效选择"
        return
    fi

    local idx=$((choice - 1))
    local target_path="${switchable_paths[$idx]}"
    local target_name="${switchable_names[$idx]}"

    if [[ "${switchable_current[$idx]}" == "✔" ]]; then
        msg_info "${target_name} 已经是当前活跃版本，无需切换"
        return
    fi

    msg_info "正在切换到: ${BRIGHT_GREEN}${target_name}${NC} (${switchable_versions[$idx]})"

    local binaries=("java" "javac" "keytool" "jar" "jarsigner")
    local switched=0
    for bin in "${binaries[@]}"; do
        if [[ -x "$target_path/bin/$bin" ]]; then
            sudo update-alternatives --install "/usr/bin/$bin" "$bin" "$target_path/bin/$bin" 200 2>/dev/null || true
            if sudo update-alternatives --set "$bin" "$target_path/bin/$bin" 2>/dev/null; then
                ((switched++))
            fi
        fi
    done

    if [[ $switched -eq 0 ]]; then
        msg_error "切换失败: 未能更新任何alternatives"
        return 1
    fi

    local env_file="/etc/profile.d/jdk.sh"
    cat > "$env_file" << 'EOF'
if [ -x /usr/bin/java ]; then
    export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
    export CLASSPATH=.:$JAVA_HOME/lib
fi
EOF

    export JAVA_HOME="$target_path"

    # shellcheck source=/dev/null
    [[ -f "$env_file" ]] && source "$env_file"

    echo ""
    msg_success "JDK已切换到: ${target_name}"
    echo ""

    msg_info "验证切换结果:"
    java -version 2>&1 | sed 's/^/  /'
    javac -version 2>&1 | sed 's/^/  /'
    msg_info "JAVA_HOME -> ${JAVA_HOME}"
}

# ═══════════════════════════════════════════════════════════════
# JDK管理 - 删除JDK环境
# ═══════════════════════════════════════════════════════════════

remove_jdk() {
    show_section "删除JDK环境"

    _collect_installed_jdks

    local count=${#_JDK_NAMES[@]}

    if [[ $count -eq 0 ]]; then
        echo ""
        msg_warning "未检测到已安装的JDK"
        return
    fi

    echo ""
    _print_jdk_table
    echo ""

    if [[ -n ${JAVA_HOME:-} ]]; then
        msg_info "当前JAVA_HOME: ${BRIGHT_GREEN}${JAVA_HOME}${NC}"
    fi

    echo ""
    msg_prompt "请选择要删除的JDK [1-${count}, 0取消]"

    if [[ $choice == "0" || -z $choice ]]; then
        msg_info "已取消"
        return
    fi

    if ! [[ $choice =~ ^[0-9]+$ ]] || [[ $choice -lt 1 || $choice -gt $count ]]; then
        msg_error "无效选择"
        return
    fi

    local idx=$((choice - 1))
    local target_name="${_JDK_NAMES[$idx]}"
    local target_path="${_JDK_PATHS[$idx]}"
    local target_type="${_JDK_TYPES[$idx]}"

    echo ""

    if [[ "${_JDK_CURRENT[$idx]}" == "✔" ]]; then
        msg_warning "你选择的是当前正在使用的JDK!"
    fi

    if [[ "$target_type" == "APT" ]]; then
        if confirm "确定卸载APT包 ${target_name}?"; then
            remove_package "$target_name"
            msg_success "APT包 ${target_name} 卸载完成"
        else
            msg_info "已取消"
        fi
    else
        if [[ -d $target_path ]]; then
            if confirm "确定删除 ${target_name} (${target_path}) 并清理系统链接?"; then
                local bin
                for bin in "${JDK_BINARIES[@]}"; do
                    sudo update-alternatives --remove "$bin" "$target_path/bin/$bin" 2>/dev/null || true
                done

                sudo rm -rf "$target_path"

                local remaining
                remaining=$(find "$JVM_INSTALL_BASE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
                if [[ $remaining -eq 0 ]]; then
                    [[ -f "$JDK_ENV_FILE" ]] && sudo rm -f "$JDK_ENV_FILE"
                    msg_info "已清理环境变量文件 (无剩余JDK)"
                fi

                msg_success "JDK ${target_name} 已删除"
            else
                msg_info "已取消"
            fi
        else
            msg_error "路径不存在: $target_path"
        fi
    fi
}

register_main_menu "配置JDK" "config_jdk"
