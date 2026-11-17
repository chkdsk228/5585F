# 5585F 固件规格书

> **文档定位**：本文件的唯一目的，是让每一次改动都能**二值判定**——符合规格 / 不符合规格。
> 有了它，后续改动不再需要「试探 → 观察 → 再试探」的循环。
>
> 维护原则：改动代码前先改这份文件；代码与文件不一致时，以文件为准并修正代码。

---

## 1. 目标设备（事实基线）

| 项 | HG5585F-CT | HG5585F-CU |
|---|---|---|
| SoC | Airoha AN7581 / EN7581 | 同 CT |
| 内存 | 512 MiB | 同 CT |
| 闪存 | 512 MiB 并行 NAND（TSOP48，128K块/2048B页） | 同 CT |
| WiFi | MT7916D（双 PCIe HIF：主口 PCIe1 `14c3:7906`） | 同 CT |
| LAN | lan1=GPY211C 2.5G（GDM），lan2/3/4=内部 PHY 1G（GSW） | lan1-4 全部内部 PHY 1G（GSW） |
| USB | 双口（usb0/usb1） | 同 CT |
| 光口 | EN7572 xPON + BOSA（I2C 0x51） | 同 CT |
| 引导 | 出厂 UBI 直刷 | 同 CT |
| LED | 蓝 | 绿 |

**硬件约束（影响功能决策）**：

- PPE 硬件加速只对 **GDM 口**（eth0 / lan1 / pon0）生效。WAN 若接 lan2-4（GSW 交换口），流量全部走 CPU。
- 无 SATA / NVMe 接口 → 本机不可能挂内置硬盘。
- 无风扇 → 无风扇控制需求。

---

## 2. 功能清单

### 2.1 必须有（MUST）

缺失即视为构建失败。

| 域 | 包 / 配置 | 理由 |
|---|---|---|
| **目标平台** | `CONFIG_TARGET_airoha` / `CONFIG_TARGET_airoha_an7581` / `CONFIG_TARGET_ROOTFS_SQUASHFS` | 基础 |
| **PON 光口** | `kmod-airoha-xpon`、`kmod-airoha-pon-frontend`、`kmod-airoha-paged-bosa`、`airoha-ponctl`、`airoha-pond`、`airoha-pon-debug`、`luci-app-onu`、`luci-app-pon-status` | 设备是光猫，PON 是核心职能，缺此设备无意义 |
| **NPU** | `airoha-en7581-npu-firmware`、`luci-app-airoha-npu` | 固件包是 NPU 微码来源；面板用于观察 PPE 加速是否生效 |
| **WiFi** | `kmod-mt7915e`、`kmod-mt7916-firmware`、`wpad-openssl` | 硬件自带，不用即浪费 |
| **硬件加密** | `kmod-crypto-hw-eip93`、`kmod-cryptodev`、`openssl-util`、`libopenssl-devcrypto` | SoC 自带 EIP93 引擎，启用后 TLS/VPN 不占 CPU |
| **LuCI 基础** | `luci`、`luci-compat`、`luci-i18n-base-zh-cn`、`CONFIG_LUCI_LANG_zh_Hans` | Web 是主交互界面；中文为默认语言 |
| **状态页数据** | `autocore` + `config/overlay/sbin/{cpuinfo,tempinfo}` | autocore 提供 RPC ACL 授权；两个脚本是数据源。缺 autocore 则温度/频率行整行消失；缺脚本则有授权无数据 |
| **基础系统** | busybox / procd / netifd / firewall4 / dnsmasq-full / dropbear / uhttpd（由 target 与 luci 依赖链自动带入） | 启动与联网前提 |

### 2.2 可选（MAY，当前全部启用）

| 域 | 内容 | 当前状态 | 移除代价 |
|---|---|---|---|
| **Vantage 主题** | `luci-theme-vantage`、`luci-app-vantage` | ✅ 启用（默认主题） | 退回 bootstrap，界面变为默认样式 |
| **USB 网卡驱动群** | 14 个 `kmod-usb-net-*` | ✅ 启用 | 无法使用 USB 2.5G 网卡 / 手机共享网络 |
| **系统诊断工具** | `zram-swap`、`usbutils`、`curl`、`iperf3`、`htop`、`coremark` | ✅ 启用 | 无 swap 保护、无法 lsusb 验证、测速不便 |
| **CPU 调频** | `luci-app-cpufreq` | ✅ 启用 | 无法调频 |
| **BBR** | `kmod-tcp-bbr` | ✅ 启用 | 高延迟链路吞吐下降 |
| **USB-SFP 变体** | 编译 `hg5585f-ct-usb-sfp` / `-cu-usb-sfp` | ⚠️ 当前**未编译**（仅主 variant） | 若机器带 SFP 插槽则无法使用 |

