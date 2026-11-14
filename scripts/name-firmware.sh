#!/usr/bin/env bash
# 固件命名规则：
#   immortalwrt-<机型>-squashfs-enhanced-<YY.MM.DD>-<HH.MM.SS>.itb
#   实际示例：immortalwrt-hg5585f-ct-squashfs-enhanced-26.11.14-12.58.30.itb
#
#   - <前缀>    固定 immortalwrt（原始发行版名，符合 OpenWrt 官方命名习惯）
#               可用环境变量 FW_PREFIX 覆盖
#   - <机型>    如 hg5585f-ct / hg5585f-cu / xg-040g-md
#   - squashfs-enhanced  镜像类型标识（标明为增强版）
#   - <YY.MM.DD> 编译日期，北京时间 Asia/Shanghai
#   - <HH.MM.SS> 编译时刻，北京时间 Asia/Shanghai，精确到秒避免同日构建覆盖
#
# 用法：source 本文件后调用 firmware_basename <机型>
firmware_basename() {
  local model="${1:?缺少机型名}"
  local prefix
  prefix="${FW_PREFIX:-immortalwrt}"
  local stamp
  stamp="$(TZ=Asia/Shanghai date +%y.%m.%d-%H.%M.%S)"
  printf '%s-%s-squashfs-enhanced-%s' "$prefix" "$model" "$stamp"
}
