# ClickGui-iOS

WKWebView 套壳的 iOS 工程，菜单页面内置在 App 里（`ClickGui/index.html`），打开即进入主界面，点「预览菜单」进入五列菜单。

- App 显示名：`Kleesx_X`（桌面图标下的名称）
- Bundle ID：`com.clickgui.menu`
- 图标：内置在 `Assets.xcassets/AppIcon.appiconset`（深色底 + 绿色圆 + 白色 K）

## 工程结构

```
ClickGui-iOS/
├── ClickGui.xcodeproj/
│   └── project.pbxproj        # Xcode 工程文件
├── ClickGui/
│   ├── AppDelegate.swift      # 入口，单窗口挂载控制器
│   ├── ViewController.swift   # WKWebView + 采集本机信息注入网页
│   ├── Info.plist             # App 信息 / Bundle ID / 部署版本
│   ├── Assets.xcassets/        # App 图标（AppIcon 各尺寸）
│   ├── index.html             # 菜单页面（主界面 + 菜单界面 + 开关 + 缩放）
│   └── bg.jpg                 # 菜单背景图（随 Resources 打进 App）
└── .github/
    └── workflows/
        └── build-ipa.yml      # 云端 Mac 自动出 ipa
```

- Bundle ID：`com.clickgui.menu`
- 最低系统：iOS 12.0
- 设备：iPhone + iPad

## 设备信息读取说明

主界面「Hook 注入」点击后，由原生 Swift 采集本机信息注入网页（`window.NATIVE_DEVICE`）回填字段：

| 字段 | 来源 | 说明 |
| --- | --- | --- |
| 设备名称 | `UIDevice.name` | 本机设置里的设备名 |
| 设备类型 | `userInterfaceIdiom` | iPhone / iPad / Mac |
| iOS版本 | `UIDevice.systemVersion` | 系统版本号 |
| 型号名称 | 内部型号映射表 | 常见机型已映射，未收录显示内部型号 |
| 型号 | `hw.machine` | 内部硬件标识，如 `iPhone15,2` |
| 序列号 | — | **iOS 不允许第三方 App 读取，固定显示「不可用」** |
| 本机UDID | `identifierForVendor` | 这是供应商标识符，**不是设备真 UDID**；卸载重装可能变化，取不到显示「不可用」 |

> 真序列号 / 真 UDID 只有在越狱环境、私有框架或 MDM/描述文件下才能拿到，普通 App Store 应用无法获取。浏览器预览时没有原生注入，字段回退为 UA 解析或「—」。

## 方式一：GitHub Actions 云端出 ipa（不用 Mac，推荐）

### 1. 准备仓库
- 注册 / 登录 GitHub，新建一个仓库（**Public** 可免费使用 macos 构建机；Private 也有每月免费额度）；
- 仓库名随意，如 `clickgui-ios`，**不要**勾选初始化 README。

### 2. 上传工程文件
把本目录 `ClickGui-iOS/` 里的**全部内容**放到仓库**根目录**，保持这个结构：

```
.github/workflows/build-ipa.yml
ClickGui.xcodeproj/project.pbxproj
ClickGui/AppDelegate.swift
ClickGui/ViewController.swift
ClickGui/Info.plist
ClickGui/Assets.xcassets/Contents.json
ClickGui/Assets.xcassets/AppIcon.appiconset/Contents.json
ClickGui/Assets.xcassets/AppIcon.appiconset/*.png
ClickGui/index.html
ClickGui/bg.jpg
```

两种上传方式任选：

**A. 网页上传（不用装 git）**
1. 仓库页点 `Add file → Upload files`；
2. 把上述文件/文件夹拖进去（`.github` 隐藏文件夹也要传）；
3. 点 `Commit changes`。

**B. git 命令行**
```bash
cd ClickGui-iOS
git init
git add .
git commit -m "init clickgui ios"
git branch -M main
git remote add origin https://github.com/你的用户名/仓库名.git
git push -u origin main
```

### 3. 触发构建
- 推送到 `main` 分支后会**自动**触发 `Build iOS ipa`；
- 也可以进仓库 `Actions` 页，选 `Build iOS ipa`，点 `Run workflow` 手动跑一次。

### 4. 下载 ipa
1. 进 `Actions` 页，点开正在运行 / 已完成的那次构建；
2. 拉到页面底部 `Artifacts` 区域；
3. 下载 `Kleesx_X-ipa`，解压后得到 `Kleesx_X.ipa`。

### 5. 安装到真机
Actions 产出的是**未签名**包，不能直接装，需要重签（见下节）。

## 方式二：Mac 上用 Xcode 编译

1. 把整个 `ClickGui-iOS` 拷到 Mac；
2. 双击 `ClickGui.xcodeproj` 用 Xcode 打开；
3. `Signing & Capabilities` 里选自己的开发者账号；
4. `Product → Build` 确认运行；`Product → Archive → Distribute App` 导出 ipa。

## 关于签名与安装

- Actions 直接产出的 ipa **没有苹果签名**，不能直接装到真机；
- **免费侧签**：用 [Sideloadly](https://sideloadly.io) 或 [AltStore](https://altstore.io) 导入该 ipa，用自己的 Apple ID 重签后侧装；免费签名 7 天有效，到期需重签；
- **正式分发**：在仓库 `Settings → Secrets and variables → Actions` 配置开发者证书 / 描述文件（见 `build-ipa.yml` 末尾注释），改用带签名的 archive 与 `xcodebuild -exportArchive` 导出正式 ipa。

## 菜单已内置的能力

- 主界面：成功进入状态、Hook 注入查询、设备字段；点「预览菜单」渐变进入菜单界面
- 菜单五列：战斗 / 移动 / 视觉 / 漏洞 / 其他
- 点按切换开关，关闭后背景全透明、不留高亮
- 右下角 `+ / − / ⟲` 手动缩放（触屏用按钮，不依赖滚轮）
- 图标为内置 SVG 矢量，放大不糊