### 2.3 明确排除（MUST NOT）

以下内容**不得**出现在固件中。移除理由经实测验证。

| 类别 | 具体包 | 体积 | 排除理由 |
|---|---|---|---|
| **QModem 4G/5G 全家桶** | `qmodem`、`luci-app-qmodem-next`、`qfirehose`、`modem_scan`、`umbim`、`wwan`、`kmod-mtk-t7xx` 等 19 包 | ~12–15 MB | 不使用蜂窝模组 |
| **Ruby 运行时** | `ruby` + 12 个 `ruby-*` + `libyaml`/`lyaml` | （含上项） | QModem 的依赖，随 QModem 一起排除 |
| **Passwall + Xray** | `luci-app-passwall`、`xray-core`、`sing-box`、`shadowsocks-rust-*`、`haproxy`、`chinadns-ng` 等 13 包 | ~25–30 MB（xray 单项） | 不使用代理 |
| **OpenClash + Mihomo** | `luci-app-openclash` + 注入 `/etc/openclash/core/clash_meta` | ~18–20 MB | 不使用代理 |
| **Aurora 主题** | `luci-theme-aurora`、`luci-app-aurora-config` | ~1 MB | 主题只保留 Vantage 一个，避免选择困难 |
| **Aurora 之外的额外主题** | fluent / footstrap / kucat / shadcn | — | 同上 |
| **NAS / 存储类** | `kmod-fs-btrfs`、`kmod-fs-ksmbd`、`kmod-nvme`、`nvme-cli`、`automount`、`luci-app-samba4` | ~4 MB | 设备无 SATA/NVMe；不充当 NAS |
| **硬盘健康检测** | `smartmontools`、`smartmontools-drivedb` | ~400 KB | 无 SATA/NVMe 接口，工具无对象 |
| **iStore 商店生态** | `luci-app-store`、`luci-app-istorex`、`luci-app-quickstart`、`taskd` 等 | ~3 MB | 与 Vantage 实况首页定位重复 |
| **KMS 激活** | `vlmcsd`、`luci-app-vlmcsd` | ~1 MB | 无 Windows 批量激活需求 |

### 2.4 自研定制（不属于上游，必须保留）

| 项 | 实现位置 | 当前值 |
|---|---|---|
| 构建者标识 | `scripts/prepare.sh` → `99-build-mark` | `build by chkdsk228` |
| 设备主机名 | `scripts/prepare.sh` → `99-hostname` | `OWRT` |
| 后台地址 | `scripts/prepare.sh` → `99-lan-ip` | `192.168.10.1` |
| 默认主题 | `scripts/prepare.sh` → `99-lang-theme` | `vantage` |
| 固件命名 | `scripts/name-firmware.sh` | `immortalwrt-<机型>-squashfs-enhanced-<YY.MM.DD>-<HH.MM.SS>.itb` |
| CI runner | 全部 workflow | `ubuntu-24.04`（上游已同） |

---

## 3. 体积预算

| 段 | 基线值 | 说明 |
|---|---|---|
| FIT 头 + DTB | ~0.05 MB | 固定 |
| kernel | ~5.45 MB | 由 target 决定，不可调 |
| rootfs（xz） | 当前 10.06 MB | 由包集合决定 |
| **合计** | **当前 16.3 MB** | |

**预算区间**：**16 – 22 MB**

- 下限 16 MB：低于此值说明 MUST 项缺失，需立即排查
- 上限 22 MB：超过此值说明引入不该有的包（通常是大体积 Go/Rust 静态二进制），需审查

**参考锚点**（用于快速判断体积是否异常）：

| 场景 | 实测 | 说明 |
|---|---|---|
| 本规格（MUST + 2.2 全部） | ~16.3 MB | run#3 实测 |
| 加 USB-SFP 变体 + SFP 驱动 | ~17 MB | 预估 |
| 上游正式版（含代理 + QModem） | 83.5 MB | 差 67 MB，全部来自被排除的三大件 |
| 原始上游（VIKINGYFY 模板，90 包工具全量） | 31–34 MB | 差 ~16 MB |

