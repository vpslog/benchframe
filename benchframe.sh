#!/bin/bash

# 休息 1 秒
sleep 1
# 清屏操作
clear
# 打印开始信息
echo "测试脚本聚合框架 V1.0 by VPSLOG"
echo "Github：https://github.com/vpslog/benchframe"
echo "运行：bash <(curl https://raw.githubusercontent.com/vpslog/benchframe/main/benchframe.sh)"
echo  -e  "教程：https://blog.vpslog.org/blog/benchframe/\n"
# 记录脚本开始时间
start_time=$(date +%s.%N)

# 默认 copyright 为空字符串
COPYRIGHT=""

# 默认不使用 screen
USE_SCREEN=false

# 默认的 Telegram Bot Token、User ID 和 pastebin 链接
TELEGRAM_BOT_TOKEN=""
TELEGRAM_USER_ID=""
PASTEBIN_URL="https://pastebin.vpslog.org/"

# 全局计数器
counter=1

# 保存所有参数到变量
ALL_ARGS=("$@")

# 处理参数 -c、-d、-t、-u 和 -p
while getopts "c:dt:u:p:" opt; do
  case $opt in
    c) COPYRIGHT="$OPTARG";;
    d) USE_SCREEN=true;;
    t) TELEGRAM_BOT_TOKEN="$OPTARG";;
    u) TELEGRAM_USER_ID="$OPTARG";;
    p) PASTEBIN_URL="$OPTARG";;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
  esac
done

# 如果使用 screen，则启动 screen 会话并运行脚本
if [ "$USE_SCREEN" = true ]; then

  echo "安装 screen"
  # apt update > /dev/null 2>&1 && apt install screen -y > /dev/null 2>&1
  apt update && apt install screen -y
  echo "脚本已进入后台运行，请用 screen -r bench 命令查看运行状态，本窗口可以关闭"
  
  # 保存所有参数到变量，并从 ALL_ARGS 中去掉 -d 参数
  SCREEN_ARGS=("${ALL_ARGS[@]/-d}")

  # 下载 benchframe.sh
  curl -sL "https://raw.githubusercontent.com/vpslog/benchframe/main/benchframe.sh" > benchframe.sh

  # 使用 screen 运行 benchframe.sh，并传递所有参数
  screen -dmS bench bash -c "bash benchframe.sh ${SCREEN_ARGS[*]}"
  exit
fi

# 保存脚本执行结果的数组
script_outputs=()

# 函数定义：下载脚本到临时文件并执行替换操作
run_script() {
  local script_name="$1"
  local script_url="$2"
  local temp_file=$(mktemp)
  local output_file="${counter}_output.txt"
  local interactive_input="$3"

  echo "####### 执行 $script_name 脚本 #######"
  # 下载脚本到临时文件
  curl -sL "$script_url" > "$temp_file"

  # 替换 clear 命令
  sed "s/clear/ > \"$output_file\"/" -i "$temp_file"

  # 执行脚本，同时保存结果到文件
  if [ -n "$interactive_input" ]; then
    echo -e "$interactive_input" | bash "$temp_file" |  tee "$output_file"
  else
    bash "$temp_file" |  tee "$output_file"
  fi

  # 将 COPYRIGHT 的内容写入到输出文件
  echo "$COPYRIGHT" >> "$output_file"
  echo "$COPYRIGHT" 

  # 计数器递增
  ((counter++))

  # 添加输出文件到数组
  script_outputs+=("$output_file")
  
  # 删除临时文件
  rm "$temp_file"
}

# 执行所有脚本
run_script "基本测试" "https://bench.sh" 
run_script "GB5 测试" "https://bash.icu/gb5" "1\n"
run_script "三网测速" "https://bench.im/hyperspeed" '\n\n'
run_script "线路测试" "https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh"
run_script "流媒体解锁测试" "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh" "1\n"
run_script "回程路由测试" "https://raw.githubusercontent.com/vpslog/benchframe/main/besttarce.sh"
# 此脚本似乎有问题，不能自动退出
# run_script "https://raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh" '2\n'

# 提交结果，注意 cat 命令输出时包含了空字节（null byte），而 Bash 不支持在命令替换中处理空字节，使用 tr 命令来删除文件中的空字节
CONTENT=$(cat "${script_outputs[@]}" |  tr -d '\000' |  sed 's/\x1b\[[0-9;]*m//g')

# 提交结果并提取返回值，注意 \n 不能直接写，直接提交似乎会有问题
# 将内容保存到临时文件
echo -e "测试脚本聚合框架 by VPSLOG"$'\n'"Github：https://github.com/vpslog/benchframe"$'\n'"运行：bash <(curl https://raw.githubusercontent.com/vpslog/benchframe/main/benchframe.sh)"$'\n'"教程：https://blog.vpslog.org/blog/benchframe/"$'\n\n'"$CONTENT" > temp_result_file.txt

# 使用 curl 提交内容
RESULT=$(curl -Fc=@temp_result_file.txt "$PASTEBIN_URL")

# 删除临时文件
rm temp_result_file.txt

# 提取 url 和 admin 字段
URL=$(echo "$RESULT" | grep -o '"url": "[^"]*' | awk -F'"' '{print $4}')
ADMIN=$(echo "$RESULT" | grep -o '"admin": "[^"]*' | awk -F'"' '{print $4}')

# 记录脚本结束时间
end_time=$(date +%s.%N)

# 计算脚本执行时间（分和秒），bc 不支持小数点
duration_seconds=$(echo "$end_time - $start_time" | bc)
duration_seconds_rounded=$(printf "%.0f" "$duration_seconds")
duration_minutes=$((duration_seconds_rounded / 60))
duration_seconds_remainder=$((duration_seconds_rounded % 60))
echo "脚本执行时间: $duration_minutes 分 $duration_seconds_remainder 秒"
# 打印结果
echo "结果链接: $URL"
echo "修改或删除结果: $ADMIN"

# 如果设置了 TELEGRAM_USER_ID 和 TELEGRAM_BOT_TOKEN，则发送 Telegram 通知
if [ -n "$TELEGRAM_USER_ID" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  # 发送 Telegram 通知
  MESSAGE="聚合框架提醒您：脚本已全部执行完毕。用时 $duration_minutes 分 $duration_seconds_remainder 秒"$'\n'"结果链接: $URL"$'\n'"修改或删除结果: $ADMIN"
  curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    --data "text=$MESSAGE&chat_id=$TELEGRAM_USER_ID" > /dev/null
fi

#删除所有输出文件
rm "${script_outputs[@]}"
