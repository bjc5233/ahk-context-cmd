# ahk-context-cmd
> 效率工具，上下文环境命令助手, 方便快速执行命令、跳转界面


### 使用方法
1. 监听``之间输入的命令 {在任何环境下都可以检测到【输入框\桌面】}
2. 鼠标中键唤出输入框，输入命令
3. 双击右侧Ctrl唤出输入框，输入命令


### 特点
1. 任意界面，即使是桌面下，完全看不到输入，也可以执行
2. 花费时间少。相比之下手动寻找快捷方式并点击，花费的时间最长；而使用运行\启动器需要打开界面，输入命令，回车，才执行命令
3. 自动根据系统壁纸主色调配置输入框颜色 \ AeroGlass主题
4. 当用户输入找不到命令, 则尝试从匹配列表中执行第一个命令【用户输入g ah则会执行命令g ahk】【用户输入ca则会执行命令calc】


### 输入框界面快捷键说明
 1. 总界面   - F1键      - 打开命令树管理
 2. 总界面   - Esc键     - 关闭
 3. 候选列表 - Up\Down键 - 在输入框\候选命令列表上下移动
 4. 候选列表 - Right键   - 将当前选中的命令复制到输入框中
 5. 输入框   - Tab键     - 将候选列表中第一个结果复制到输入框中


### 配置自定义命令
1. 图标右键->修改菜单-> 新增\编辑\删除\保存命令树
```
 => g   快捷跳转命令
 => get 快捷复制命令
 => q   qq联系人跳转
 => do  综合性处理命令
 => -   contextCmd内建指令【theme[切换主题] tree[编辑命令树] history[历史命令] reload[重启脚本] quit[关闭界面] exit[退出脚本]】 
 => 其他系统级别的命令、快捷方式 【calc notepad...】
```




### 演示
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo.gif"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo.png"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo2.png"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo3.png"/></div>
<div align=center><img src="https://github.com/bjc5233/ahk-context-cmd/raw/master/resources/demo4.png"/></div>




### 主题说明
 1. auto模式(默认), 根据系统当前壁纸配置颜色, 窗口位置中间【需要第三方命令行工具imagemagick-convert.exe】
 2. blur模式, AeroGlass风格, 由于在偏白色背景下无法看清文字, 因此位置放置在左下角
 3. custom模式, 配置的固定几种颜色风格, 每次展示时随机颜色风格, 窗口位置中间



### TODO
1. 当输入无法匹配命令，会根据当前输入key和所有key进行字符串相似度比较, 提供猜测建议
2. 命令匹配模式[startWith] ==> [containsWith]
3. 历史记录中，当当前要记录的与前一条一样，则不记录数据库
4. 对第二层级命令进行提示[g ziliao mobile]中的mobile
5. 每周五展示历史输入命令排行榜[前二十]；创建内部指令统计当前命令hitting次数排行榜
6. 选取文本，此时再点击鼠标中键\Ctrl+Ctrl    处理选中文本 - 搜索\查询单词
7. 新增命令属性[窗口类型], 取值[min max normal hide], 默认值为normal; 此时修改删除临时变量execWinMode
8. 新顶级命令 => c 代码片段读取    参考项目[ahk-context-code](https://github.com/bjc5233/ahk-context-code)      需要支持第二层级命令提示
9. 脚本类型命令，在第一次调用后会在cache目录生成脚本文件，后续直接调用此文件。需要在修改命令时，检查是否存在缓存脚本，有则删除
10. 脚本在启动时会将系统path目录中的所有命令及其注释保存到DB，但命令可能会被修改(如bat标题、lnk备注信息)。因此需要DB记录命令的修改时间，脚本启动后检查命令时间是否有变化，有则更新



### 更新
* 2018-06-11  1:19:57 增加搜索栏主题颜色
* 2018-05-29 16:54:53 最初版本



### 其他
1. 项目整合替代了[g.bat](https://github.com/bjc5233/batch-shortcut-go)、[get.bat](https://github.com/bjc5233/batch-shortcut-get)、[q.bat](https://github.com/bjc5233/batch-shortcut-qq)、do.bat
2. 项目自带数据库contextCmd.db，是本人日常生活中所使用的(没有敏感命令)
3. 项目自带事例命令中有些涉及bat脚本, 需要一定的环境[如第三方exe文件], 不保证执行成功