> **判据**：体积异常只查两件事——(a) MUST 项是否齐（用第 4 节验收）；(b) 是否混入了 2.3 排除项。
>
> **警戒线**（比区间更严格，用于主动发现异常）：
> - **< 15 MB** → 极大可能 MUST 项缺失，立即排查
> - **> 19 MB** → 疑似混入排除项（大体积 Go/Rust 二进制），审查包清单
> - **15 – 19 MB** → 正常波动区间

---

## 4. 验收清单

构建成功后**必查**；刷机后**抽查**。

### 4.1 构建期（自动化，prepare.sh 强制校验）

| 检查 | 实现 | 失败行为 |
|---|---|---|
| `.config` 含全部 MUST 包 | `prepare.sh` 的 `for p in ...; do grep -q "^CONFIG_PACKAGE_${p}=y$"` | `::error::` + `exit 1` |
| 目标设备符号被选中 | 同上（`CONFIG_TARGET_airoha_an7581_DEVICE_<profile>=y`） | `exit 1` |
| 无 QModem/Passwall/OpenClash 残留 | **当前未实现** → 见 7.2 | — |
| 固件体积在预算区间 | **当前未实现** → 见 7.2 | — |

### 4.2 产物期（构建后，人工或脚本解包验证）

| 检查项 | 验证方法 | 期望 |
|---|---|---|
| 固件存在 | artifact 有 `.itb` | 存在 |
| 体积 | 文件大小 | 16–22 MB |
| rootfs 包数 | 解包查 `lib/apk/packages/*.list` | ≈ 250 个 |
| kernel 段大小 | FIT 解析 | ≈ 5.45 MB |
| **禁止项未混入** | 解包 grep `xray-core`/`qmodem`/`openclash` | 无 |

### 4.3 刷机后（现场抽查）

| 检查项 | 命令 | 期望 |
|---|---|---|
| 系统版本 | `cat /etc/openwrt_release` | ImmortalWRT SNAPSHOT |
| 主机名 | `uci get system.@system[0].hostname` | `OWRT` |
| 后台地址 | 浏览器访问 | `http://192.168.10.1` |
| 主题 | LuCI 界面 | Vantage |
| PON 口 | `ip link show pon0` | 存在 |
| NPU 固件 | `dmesg \| grep "NPU fw"` | 有版本号 |
| NPU 面板 | LuCI → NPU | 能打开，有数据 |
| WiFi | `iwinfo` | 有 radio |
| USB 网卡 | 插入后 `lsusb` + `ip link` | 能识别 |
| 温度/频率 | LuCI 概览页 | 有数值（非 N/A） |
| 加密引擎 | `dmesg \| grep eip93` | 已注册 |

---

## 5. 变更规则（影响面分级）

按改动的影响面决定流程深度。

### 5.1 分级标准

| 级别 | 判定条件 | 流程 |
|---|---|---|
| **L1 低** | 只增删 `seed.config` / `seed-extra.config` 中的包项；不改脚本逻辑。**注意：seed.config 被 3 条构建线共用，seed-extra 被 2 条共用（见 §7.7）** | 直接改 → 更新本文件 §2 → 提交 |
| **L2 中** | 改 `prepare.sh` / `build.sh` 逻辑；改 workflow；改依赖链 | 给 2 版方案 → 改 → 构建验证 → 更新本文件 |
| **L3 高 / 不可逆** | 换上游；改镜像格式或分区；改 `DEVICE_PACKAGES`；改命名规则 | 给 3 版方案 + 回滚步骤 → 先在 TEST 模式验证 → 再正式构建 |

### 5.2 每次改动必须回答的四问（对应规则 4）

1. **直接效果**：这次改动解决了什么？
2. **二阶影响**：会影响哪些其他包 / 脚本 / workflow？
3. **三阶影响**：对后续上游同步、维护成本、故障排查难度有什么影响？
4. **回滚方式**：怎么退回去？

### 5.3 上游同步规则

- 上游改动**先读再合**，不无脑 `merge`
- 与本规格 §2 / §2.4 冲突的，**保留本规格**
- 上游新增的**能力**（如新的构建变体、新修复）默认吸收，但需评估体积与功能影响

---

## 6. 与上游的关系

**当前上游**：`luxinxin0378-create/an7581-HG5585-md-mf`

| 项 | 上游 | 本仓库 | 分歧性质 |
|---|---|---|---|
| 构建架构 | 多 variant（build / build-opt / build-extra / build-usbwifi / xg040gmd-ubi-usb-sfp / **build-personal**） | 同结构，但**未启用 personal** | 上游新增能力，本仓库未跟进 |
| runner | `ubuntu-24.04` | `ubuntu-24.04` | ✅ 已一致 |
| 固件命名 | `R<NN>-B<YY>-月-日`（依赖 `config/REVISION`） | `<YY.MM.DD>-<HH.MM.SS>`（**已删除 REVISION**） | ⚠️ **永久分歧**，见 7.3 |
| 包集合 | 29 包（含 QModem/Passwall/OpenClash/Aurora） | 38 包（排除三大件，加 USB/工具/Vantage） | 有意分歧 |
| 主题 | Aurora | Vantage | 有意分歧 |

