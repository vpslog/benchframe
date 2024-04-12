#!/bin/bash

# 执行安装命令
bash <(curl -Ls https://raw.githubusercontent.com/sjlleo/nexttrace/main/nt_install.sh)

# 等待一段时间，确保安装完成

# 运行程序 nexttrace，并模拟输入 1，回车，6，回车
echo -e "1\n6\n" | nexttrace -T -F
