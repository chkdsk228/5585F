#!/usr/bin/env bash
# 固件命名规则（与 ImmortalWrt-XG-040G-Enhanced 项目保持一致）：
#   immortalwrt-<机型>-squashfs-enhanced-R<NN>-B<YY>-<月>-<日>.itb
#   实际示例：immortalwrt-hg5585f-ct-squashfs-enhanced-R01-B26-11-14.itb
#
#   - <前缀>    默认 immortalwrt（原始发行版名，符合 OpenWrt 官方命名习惯）
#               可用环境变量 FW_PREFIX 覆盖
#   - <机型>    如 hg5585f-ct / hg5585f-cu / xg-040g-md
#   - squashfs-enhanced  镜像类型标识（沿用 Enhanced 项目风格，标明为增强版）
#   - R<NN>     两位版本号，从 R01 起每轮构建递加；数值来自 config/REVISION
#               （每次发版前把该文件数字 +1），也可用 FW_REV 临时指定
#   - B<YY>     批次号（默认 B26 = 2026 年度批次），可用 FW_BATCH 覆盖
#   - <月>-<日> 构建当天日期，北京时间 Asia/Shanghai，两位补零
#
# 用法：source 本文件后调用 firmware_basename <机型> <REVISION 文件路径>
firmware_basename() {
  local model="${1:?缺少机型名}"
  local revfile="${2:?缺少 REVISION 文件路径}"
  local prefix batch rev mmdd
  prefix="${FW_PREFIX:-immortalwrt}"
  batch="${FW_BATCH:-B26}"
  rev="${FW_REV:-}"
  if [ -z "$rev" ]; then
    rev="$(tr -dc '0-9' < "$revfile" 2>/dev/null || true)"
  fi
  [ -n "$rev" ] || rev=1
  mmdd="$(TZ=Asia/Shanghai date +%m-%d)"
  printf '%s-%s-squashfs-enhanced-R%02d-%s-%s' "$prefix" "$model" "$rev" "$batch" "$mmdd"
}
