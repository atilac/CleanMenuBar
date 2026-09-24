# App Store — zh-Hans

**Version 0.1.3** — same number as the GitHub release, deliberately: one
number, one binary, one set of changes, wherever someone finds the app.

## Name (30)

CleanMenuBar：隐藏图标

## Subtitle (30)

整理你的菜单栏

## Keywords (100)

隐藏,收起,图标,菜单栏,状态栏,整理,清爽,效率,刘海,快捷键,极简

## Promotional text (170)

隐藏你用不到的图标，需要时再显示。无需权限，不收集数据，不联网。MIT 许可证开源。

## Description (4000)

菜单栏图标太多？CleanMenuBar 隐藏你不想看到的图标，需要时再显示出来。

工作原理

菜单栏中会出现两个项目：一个细分隔符「|」和一个箭头「>」。

按住 ⌘ 并将想隐藏的图标拖到分隔符「|」的左侧。位于其右侧的图标始终保持可见。点按箭头「>」折叠，点按「<」展开——或在任意位置按 ⌃⌥⌘C。

整理完成后，在设置中开启「隐藏分隔符」，屏幕上便只留下箭头。

位置在重新启动后依然保留。macOS 会记住每个图标的位置。

功能

• 点按、全局快捷键，或仅将指针悬停其上即可隐藏与显示
• 始终隐藏区域，用于你永远不想看到的图标
• 5、10、15、30 或 60 秒后自动折叠
• 启动时恢复上次的状态
• 登录时自动打开
• 九种语言

无需权限

CleanMenuBar 不请求任何特殊权限。既不需要「辅助功能」，也不需要「屏幕录制」——这在菜单栏工具中并不常见，之所以可行，是因为全局快捷键使用了无需这些权限的 API，且该 App 从不读取屏幕。

它也没有网络权限。即使代码尝试，也无法发送任何内容。沙盒容器之外的内容一概不读取。

需要 macOS 27

macOS 27 将菜单栏重建为单一窗口，部分 App 所用的技术随之失效。CleanMenuBar 在 macOS 27 公开发布次日，于该系统上直接开发并实测。

不支持更早的 macOS 版本——也无需支持：在那些系统上，旧技术仍然有效。

由于 macOS 27 无法在 Intel 芯片的 Mac 上运行，CleanMenuBar 需要 Apple Silicon。

开源

完整源代码以 MIT 许可证公开，其中包括声明 App 权限范围的文件。你无需相信以上任何说法——可以自行查证。

github.com/atilac/CleanMenuBar

致谢

CleanMenuBar 建立在 Dwarves Foundation 的 Hidden Bar 之上，依 MIT 许可证使用。其菜单、设置与文案均源自该项目。感谢六年来让它持续存在的每一位。

## What's New

CleanMenuBar 的首个公开版本。
