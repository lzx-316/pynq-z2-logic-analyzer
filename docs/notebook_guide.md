# PYNQ-Z2 逻辑分析仪 Notebook 使用说明

1. 准备工作：将 PYNQ-Z2 通过网线连接到电脑，把电脑网卡地址设到 192.168.2.x 网段，与板卡保持同一网段。
2. 启动板卡：插入已烧录 PYNQ 镜像的 SD 卡，上电后等待板卡指示灯常亮。
3. 打开浏览器：访问板卡地址 http://192.168.2.99:9090 ，若主机名已解析也可用 http://pynq:9090 ；若提示登录，用户名和密码均为 xilinx，部分环境免密直接进入。
4. 上传文件：把仓库中 pynq/logic_analyzer.bit 与 pynq/logic_analyzer.hwh 上传到板卡上的同一个目录，并且两个文件保持同名（基名 logic_analyzer），Overlay 加载时按该基名匹配，两个文件缺一不可。
5. 打开 Notebook：进入 notebooks 目录，双击 logic_analyzer_corrected.ipynb。
6. 加载覆盖层：运行第一个单元格，等待 Overlay 加载完成，确认打印出 IP 列表且没有报错。
7. 确认采集参数：采样率由 RTL 固定为 1 MSa/s（50 MHz ÷ 50 = 1 MHz），Notebook 内不提供采样率参数；缓冲深度固定 2048 点；PRE_TRIGGER 与 POST_TRIGGER 各 256 点，可按需修改，上限 1023。
8. 设置触发：TRIGGER_CH 取 0~3 对应 CH0~CH3；TRIGGER_MODE 取 0 上升沿、1 下降沿、2 任意边沿，共三种，不含电平触发。
9. 采集数据：先清状态再 arm，运行采集单元格等待 done 标志置位，然后按 trigger_ptr 读取 BRAM 数据并绘制波形图；正式演示优先把 TEST_MODE 置 1 使用内部测试计数作为激励，Pmod 外部输入不作必做项。
10. 保存结果：采集单元格会自动导出 logic_capture.csv，波形图用截图保存，Notebook 目前只自动保存 CSV，不会导出 PNG。
