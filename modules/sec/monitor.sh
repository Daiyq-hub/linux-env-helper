#!/usr/bin/env bash
#
# Copyright 2026 LinuxEnv Helper contributors
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
#  📝 模块描述 : 监控工具模块 (htop/btop/ncdu/glances/sysstat)
#  📁 文件路径 : modules/sec/monitor.sh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

config_monitor() {
    while true; do
        show_submenu "监控工具" \
            "安装监控工具(htop/btop/ncdu/glances/sysstat)" \
            "启动Glances Web监控" \
            "停止Glances Web监控"

        local choice
        msg_prompt "请选择操作 [0-3, q退出]"

        case $choice in
            0) return ;;
            q|Q) exit 0 ;;
            1) install_monitor_tools ;;
            2) start_glances_web ;;
            3) stop_glances_web ;;
            *) msg_error "无效选择" ;;
        esac

        pause
    done
}

install_monitor_tools() {
    show_section "安装监控工具"
    if ! install_packages htop btop ncdu glances sysstat iotop; then
        msg_error "安装失败，请检查网络或软件源"
        return 1
    fi
    msg_success "监控工具安装完成"
    msg_info "glances: 实时监控面板 | btop: 现代化 top | ncdu: 磁盘分析 | sysstat: 历史性能采集"
}

start_glances_web() {
    show_section "启动 Glances Web 监控"

    local glances_bin
    glances_bin="$(command -v glances || true)"
    if [[ -z "$glances_bin" ]]; then
        msg_error "未安装 glances，请先执行选项 1"
        return 1
    fi

    local port
    msg_prompt "请输入 Web 端口 [默认 61208]" "port"
    port="${port:-61208}"

    cat > /etc/systemd/system/glances-web.service << EOF
[Unit]
Description=Glances Web Server
After=network.target

[Service]
ExecStart=${glances_bin} -w -p ${port}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    enable_service glances-web || true
    start_service glances-web || true
    msg_success "Glances Web 已启动: http://$(hostname -I | awk '{print $1}'):${port}"
}

stop_glances_web() {
    show_section "停止 Glances Web 监控"
    stop_service glances-web || true
    disable_service glances-web || true
    msg_success "Glances Web 已停止"
}

register_main_menu "监控工具" "config_monitor"
