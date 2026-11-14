# ImmortalWrt for FiberHome HG5585F (Enhanced Edition)

基于 **ImmortalWrt** 的烽火 HG5585F 光猫增强固件项目，源自 [luxinxin0378-create/an7581-HG5585-md-mf](https://github.com/luxinxin0378-create/an7581-HG5585-md-mf)。

## 🎯 项目特色

### 核心特性
- ✅ **PON 光口完整支持** — 集成 `naoki66/OpenWrt_ONU_CONFIG`（GPON/XGPON 认证、OMCI、光模块状态）
- ✅ **NPU 状态面板** — 集成 `naoki66/luci-app-airoha` 的 NPU/CPU/Frame Engine 监控
- ✅ **Vantage 主题** — 登录后实况首页（在线设备/速率/接口状态一览）
- ✅ **硬件加密加速** — EIP93 (AES/DES/authenc) + openssl-devcrypto
- ✅ **转发调优** — TCP 缓冲 16MB + conntrack 65536 + dnsmasq 缓存
- ✅ **RPS 多核转发** — 网卡软中断分散到 CPU1-3，缓解 PPE 未启用时的单核瓶颈
- ✅ **BBR 拥塞控制** — 跨境高延迟链路吞吐显著提升

### 设备支持

| 型号 | SoC | 内存 | 闪存 | 网口 | WiFi | PON |
|------|-----|------|------|------|------|-----|
| **HG5585F-CT** | AN7581 | 512MB | 512MB NAND | 1×2.5G(GPY211C) + 3×1G | ✅ MT7916D | ✅ EN7572 XGSPON |
| **HG5585F-CU** | AN7581 | 512MB | 512MB NAND | 4×1G | ✅ MT7916D | ✅ EN7572 XGSPON |
| XG-040G-MD | AN7581 | 1GB | 512MB NAND | 1×2.5G + 3×1G | ❌ | ✅ |
| XG-040G-MF | AN7583 | 1GB | 512MB NAND | 1×2.5G + 3×1G | ❌ | ✅ |

> **CT 与 CU 的区别**：CT 版 lan1 为独立 GPY211C 2.5G PHY，CU 版 lan1 走内部 PHY1（千兆）。LED 颜色 CT=蓝、CU=绿。

## 📦 固件特性

### 预装 LuCI 应用
- **PON 管理** — luci-app-onu、luci-app-pon-status（认证/业务/OMCI/DDM）
- **NPU 监控** — luci-app-airoha-npu（PPE 引擎状态、CPU 频率、温度）
- **网络工具** — luci-app-cpufreq
- **主题** — luci-theme-vantage + luci-app-vantage

### 技术亮点
3. **CPU 频率/温度显示** — 注入 `/sbin/cpuinfo`、`/sbin/tempinfo` + autocore ACL 授权
4. **USB 网卡驱动群** — 14 个 kmod-usb-net-*（asix/ax88179/cdc-eem/cdc-ether/cdc-mbim/cdc-ncm/cdc-subset/huawei-cdc-ncm/ipheth/rndis/rtl8150/rtl8152/sierrawireless），双 USB 口热插即用
5. **u-boot 源码镜像回退** — 上游站响应慢时自动切换 GitHub 镜像并重算校验值
6. **设备隔离校验** — 构建时断言目标机型符号确实被选中，避免编错设备

## 🚀 快速开始

### 默认配置
- **管理地址：** http://192.168.10.1
- **主机名：** OWRT
- **用户名：** root
- **密码：** root（首次登录后请修改）
- **WiFi SSID：** HG5585F-CT / HG5585F-CU（按机型命名）
- **WiFi 密码：** 88888888

### 刷写方法

**从原厂固件刷写：**
```bash
sysupgrade -F -n factory.bin
```

**从 OpenWrt/ImmortalWrt 升级：**
```bash
sysupgrade -n sysupgrade.bin
```

> ⚠️ **刷机前必须备份原厂分区，尤其是 `ri` 和 `bosa`**，否则无法恢复光模块校准与 MAC 地址。

### 固件命名规则
```
immortalwrt-<机型>-squashfs-enhanced-<YY.MM.DD>-<HH.MM.SS>.itb
```
示例：`immortalwrt-hg5585f-ct-squashfs-enhanced-26.11.14-12.51.52.itb`

- `<YY.MM.DD>` — 编译日期（北京时间）
- `<HH.MM.SS>` — 编译时刻（北京时间，精确到秒避免同日覆盖）

## 🛠️ 构建说明

### GitHub Actions 工作流

| 工作流 | 机型 | 说明 |
|--------|------|------|
| `build.yml` | HG5585F-CT + XG-040G-MD | 主线双机型构建，推送 config/scripts 自动触发 |
| `build-extra.yml` | HG5585F-CU + XG-040G-MF | 额外机型（CU 版 + AN7583 平台） |
| `build-opt.yml` | 全机型 | 优化构建（含 ccache 预热） |
| `build-usbwifi.yml` | HG5585F 系列 | USB WiFi 网卡支持版 |
| `build-xg040gmd-ubi-usb-sfp.yml` | XG-040G-MD | UBI-USB-SFP 变体 |

### 构建流程
```bash
# 1. Fork 本仓库
# 2. Actions → 选择工作流 → Run workflow
# 3. 等待 2-4 小时，Release 页面下载固件
```

### 本地构建（需要 50GB+ 磁盘）
```bash
# 安装依赖（Debian/Ubuntu）
sudo apt install -y build-essential clang flex bison g++ gawk \
  gettext git libncurses-dev libssl-dev python3 python3-dev \
  python3-setuptools rsync swig unzip zlib1g-dev file wget curl \
  libtool-bin libelf-dev device-tree-compiler ccache

# 准备并编译
bash scripts/prepare.sh hg5585f-ct fiberhome_hg5585f-ct
bash scripts/build.sh hg5585f-ct fiberhome_hg5585f-ct
```

## 📋 已知问题与说明

### PPE 硬件加速限制
本固件在 AN7581 上 **PPE 硬件加速仅对 GDM 口生效**（eth0 / lan1 / pon0）。若 WAN 接在 lan2/lan3/lan4（GSW 交换口），流量全部走 CPU 软件转发，测速时 CPU 占用会升高。将 WAN 改接 lan1 可启用硬件加速。

### ✅ 已解决问题
| 问题 | 原因 | 解决方案 |
|------|------|----------|
| CPU 频率/温度不显示 | LuCI ACL 仅授权部分 RPC | 引入 autocore 提供 RPC 授权声明 |
| ccache 不生效 | kconfig 可见性依赖 DEVEL | 改写 `Config-devel.in` 移除条件 |
| 编错设备 | profile 可能被 defconfig 丢弃 | 构建后断言设备符号存在 |
| Vantage 主题不生效 | 部分版本 mediaurlbase 残留 | uci-defaults 99- 兜底指向 vantage |

### ⚠️ 待验证
- [ ] PON 口光模块识别（需运营商 OLT 配合）
- [ ] NPU 加速在 lan1 上的实际性能
- [ ] USB WiFi 网卡兼容性

## 🏗️ 项目结构

| 文件 | 类型 | 说明 |
|------|------|------|
| `config/seed.config` | 上游同步 | 共用 .config 种子，每 3 天跟随上游 |
| `config/seed.config` (IP/主机名) | 🔒 自研 | 后台 192.168.10.1、主机名 OWRT |
| `config/overlay/sbin/` | 上游同步 | cpuinfo / tempinfo 状态页脚本 |
| `scripts/prepare.sh` | 上游同步 | 拉源码/feeds/定制/生成配置 |
| `scripts/build.sh` | 上游同步 | 下载+编译+收集产物 |
| `scripts/name-firmware.sh` | 🔒 自研 | 固件命名（编译日期+时间） |
| `.github/workflows/*.yml` | 部分自研 | Runner 固定 ubuntu-24.04 |
| `extra/*` | 上游同步 | 扩展机型构建脚本 |

> 自研部分：构建者标识 `build by chkdsk228`、主机名 OWRT、后台 IP 192.168.10.1、固件命名规则、CI runner 版本。

## 🙏 致谢

| 项目 | 作者 | 贡献 |
|------|------|------|
| [an7581-HG5585-md-mf](https://github.com/luxinxin0378-create/an7581-HG5585-md-mf) | luxinxin0378-create | **本项目直接上游** |
| [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) | immortalwrt | 上游固件 |
| [ponwrt](https://github.com/pbs05/ponwrt) | pbs05 | AN7581 PON 支持 |
| [OpenWrt_ONU_CONFIG](https://github.com/naoki66/OpenWrt_ONU_CONFIG) | naoki66 | PON 管理界面 |
| [luci-app-airoha](https://github.com/naoki66/luci-app-airoha) | naoki66 | NPU 状态面板 |
| [luci-theme-vantage](https://github.com/anothaDev/luci-theme-vantage) | anothaDev | Vantage 主题 + 实况面板 |

## 📜 许可证

- 固件代码：GPL-2.0
- CI 脚本：MIT
- 硬件文档：保留原作者版权

## 🔗 相关链接

- [ImmortalWrt 官方文档](https://immortalwrt.org/)
- [OpenWrt Wiki - AN7581](https://openwrt.org/toh/hwdata/airoha/airoha_an7581)
- [本项目上游](https://github.com/luxinxin0378-create/an7581-HG5585-md-mf)
- [姊妹项目：XG-040G-Enhanced](https://github.com/chkdsk228/ImmortalWrt-XG-040G-Enhanced)
