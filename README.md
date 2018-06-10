# ahk-context-cmd
> 效率工具，上下文环境命令助手, 方便快速执行命令、跳转界面


### 启用方式
1. 监听``之间输入的命令 {在任何环境下都可以检测到【输入框\桌面】}
2. 双击Ctrl弹出输入框，输入命令

### 配置说明
1. 图标右键->修改菜单-> 新增\编辑\删除\保存命令树
```
 => g.bat 快捷跳转命令
 => get.bat 快捷复制命令
 => q.bat qq联系人跳转
 => do.bat
 => 其他系统级别的命令、快捷方式 【calc notepad...】
```


### 主题说明
 1. auto模式(默认), 根据系统当前壁纸配置颜色, 窗口位置中间【需要第三方命令行工具imagemagick-convert.exe】
 2. blur模式, AeroGlass风格, 由于在偏白色背景下无法看清文字, 因此位置放置在左下角
 3. custom模式, 配置的固定几种颜色风格, 每次展示时随机颜色风格, 窗口位置中间



### 特点
1. 任意界面，即使是桌面下，完全看不到输入，也可以执行
2. 花费时间少。相比之下手动寻找快捷方式并点击，花费的时间最长；而使用运行\启动器需要打开界面，输入命令，回车，才执行命令
3. 自动根据系统壁纸主色调配置输入框颜色 \ AeroGlass主题


### 更新
* 2018-06-11  1:19:57 增加搜索栏主题颜色
* 2018-05-29 16:54:53 最初版本

### TODO
1. 添加命令时判断是否重复
2. exec中加入execLang= 设定编程语言, 目前写死bat, 后续动态
3. 增加菜单搜索命令
3. 增加菜单判断命令是否已经存在
4. label方式调用，导致global变量太多过于混乱，修改为函数调用。注意:Gui, AddBranchItem:Add, Text, x+5 yp-3 w400 vAddBranchParent, %parentBranchName%。vAddBranchParent必须为global类型
5. inputCmdBar窗口大小目前写死, 使用变量定制
6. 将公共变量集中定义
7. 为命令添加权重，被使用次数越多的命令拍的更加靠前
8. 数据存储到sqlite




### 演示
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo.png"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo2.png"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo3.png"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo4.png"/></div>


### 其他
1. 项目整合替代了[ahk-context-command](https://github.com/bjc5233/ahk-context-command)、[g.bat](https://github.com/bjc5233/batch-shortcut-go)、[get.bat](https://github.com/bjc5233/batch-shortcut-get)、[q.bat](https://github.com/bjc5233/batch-shortcut-qq)、do.bat
2. 项目自带配置的命令中有些涉及bat脚本, 需要一定的环境, 不一定执行成功