**历史包袱（规则 7 考古结论）**：

| 遗留 | 来源 | 现状 | 处置建议 |
|---|---|---|---|
| VIKINGYFY CI 模板（`WRT-CORE.yml`、`Config/*.txt`、`Scripts/*.sh`） | 第一代（`zk6685` fork 链） | 已于 `b3b7440` 整体移除 | ✅ 已清理 |
| `docs/donate.png` / 赞赏码 | 原作者（zk6685） | 已移除 | ✅ 已清理 |
| v2ray-geoip/geosite | 早期 honk 代理依赖 | 已移除 | ✅ 已清理 |
| QModem / Passwall / OpenClash | 第二代上游（`luxinxin0378`）默认项 | 已排除 | ✅ 已清理 |
| `config/REVISION` | 第二代上游命名机制 | 本仓库已删除 | ⚠️ 见 7.3 |

---

## 7. 待决问题

> 以下问题需要明确决策后才能收敛。**未决策前，相关改动不应实施。**

### 7.1 `i2c-tools` 是否加回？

- **矛盾点**：HG5585F 的光模块 BOSA 挂在 I2C-0 @0x51，`i2c-tools` 可直接读写光模块寄存器（诊断收光功率、温度、告警）。上游已包含此项。你在「去掉 4/6/8」时把它移除了。
- **代价**：约 30 KB。几乎可忽略。
- **需要你确认**：移除是「明确不要」，还是「当时顺手一起删了」？

### 7.2 是否增加两道自动闸门？

当前 `prepare.sh` 只校验「MUST 项存在」，**不校验「排除项不存在」和「体积不超预算」**。建议增加：

```bash
# 闸门 A：排除项不得混入
for p in xray-core qmodem luci-app-openclash luci-app-passwall luci-theme-aurora; do
  grep -q "^CONFIG_PACKAGE_${p}=y$" .config && { echo "::error::禁止项混入: $p"; exit 1; }
done

# 闸门 B：体积预算
SZ=$(stat -c%s output/*/*.itb)
[ "$SZ" -gt 23068672 ] && { echo "::error::超出体积预算(22MB): $SZ"; exit 1; }
```

- **代价**：约 15 行代码；构建失败时会明确报出原因。
- **风险**：闸门 B 若阈值过严，可能在合理扩展时误伤。
- **需要你确认**：是否启用？

### 7.3 固件命名是否回归上游的 `R<NN>`？

- **现状**：你要求「去掉末尾无意义字母数字组合，改为编译日期时间」，已实施。
- **代价**：`name-firmware.sh` 与上游永久分歧，每次同步都会冲突，需手工解冲突。
- **反方观点**（规则 6）：`R<NN>` 并非无意义——它是**单调递增的发布序号**，能一眼判断哪个包更新，且比时间戳短。时间戳的独特优势是「精确到秒，避免同日覆盖」，但 `R<NN>` 靠手工 +1 也能做到（只是依赖纪律）。
- **折中方案**：保留时间戳命名，但在 `README.md` 里记录「命名与上游不同」这一事实，降低未来同步时的困惑。
- **需要你确认**：维持时间戳，还是回归 `R<NN>`？

### 7.4 USB-SFP 变体是否编译？

- **现状**：`build.yml` 矩阵只有 `hg5585f-ct` 和 `xg-040g-md`，**未编译** `hg5585f-ct-usb-sfp` / `-cu-usb-sfp`。
- **需要你确认**：你的机器是标准 CT（3 网口 + PON），还是带 SFP 插槽的变体？若是后者，需要加入矩阵。

### 7.5 WAN 口位置（影响 NPU 加速）

- **现状**：实测你的 WAN 接在 **lan4（GSW 交换口）**，因此 PPE 无法接管，全部 CPU 软件转发。
- **若要 NPU 生效**：需把 WAN 改接 **lan1（GPY211C 2.5G GDM 口）**，并改 `network.wan` 的 device。
- **需要你确认**：是否愿意换网口位置？这属于物理部署决策，不在固件层面。

### 7.6 `build-usbwifi.yml` 是僵尸 workflow（已发现，待处置）

