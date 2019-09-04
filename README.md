# ahk-context-cmd
> 效率工具，快捷命令助手，快速跳转界面、执行命令


### 使用方法
1. 鼠标中键唤出输入框，输入命令
2. 双击右侧Ctrl唤出输入框，输入命令
3. 监听``之间输入的命令
4. 自定义命令: 图标右键->修改菜单-> 新增\编辑\删除\保存命令树


### 特点
1. 任意界面，例如在桌面下，键盘输入`calc`, 即使看不到输入，也可以执行
2. 当找不到匹配命令, 则从匹配列表中选择第一个命令来执行 eg:[g ah ==> 执行g ahk] [ca ==> 执行calc]
3. 匹配桌面壁纸的主题 \ AeroGlass全透明主题



### 演示
|监听命令和配置界面|auto模式主题|
|-|-|
|<img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo.gif"/><br><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo.png"/>|<img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo2.png"/><br><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo3.png"/><br><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo4.png"/>|



### 命令类别
|起始值|说明|实例|
|-|-|-|
|g|快捷跳转命令|g baidu|
|get|快捷复制命令|get date|
|q|qq联系人跳转||
|do|综合性处理命令|do laji|
|-|内建命令：<br>-theme 切换主题<br>-tree 编辑命令树<br>-history 历史命令<br>-clearCache 清除缓存<br>-reload 重启脚本<br>-quit 关闭界面<br>-exit 退出脚本|-theme auto|
|其他|系统环境变量路径中所定义系统级命令、快捷方式|calc<br>notepad|


### 输入框快捷键
|界面|快捷键|作用|
|-|-|-|
|总界面|F1键|打开命令树管理|
|总界面|Esc键|关闭|
|候选列表|Up\Down键|在输入框\候选命令列表上下移动|
|候选列表|Right键|将当前选中的命令复制到输入框中|
|输入框|Tab键|将候选列表中第一个结果复制到输入框中|



### 主题说明
|模式|说明|
|-|-|
|auto|默认，根据系统当前壁纸配置颜色, 窗口位置中间[调用命令行工具imagemagick-convert.exe]|
|blur|AeroGlass风格, 由于在偏白色背景下无法看清文字, 因此位置放置在左下角|
|custom|配置的固定几种颜色风格, 每次展示时随机颜色风格, 窗口位置中间|
|random|随机以上几种模式|


### TODO
1. 对第二层级命令进行提示[g ziliao mobile]中的mobile
2. 每周五展示历史输入命令排行榜[前二十]；创建内部指令统计当前命令hitting次数排行榜
3. 新增命令属性[窗口类型], 取值[min max normal hide], 默认值为normal; 此时修改删除临时变量execWinMode
4. 新顶级命令 => c 代码片段读取    参考项目[ahk-context-code](https://github.com/bjc5233/ahk-context-code)      需要支持第二层级命令提示
5. 脚本在启动时会将系统path目录中的所有命令及其注释保存到DB，但命令可能会被修改(如bat标题、lnk备注信息)。因此需要DB记录命令的修改时间，脚本启动后检查命令时间是否有变化，有则更新
6. 提升命令匹配速度



### 其他
1. 项目整合替代了[g.bat](https://github.com/bjc5233/batch-shortcut-go)、[get.bat](https://github.com/bjc5233/batch-shortcut-get)、[q.bat](https://github.com/bjc5233/batch-shortcut-qq)、do.bat
2. 项目自带数据库ContextCmd.db，是本人日常生活中所使用的(没有敏感命令)
3. 项目自带事例命令中有使用bat脚本, 其中少量会需要第三方exe文件
4. 当命令命中次数到达阀值[ICBCmdHitThreshold\ICBSystemCmdHitThreshold], 将重新构建ICB变量, 使得命中次数多的命令可以在匹配结果中更加靠前
5. 在配置命令的[执行]文本框中, 首行可配置信息:
``` 
::execLang=bat execWinMode=hide
bat注释  将脚本保存为.bat文件  脚本执行时隐藏窗口

;execLang=ahk
ahk注释  将脚本保存为.ahk文件
```
6. DB表结构变更: 
```
cmd.cmd->cmd.name; cmd.name->cmd.desc
historyCmd.cmd->historyCmd.name; historyCmd.name->historyCmd.desc
```