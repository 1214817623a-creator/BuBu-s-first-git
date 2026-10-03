# 布布大王的菜谱 · Android V1

一个离线厨房学习 APP：告诉你怎么做，也解释为什么。Flutter 实现，安卓为主要目标，同时提供本机浏览器预览。

这个是布布（没有一二宝）的第一个仓库，开启了学习GitHub的第一步！

第一版 APK、安装说明和文件校验值保存在 `dist/`，版本标记为 `v1.0.0`。

## 第一版内容

- 今日厨房：按当前月份推荐时令食材和关联菜谱。
- 找道菜：搜索菜名、食材或标签，按菜系、做法、食材、场景、难度筛选。
- 菜谱详情：简介、总用时、动手与等待时间、工具、1～8 人份食材换算。
- 做菜模式：备料清单、单步大字引导、4 档字号、原创矢量插画和轻动画。
- 知识库：18 张知识卡，关联步骤，包含原理、替代方法、差异和安全内容来源。
- 烹饪辅助：跨步骤计时、暂停/继续、到时检查、追加 10 分钟、慢炖每 10 分钟看锅提醒。
- 安卓：做菜页面屏幕常亮、系统后台通知、可选精确计时权限。
- 本地保存：菜谱与知识收藏、备料、步骤、字号、计时截止时间和完成次数。无需登录，安卓系统云备份关闭。
- 完整菜谱：番茄牛腩、莲藕排骨汤、嫩滑蒸蛋、蒜蓉小青菜、清蒸南瓜、栗子焖鸡。

## 在手机上体验

编译成功后，安装包放在 `dist/布布大王的菜谱-v1.0.0.apk`。把 APK 发到安卓手机，点击安装；手机可能会要求为接收文件的应用允许「安装未知应用」。

首次建议按「首页 → 番茄牛腩 → 准备食材 → 勾选食材 → 开始做菜」体验。可点知识卡、字号按钮和计时按钮；返回首页会保留进度。

开计时时可以授权通知。在厨房设置中可开启精确计时权限。没有精确权限时，系统后台提醒可能延迟。静音、省电、强行停止应用和设备重启均可能影响通知；重启后请重新打开 APP。计时不能代替照看炉火，暂停计时不会停止炉火。

此版为开发签名的个人体验版本；应用商店发行需配置正式签名。支持 Android 7.0（API 24）及以上。

## 本机预览

启动本机服务：`node tools/preview.mjs`，访问 `http://127.0.0.1:5173`。浏览器和安卓的本地记录各自独立。浏览器版用于体验页面和流程，后台通知与常亮以安卓版为准。

## 开发和验证

本次使用 Flutter 3.47.5 / Dart 3.13.4、Android SDK 36 和 JDK 21。构建工具位于 `.tooling`，不进入版本控制。部分 Windows 原生工具无法处理中文路径，构建时临时用 `B:` 映射项目目录。

```powershell
powershell -ExecutionPolicy Bypass -File tools/flutter-task.ps1 check
powershell -ExecutionPolicy Bypass -File tools/flutter-task.ps1 apk
powershell -ExecutionPolicy Bypass -File tools/flutter-task.ps1 web
```

测试覆盖月份推荐、知识引用完整性、份量换算、本地进度恢复、计时恢复/暂停/去重/结束清理，以及 360、412、1100 像素宽下的首页、详情、备料和超大字号做菜模式。最终验证记录见 `docs/验证记录.md`。

`lib/content.dart` 是菜谱和知识内容，`lib/kitchen_state.dart` 负责本地状态和计时，`lib/main.dart` 是界面，`lib/food_art.dart` 是原创插画。安卓系统提醒实现在 `android/app/src/main/kotlin/com/bubu/bubu_kitchen/`。

## 内容依据和授权

家庭烹饪时间、食材配比和口感提示是可调整的实践建议。食品安全内容按以下资料核实，应用内可查看来源：

- [USDA FSIS：食物清洗与交叉污染](https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics/washing-food-does-it-promote-food)
- [USDA FSIS：安全中心温度](https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics/safe-temperature-chart)
- [USFA：厨房火灾预防](https://www.usfa.fema.gov/prevention/home-fires/prevent-fires/cooking/)
- [Iowa State University：湿热烹饪原理](https://iastate.pressbooks.pub/fshn115/chapter/11-1-moist-heat-methods-introduction/)

中文字体 Noto Sans SC 使用 SIL Open Font License，授权文件在 `assets/fonts/OFL.txt`。插画由本项目原创矢量代码绘制，无远程图片依赖。