**实测确认的坏引用**：

| 检查项 | 结果 |
|---|---|
| 本仓库 `config/seed-usbwifi.config` | ❌ 不存在 |
| 上游同文件 | ❌ 也不存在（上游 `config/` 仅有 `REVISION`、`overlay/`、`seed.config`） |
| `build-usbwifi.yml:57` | `SEED_FILE: ${{ github.workspace }}/config/seed-usbwifi.config` |
| `prepare.sh:305` | `cat "$SEED"` → 文件不存在即报错退出 |
| 触发方式 | 仅 `workflow_dispatch`（手动）→ **一直没人踩到** |

**结论**：该 workflow 一经手动触发必然立即失败。属于上游遗留的历史包袱。

**三个处置选项**：

| 选项 | 做法 | 优点 | 缺点 |
|---|---|---|---|
| **A. 删除**（推荐） | 移除 `build-usbwifi.yml` | 消除死代码，减少困惑 | 若将来要 USB WiFi 需重建 |
| **B. 补文件** | 创建 `config/seed-usbwifi.config` | 功能可用 | 需定义其内容；上游同步时会反复冲突 |
| **C. 保持原样** | 不动 | 零成本 | 保留一个永远失败的入口，违背规格「二值判定」原则 |

**需要你确认**：选哪个？

### 7.7 各 workflow 的 seed 归属（二阶影响矩阵）

实测各 workflow 使用的配置来源，用于评估「改 seed.config 会影响谁」：

| Workflow | 目标机型 | 使用的 seed / 脚本 | 受本仓库改动影响 |
|---|---|---|---|
| `build.yml` | hg5585f-ct、xg-040g-md | `scripts/prepare.sh` + `config/seed.config` | ✅ 是（主路径） |
| `build-extra.yml` | hg5585f-cu、xg-040g-mf | `extra/prepare-extra.sh` + `extra/seed-extra.config` | ✅ 是 |
| `build-opt.yml` | 4 机型（ct/md/cu/mf） | **两者都用**（extra 覆盖 + 主线） | ✅ 是（双路径） |
| `build-usbwifi.yml` | xg-040g-md | `config/seed-usbwifi.config` → **不存在** | ❌ 无法运行（见 7.6） |
| `build-xg040gmd-ubi-usb-sfp.yml` | xg-040g-md | `scripts/prepare.sh` + 默认 `seed.config` | ✅ 是 |

> **关键推论**：改动 `seed.config` 会同时影响 **build / build-opt / xg040gmd-ubi-usb-sfp** 三条线；改动 `seed-extra.config` 会影响 **build-extra / build-opt**。因此任何 L1 级改动实际影响面是 **3–5 条构建线**，不应按「小改动」轻率处理。

---

### 7.8 本规格书自身的局限（反方校验结论）

诚实标注这份文件**做不到**什么，避免高估它的价值：

| 局限 | 后果 | 缓解方向 |
|---|---|---|
| **目前是纯文档，不可执行** | §4.1 的「禁止项校验」「体积预算」尚未实现，改动仍可能悄悄违规 | 实现 §7.2 的两道闸门后，才真正具备二值判定能力 |
| **不覆盖运行时状态** | 刷机后配置漂移（如手工改 UCI）不在规格约束内 | 接受；这是运维范畴 |
| **§2.2「可选」定义模糊** | 某包当前启用但被列为可选，删除它算不算违规无定论 | 需为每个可选项标注「已决策启用 / 可随时移除」 |
| **不定义回滚流程** | 出问题时无标准退路 | 依赖 git revert + 上一版 artifact；§5.2 Q4 要求每次改动自行说明回滚方式 |
| **待决问题未收敛** | §7 有 6 项待决，SPEC 尚属 v0.9 | 逐项决策后升为 v1.0 |

> **本文件的正确定位**：不是「已完成的质量保证体系」，而是「把隐性预期显性化、为后续自动化闸门提供判据」的**中间产物**。

## 8. 变更记录

| 日期 | 提交 | 内容 |
|---|---|---|
| 2026-11-14 | `b3b7440` | 切换上游为 `luxinxin0378-create`，按新结构重整 |
| 2026-11-14 | `f7673a2` | 移除 QModem/Passwall/OpenClash，Vantage 主题，命名改时间戳 |
| 2026-11-14 | `3e5e230` | 补回 USB 网卡驱动群 14 个 |
| 2026-11-14 | `7b9dea6` | 补入系统诊断工具 6 个 |
| 2026-11-17 | — | 建立本规格书 |
