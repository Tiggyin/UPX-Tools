# UPX-Tools 项目完整档案文档

> 源仓库: https://github.com/Y-ASLant/UPX-Tools  
> 本地路径: D:\Pa\Ai_Huan\UPX-Tools  
> 版本: v1.5.0 | 语言: JavaScript + Rust | License: MIT  
> 定位: 基于 Tauri 2.0 的 UPX 可视化加壳/脱壳工具，Windows 平台专用

---

## 目录

1. [项目概览](#1-项目概览)
2. [完整目录结构](#2-完整目录结构)
3. [核心架构说明](#3-核心架构说明)
4. [文件详解](#4-文件详解)
    - [4.1 前端 (ui/)](#41-前端-ui)
    - [4.2 后端 (src-tauri/)](#42-后端-src-tauri)
    - [4.3 构建与工具链](#43-构建与工具链)
    - [4.4 CI/CD](#44-cicd)
    - [4.5 资源文件](#45-资源文件)
5. [环境依赖](#5-环境依赖)
6. [编译与打包指南](#6-编译与打包指南)
7. [接口文档 (Tauri Commands)](#7-接口文档-tauri-commands)
8. [数据流与交互逻辑](#8-数据流与交互逻辑)

---

## 1. 项目概览

### 功能定位

UPX-Tools 是一个 Windows 桌面 GUI 工具，封装了 [UPX](https://github.com/upx/upx) (Ultimate Packer for eXecutables) 命令行工具，提供图形化界面用于 EXE/DLL 文件加壳压缩和脱壳解压。

### 核心特性

| 特性 | 说明 |
|------|------|
| 双模式操作 | "加壳压缩" 和 "脱壳解压" 两种核心操作 |
| 拖放支持 | 支持文件/文件夹拖放到对应按钮区域 |
| 批量处理 | 多文件并发处理，动态调整并发数 |
| 压缩级别 | 1-9 级 + best + ultra-brute 极限模式 |
| 便携版支持 | 单文件 EXE，内嵌 UPX 二进制 (include_bytes!) |
| 配置持久化 | JSON 配置文件自动保存/加载 |
| 更新检查 | 一键检测 GitHub Release 新版本 |
| 图标缓存刷新 | 清理 Windows 图标缓存 + 重启资源管理器 |

### 技术选型

```
┌─────────────────────────────────────────┐
│            UPX-Tools 应用架构            │
├─────────────────────────────────────────┤
│  前端 (Webview)                          │
│  HTML + TailwindCSS + Vanilla JS(shadcn)│
│  文件: ui/index.html, ui/js/main.js     │
├─────────────────────────────────────────┤
│  通信层: Tauri IPC (invoke/command)     │
├─────────────────────────────────────────┤
│  后端 (Rust)                             │
│  Tauri 2.0 + tokio + reqwest + serde   │
│  文件: src-tauri/src/main.rs (745行)    │
├─────────────────────────────────────────┤
│  核心引擎                                │
│  UPX (upx/upx.exe, 621KB)              │
└─────────────────────────────────────────┘
```

---

## 2. 完整目录结构

```
D:\Pa\Ai_Huan\UPX-Tools\
│
├── .github/                         # GitHub Actions 工作流目录
│   └── workflows/
│       ├── build.yml                # 构建工作流 (push/PR触发)
│       ├── ci.yml                   # CI检查 (格式化/clippy/测试)
│       └── release.yml              # 发布工作流 (tag触发，生成MSI/NSIS/便携版)
│
├── icons/                           # 应用图标资源
│   ├── 32x32.png                   # 小图标 (1,067 B)
│   ├── 128x128.png                 # 中等图标 (6,174 B)
│   ├── 128x128@2x.png             # 高清图标 (15,103 B)
│   ├── icon.ico                    # Windows ICO 格式 (278,590 B)
│   ├── tools.png                   # 工具图标 (48,229 B)
│   └── README.md                   # 图标说明文档
│
├── img/                             # README 文档用截图
│   ├── index.png                   # 主界面截图
│   ├── pack.png                    # 加壳压缩截图
│   ├── unpack.png                  # 脱壳解压截图
│   ├── setting.png                 # 设置界面截图
│   ├── check_update_noupdate.png   # 更新检查-无更新
│   └── check_update_update.png     # 更新检查-有新版本
│
├── src-tauri/                       # 【核心】Tauri 后端 + Rust 代码
│   ├── src/
│   │   └── main.rs                 # ★ Rust 后端唯一源码 (745行)
│   ├── gen/
│   │   └── schemas/                # Tauri 自动生成的权限配置
│   │       ├── acl-manifests.json  # 访问控制清单
│   │       ├── capabilities.json   # 能力配置
│   │       ├── desktop-schema.json # 桌面端模式定义
│   │       └── windows-schema.json # Windows 平台模式定义
│   ├── Cargo.toml                  # ★ Rust 依赖与编译配置
│   ├── Cargo.lock                  # Rust 依赖锁定文件
│   ├── build.rs                    # Rust 构建脚本 (调用 tauri_build)
│   └── tauri.conf.json             # ★ Tauri 应用运行时配置
│
├── ui/                              # 【核心】前端代码 (原生 HTML/CSS/JS)
│   ├── index.html                  # ★ 主页面 (463行，包含完整UI)
│   ├── css/
│   │   ├── main.css               # Tailwind CSS 入口 (仅3行 @tailwind)
│   │   ├── style.css              # ★ 自定义样式 (641行，shadcn/ui变量)
│   │   └── tailwind.css           # Tailwind 编译产物 (11,854 B)
│   ├── js/
│   │   └── main.js                # ★ 前端业务逻辑 (928行)
│   └── font/
│       └── YASLant.woff2          # 自定义字体文件 (552 KB)
│
├── upx/                             # UPX 可执行文件
│   └── upx.exe                     # ★ UPX 核心压缩引擎 (621 KB)
│
├── package.json                     # ★ npm 项目配置 + 脚本定义
├── tailwind.config.js              # Tailwind CSS 主题配置
├── postcss.config.js               # PostCSS 构建配置
├── eslint.config.js                # ESLint 9 代码检查规则
├── .prettierrc.json                # Prettier 格式化配置
├── .prettierignore                 # 格式化忽略列表
├── .gitignore                      # Git 忽略规则
│
├── README.md                       # 项目自述文件
├── CLAUDE.md                       # AI 辅助开发指南
├── LICENSE                         # MIT 许可证
│
└── PROJECT_DOCUMENTATION.md        # ★ 本文档 — 完整档案
```

---

## 3. 核心架构说明

### 3.1 进程模型

```
┌──────────────────────────────────────────────────────┐
│                   主进程 (Rust)                       │
│  tauri::Builder → 注册 8 个 Tauri Command            │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │  process_upx (async)                         │    │
│  │    → 调用 upx.exe (tokio::spawn_blocking)    │    │
│  │    → GBK → UTF-8 编码转换                     │    │
│  │    → 输出过滤 + 错误解析                       │    │
│  └──────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────┐    │
│  │  check_update (async)                        │    │
│  │    → reqwest HTTP GET GitHub API             │    │
│  │    → 版本比较 + 过滤 Windows 资源             │    │
│  └──────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────┐    │
│  │  scan_folder / get_upx_version /             │    │
│  │  refresh_icon_cache / save_config /          │    │
│  │  load_config / download_and_install          │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────┬───────────────────────────────┘
                       │ Tauri IPC (invoke)
┌──────────────────────┴───────────────────────────────┐
│                   Webview 进程                        │
│  index.html → main.js → window.__TAURI__.core.invoke  │
│                                                      │
│  UI: 标题栏(自定义) + 双操作按钮 + 日志面板            │
│  Drag & Drop: listen('tauri://drag-drop')            │
│  弹窗: 设置(模态框) + 更新检查(模态框)                │
└──────────────────────────────────────────────────────┘
```

### 3.2 UPX 路径解析 (三级查找)

```
get_upx_path() 查找逻辑:
  ┌─────────────────────────────────────────────┐
  │ 1. 安装版检查                                │
  │    当前exe目录/_up_/upx/upx.exe              │
  │    → 如果存在，返回此路径                    │
  ├─────────────────────────────────────────────┤
  │ 2. 开发环境检查                              │
  │    ../upx/upx.exe (相对路径)                 │
  │    → 如果存在，返回此路径                    │
  ├─────────────────────────────────────────────┤
  │ 3. 便携版 (嵌入资源释放)                      │
  │    EMBEDDED_UPX → %TEMP%/upx-gui-portable/   │
  │    → 释放后缓存到 OnceLock 静态变量          │
  └─────────────────────────────────────────────┘
```

### 3.3 批处理并发策略

```javascript
// JS端: main.js 第11-14行
cpuCores = navigator.hardwareConcurrency || 4
batchSize = Math.max(2, Math.min(cpuCores * 2, 16))
// 范围: [2, 16]，默认为 CPU核心数×2
```

---

## 4. 文件详解

### 4.1 前端 (ui/)

#### ⭐ `ui/index.html` — 主页面 (463行)

**职责**: 定义完整的 GUI 界面结构，包括：

| 区域 | 行号范围 | DOM ID | 说明 |
|------|----------|--------|------|
| 标题栏 | 15-135 | `titlebar` | 自定义窗口装饰，包含标题/版本/7个按钮 |
| 操作区 | 138-189 | `compress-btn`/`decompress-btn` | 双按钮 + 拖放区域 |
| 日志区 | 192-224 | `log-output` | 带清空按钮的只读日志面板 |
| 设置弹窗 | 227-382 | `settings-modal` | 压缩级别滑条 + 7个Switch开关 |
| 更新弹窗 | 385-458 | `update-modal` | 版本信息 + 下载选项 + 进度条 |

**技术要点**:
- 无边框窗口 (`decorations: false`)，手动实现标题栏拖拽 (`data-tauri-drag-region`)
- 右键菜单禁用 (`oncontextmenu="return false"`)
- 全局禁用用户选择 (`user-select: none`)
- 自定义呼吸灯动画 (`.breathing-light`)

---

#### ⭐ `ui/js/main.js` — 前端业务逻辑 (928行)

**模块划分**:

| 模块 | 行号 | 函数/变量 | 说明 |
|------|------|-----------|------|
| **初始化** | 1-15 | `invoke`, `open`, `save` | Tauri API 导入 + 性能配置 |
| **DOM 引用** | 17-66 | `$()`, `initDOMElements()` | 延迟获取 + 缓存 DOM 引用 |
| **应用入口** | 69-103 | `DOMContentLoaded` 回调 | 页面加载完成后7步初始化 |
| **键盘拦截** | 105-129 | `preventRefresh()` | 禁用 F5/Ctrl+R/Ctrl+W |
| **窗口控制** | 132-136 | `initWindowControls()` | 最小化/最大化/关闭 |
| **标题点击** | 139-153 | `initTitleClick()` | 点击标题打开 GitHub 仓库 |
| **操作按钮** | 155-198 | `initOperationButtons()` | 加壳/脱壳按钮绑定 + 文件选择 |
| **压缩级别** | 201-231 | `updateLevelDisplay()` | 滑条值显示 + 说明映射 |
| **弹窗控制** | 234-248 | `showModal()`/`hideModal()` | 通用弹窗动画控制 |
| **文件夹扫描** | 251-264 | `scanFolder()` | 递归扫描 exe/dll |
| **批量处理** | 266-306 | `processBatchFiles()` | 并发批量处理核心逻辑 |
| **拖放系统** | 308-435 | `setupDragAndDrop()` 等 | Tauri 拖放事件监听 + 区域判断 |
| **文件选择** | 437-462 | `handleFileSelect()` | 原生文件对话框 |
| **压缩/解压** | 464-578 | `processUpx()` | invoke Rust 命令 + 结果解析 |
| **日志系统** | 832-878 | `addLog()` | 日志添加 + 性能优化 |
| **图标刷新** | 581-594 | `handleRefreshIcon()` | 清理 Windows 图标缓存 |
| **更新系统** | 596-830 | `handleCheckUpdate()` | GitHub Release 检查 + 下载 |
| **配置管理** | 880-927 | `saveCurrentConfig()`/`loadSavedConfig()` | 配置保存/加载 |
| **Markdown渲染** | 651-708 | `renderMarkdown()`/`formatInline()` | 简易内联 Markdown 渲染器 |

**关键代码段**:

```javascript
// [行11-14] 性能配置 — 基于CPU核心数动态调整批处理并发
const PERFORMANCE_CONFIG = {
    cpuCores: navigator.hardwareConcurrency || 4,           // 默认4核
    batchSize: Math.max(2, Math.min((... || 4) * 2, 16)),   // 2~16范围
}

// [行403-435] 拖放区域判断 — 通过坐标碰撞检测确定目标操作
let cachedButtonRects = null  // 缓存按钮位置 (resize时清除)
function getDropTarget(position) {
    if (!cachedButtonRects) updateButtonRectsCache()
    const { x, y } = position
    if (isPointInRect(x, y, cachedButtonRects.compress)) return 'compress'
    if (isPointInRect(x, y, cachedButtonRects.decompress)) return 'decompress'
    return null
}

// [行836-878] 日志管理 — 最大1000条，超出批量删200条
const LOG_CONFIG = { MAX_LOGS: 1000, TRIM_COUNT: 200 }
function addLog(message, type, highlight) {
    // ...创建logLine元素...
    if (logCount > LOG_CONFIG.MAX_LOGS) {
        for (let i = 0; i < LOG_CONFIG.TRIM_COUNT; i++)
            logOutput.removeChild(logOutput.firstChild)  // 批量删除优化性能
    }
    requestAnimationFrame(() => logOutput.scrollTop = logOutput.scrollHeight)
}
```

---

#### ⭐ `ui/css/style.css` — 自定义样式 (641行)

**样式模块**:

| 模块 | 行号 | 说明 |
|------|------|------|
| 字体定义 | 1-8 | `@font-face` YASLant 自定义字体 |
| CSS 变量 | 10-33 | shadcn/ui New York 风格设计令牌 (neutral基色) |
| 全局重置 | 35-81 | box-sizing, 焦点样式, 字体家族, 禁用选择 |
| 呼吸灯 | 83-98 | `@keyframes breathing` 2秒循环 |
| 滚动条 | 100-141 | 自定义 WebKit 滚动条 (4px 宽度) |
| 日志行 | 143-173 | `.log-info/error/warning/success/hint` 颜色定义 |
| 按钮系统 | 175-246 | shadcn/ui 风格: primary/secondary/outline/ghost |
| 卡片 | 248-254 | `.card` 带边框圆角 |
| Switch 开关 | 274-443 | 自定义 CSS Switch 组件 (36×20px) |
| 滑条 | 446-521 | 自定义 range input (WebKit + Firefox) |
| 动画 | 523-608 | spin, fadeIn, shimmer, bounce 动画 |
| 拖放区域 | 582-608 | `.drop-zone.drag-over` 高亮效果 |
| 弹窗 | 610-640 | `.modal-backdrop/.modal-content` 淡入缩放动画 |

**设计令牌体系** (CSS Variables):

```css
:root {
    --background: 0 0% 100%;        /* 白 */
    --foreground: 0 0% 3.9%;        /* 近黑 */
    --primary: 0 0% 9%;             /* 主色:深灰 */
    --muted: 0 0% 96.1%;            /* 弱化背景 */
    --muted-foreground: 0 0% 45.1%; /* 弱化文字 */
    --destructive: 0 84.2% 60.2%;   /* 破坏性操作色(红) */
    --border: 0 0% 89.8%;           /* 边框色 */
    --radius: 8px;                  /* 圆角半径 */
    --radius-btn: 4px;              /* 按钮圆角 */
}
```

---

#### `ui/css/main.css` (3行)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Tailwind CSS 入口文件，通过 `postcss.config.js` 编译为 `ui/css/tailwind.css` (11,854 B)。

编译命令: `npm run build:css` → `npx tailwindcss -i ./ui/css/main.css -o ./ui/css/tailwind.css --minify`

---

#### `ui/font/YASLant.woff2` (552 KB)

自定义字体文件，采用 WOFF2 格式，通过 `@font-face` 在 `style.css` 中声明，作为全局 sans-serif 字体栈首选。

---

### 4.2 后端 (src-tauri/)

#### ⭐ `src-tauri/src/main.rs` — Rust 后端源码 (745行)

**完整模块结构**:

```
main.rs 代码组织 (745行)
│
├── [行1-2]   编译指令
│   ├── #![windows_subsystem = "windows"]  (release模式隐藏控制台)
│
├── [行4-16]  依赖导入
│   ├── encoding_rs::GBK     (GBK→UTF-8编码转换)
│   ├── serde                 (序列化/反序列化)
│   ├── std::fs, io, path    (文件系统操作)
│   ├── std::process::Command (进程调用)
│   ├── reqwest               (HTTP客户端)
│   ├── tokio                 (异步运行时)
│   └── CREATE_NO_WINDOW     (0x08000000, 隐藏子进程窗口)
│
├── [行19-22]  静态数据
│   ├── EMBEDDED_UPX: 嵌入upx.exe二进制 (include_bytes!)
│   └── EXTRACTED_UPX_PATH: 释放路径缓存 (OnceLock)
│
├── [行28-76]  数据结构定义
│   ├── UpxOptions        — UPX操作参数 (前端传入)
│   ├── ScanFolderOptions — 文件夹扫描参数
│   ├── AppConfig         — 全局配置 (8字段 + 默认值)
│   ├── UpdateInfo        — 更新信息
│   ├── GitHubRelease     — GitHub API Release
│   └── GitHubAsset       — Release 资源文件
│
├── [行82-141]  路径解析
│   ├── get_config_path()         → 配置文件路径
│   ├── get_upx_path()            → UPX三级查找
│   └── extract_embedded_upx()    → 便携版释放 + OnceLock缓存
│
├── [行146-207]  命令构建辅助
│   ├── create_silent_command()   → 创建隐藏窗口的Command
│   ├── build_compress_args()     → 构建加壳参数
│   └── build_decompress_args()   → 构建脱壳参数
│
├── [行212-271]  输出处理
│   ├── IGNORED_PREFIXES          → 需要过滤的输出前缀
│   ├── filter_output_lines()     → 过滤噪音输出
│   ├── format_upx_output()       → 格式化成功输出
│   └── parse_upx_error()         → ★错误模式匹配 (6种错误类型)
│
├── [行277-292]  工具函数
│   └── format_bytes()            → 字节大小格式化
│
├── [行297-399]  UPX 处理核心
│   ├── validate_upx_and_file()   → 验证UPX可用 + 文件存在
│   ├── validate_file_writable()  → 检查文件可写
│   ├── create_backup()           → 创建.bak备份
│   ├── execute_upx()             → ★执行UPX (GBK解码 + 结果计算)
│   └── process_upx()             → ★Tauri Command (异步入口)
│
├── [行405-445]  文件夹扫描
│   ├── SUPPORTED_EXTENSIONS      → ["exe", "dll"]
│   ├── scan_folder_recursive()   → 递归扫描
│   └── scan_folder()             → Tauri Command
│
├── [行451-466]  get_upx_version() → UPX版本查询
│
├── [行472-527]  refresh_icon_cache() → Windows图标缓存刷新
│   └── refresh_icon_cache_internal()
│       ├── taskkill /f /im explorer.exe
│       ├── 删除 IconCache.db
│       ├── 删除 thumbcache_*
│       └── 重启 explorer.exe
│
├── [行533-698]  检查更新 + 下载安装
│   ├── GITHUB_REPO / CURRENT_VERSION  (常量)
│   ├── create_http_client()           → reqwest客户端
│   ├── check_update()                 → ★Tauri Command (GitHub API)
│   ├── download_and_install()         → Tauri Command (下载+启动)
│   └── version_compare()              → 版本号比较
│
├── [行703-723]  配置持久化
│   ├── save_config() → 序列化为JSON写入文件
│   └── load_config() → 读取JSON反序列化 (不存在返回默认值)
│
└── [行728-744]  Tauri应用入口
    └── main()
        ├── .plugin(tauri_plugin_shell::init())
        ├── .plugin(tauri_plugin_dialog::init())
        ├── .invoke_handler(generate_handler![8个命令])
        └── .run()
```

**关键代码段**:

```rust
// [行19] 便携版支持 — 编译时嵌入 UPX 二进制到 Rust 二进制中
const EMBEDDED_UPX: &[u8] = include_bytes!("../../upx/upx.exe");

// [行113-139] OnceLock 确保嵌入资源只释放一次 (线程安全)
static EXTRACTED_UPX_PATH: OnceLock<Option<PathBuf>> = OnceLock::new();
fn extract_embedded_upx() -> Option<PathBuf> {
    EXTRACTED_UPX_PATH.get_or_init(|| {
        let temp_dir = std::env::temp_dir().join("upx-gui-portable");
        fs::create_dir_all(&temp_dir).ok()?;
        let upx_path = temp_dir.join("upx.exe");
        // 如果已存在且大小匹配，直接复用
        if upx_path.exists() {
            if let Ok(m) = fs::metadata(&upx_path) {
                if m.len() == EMBEDDED_UPX.len() as u64 { return Some(upx_path); }
            }
        }
        let mut file = fs::File::create(&upx_path).ok()?;
        file.write_all(EMBEDDED_UPX).ok()?;
        Some(upx_path)
    }).clone()
}

// [行247-271] 错误模式匹配 — 智能解析 UPX 中文错误提示
fn parse_upx_error(stdout: &str, stderr: &str) -> String {
    let error_patterns: &[(&[&str], &str)] = &[
        (&["AlreadyPackedException", "already packed"], "[错误] 文件已经被 UPX 加壳过了..."),
        (&["NotPackedException", "not packed"], "[错误] 文件未被 UPX 加壳..."),
        (&["CantPackException"], "[错误] 无法压缩此文件..."),
        (&["OverlayException"], "[错误] 文件包含附加数据（Overlay）..."),
        (&["IOException", "can't open"], "[错误] 文件访问失败..."),
        (&["NotCompressibleException"], "[错误] 文件无法压缩..."),
    ];
    for (patterns, message) in error_patterns {
        if patterns.iter().any(|p| combined.contains(p)) {
            return message.to_string();
        }
    }
    // 通用错误回退
}

// [行336] GBK → UTF-8 编码转换 (UPX在Windows上输出GBK)
let (stdout, _, _) = GBK.decode(&output.stdout);
let (stderr, _, _) = GBK.decode(&output.stderr);
```

**8 个 Tauri Commands (IPC 接口)**:

| Command | 行号 | 类型 | 说明 |
|---------|------|------|------|
| `process_upx` | 363 | async | 执行加壳/脱壳 (tokio阻塞任务) |
| `scan_folder` | 433 | sync | 递归扫描exe/dll文件 |
| `get_upx_version` | 452 | sync | 获取UPX版本号 |
| `refresh_icon_cache` | 518 | async | 清理Windows图标缓存 |
| `check_update` | 573 | async | 检查GitHub Release更新 |
| `download_and_install` | 639 | async | 下载并启动安装程序 |
| `save_config` | 704 | sync | 保存配置到JSON文件 |
| `load_config` | 712 | sync | 加载JSON配置文件 |

---

#### `src-tauri/Cargo.toml` — Rust 依赖配置

```toml
[package]
name = "UPX-Tools"
version = "1.5.0"
edition = "2021"

[dependencies]
tauri = { version = "2" }              # Tauri 2.0 框架
tauri-plugin-shell = "2"              # Shell 插件 (打开URL)
tauri-plugin-dialog = "2"             # 文件对话框插件
serde = { version = "1", features = ["derive"] }  # 序列化
serde_json = "1"                       # JSON 解析
tokio = { version = "1", features = ["full"] }     # 异步运行时
encoding_rs = "0.8"                   # GBK/UTF-8 编码转换
reqwest = { version = "0.12", features = ["json"] } # HTTP客户端

[profile.release]
strip = true       # 移除调试符号
opt-level = "z"    # 优化大小 (最小化)
lto = true         # 链接时优化
codegen-units = 1  # 单编译单元 (更好优化)
panic = "abort"    # panic时abort (减小体积)
```

---

#### `src-tauri/tauri.conf.json` — Tauri 运行时配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `productName` | UPX-Tools | 产品名称 |
| `identifier` | top.aslant.upxgui | 应用唯一标识 |
| `frontendDist` | ../ui | 前端资源目录 |
| `withGlobalTauri` | true | 启用 `window.__TAURI__` |
| `window.width/height` | 640×600 | 默认窗口尺寸 |
| `window.decorations` | false | 无边框窗口 (自定义标题栏) |
| `window.visible` | false | 初始隐藏 (加载完后再显示) |
| `window.dragDropEnabled` | true | 启用拖放 |
| `bundle.targets` | [msi, nsis] | 生成两种安装包 |
| `bundle.resources` | [upx/upx.exe] | 打包时包含UPX |
| `bundle.nsis.languages` | [SimpChinese] | NSIS 安装界面中文 |

---

#### `src-tauri/build.rs` (4行)

```rust
fn main() {
    tauri_build::build()  // Tauri 编译时代码生成
}
```

Tauri 构建脚本，在编译时生成版本信息常量、图标嵌入等。

---

### 4.3 构建与工具链

#### `package.json` — npm 项目配置

| 脚本 | 命令 | 说明 |
|------|------|------|
| `lint` | eslint "ui/**/*.{js,html}" --max-warnings 0 | 代码检查 |
| `lint:fix` | eslint "ui/**/*.{js,html}" --fix | 自动修复 |
| `format` | prettier --write "ui/**/*.{js,html,css}" | 代码格式化 |
| `format:check` | prettier --check "ui/**/*.{js,html,css}" | 格式检查 |
| `check` | npm run lint && npm run format:check | 完整检查 |
| `build:css` | tailwindcss -i ui/css/main.css -o ui/css/tailwind.css --minify | CSS 编译 |
| `watch:css` | tailwindcss --watch | 开发模式 CSS 监听 |
| `build` | cargo tauri build && npm run post-build | 完整构建 + 便携版复制 |

**开发依赖**:
- `eslint` ^9.39.2 + `eslint-plugin-html` — JS/HTML 代码检查
- `prettier` ^3.3.3 — 代码格式化
- `tailwindcss` ^3.4.19 — CSS 框架
- `autoprefixer` ^10.4.23 — CSS 自动加前缀
- `postcss` ^8.5.6 — CSS 处理管道

---

#### `tailwind.config.js` — Tailwind 主题配置

- **content**: `['./ui/**/*.html', './ui/**/*.js']` — 扫描前端文件
- **colors**: 使用 CSS 变量桥接 shadcn/ui 设计令牌
- **fontFamily**: `YASLant` 为首选字体
- **borderRadius**: 继承 CSS 变量 `--radius` / `--radius-btn`

---

#### `eslint.config.js` — ESLint 9 flat config

```json
// 核心规则
indent: 4          // 4空格缩进
quotes: 'single'   // 单引号
semi: 'never'      // 无分号
// 全局变量声明
globals: { invoke, open, save, getCurrentWindow, listen }  // Tauri API
```

---

#### `.prettierrc.json` — 格式化配置

```json
{ "printWidth": 100, "tabWidth": 4, "semi": false, "singleQuote": true }
```

---

### 4.4 CI/CD

#### `release.yml` — 自动发布工作流

触发: 推送 `v*` tag
流程:
1. Checkout → 安装 Rust → Rust缓存 → 安装 Tauri CLI
2. `cargo tauri build` 编译 MSI + NSIS
3. 复制便携版 exe 到 bundle/Portable/
4. 按版本号重命名: `UPX-Tools-{version}-x64-{portable/msi/setup}.{exe/msi}`
5. 上传到 GitHub Release (softprops/action-gh-release@v2)

#### `ci.yml` — CI 检查

触发: push main/master + PR + tag推送
步骤: `cargo fmt --check` → `cargo clippy` → `cargo test`

#### `build.yml` — 构建验证

触发: push main/master (含 `build:` 的commit) + PR
步骤: 同 release 但不发布

---

### 4.5 资源文件

| 文件 | 大小 | 说明 |
|------|------|------|
| `icons/32x32.png` | 1KB | 小图标 |
| `icons/128x128.png` | 6KB | 中等图标 |
| `icons/128x128@2x.png` | 15KB | 高清图标 (256px) |
| `icons/icon.ico` | 279KB | Windows ICO (多尺寸) |
| `icons/tools.png` | 48KB | 工具图标 |
| `ui/font/YASLant.woff2` | 552KB | 自定义字体 |
| `upx/upx.exe` | 621KB | UPX 4.2.4 压缩引擎 |
| `img/*.png` | ~904KB | 6张截图 (README用) |

---

## 5. 环境依赖

### 开发环境

| 依赖 | 最低版本 | 说明 |
|------|----------|------|
| Windows | 10/11 | 目标平台 |
| Node.js | 16+ | 前端工具链 |
| npm | 8+ | 包管理器 |
| Rust | 1.70+ | 后端编译 |
| cargo | 1.70+ | Rust 包管理 |

### 安装 Rust 工具链 (Windows)

```bash
# 下载 rustup-init.exe 并安装 stable-x86_64-pc-windows-msvc
# https://rustup.rs/

# 或通过 winget
winget install Rustlang.Rustup
```

### 安装 Tauri CLI

```bash
cargo install tauri-cli --version "^2.0.0" --locked
```

### 安装 npm 依赖

```bash
cd D:\Pa\Ai_Huan\UPX-Tools
npm install   # 安装 ESLint, Prettier, TailwindCSS 等
```

### 编译 Tailwind CSS

```bash
npm run build:css   # 一次性编译
npm run watch:css    # 开发模式监听
```

---

## 6. 编译与打包指南

### 开发模式运行

```bash
cd D:\Pa\Ai_Huan\UPX-Tools
cargo tauri dev
```

首次运行会下载 Rust 依赖，预计 5-15 分钟。后续运行支持热重载。

### 生产构建

```bash
# 方式1: npm 脚本 (含便携版复制)
npm run build

# 方式2: 直接使用 cargo
cargo tauri build
```

编译产物位置: `src-tauri/target/release/bundle/`

### 编译产物说明

| 产物 | 路径 | 说明 |
|------|------|------|
| 便携版 | `bundle/Portable/UPX-Tools.exe` | 单文件，内嵌UPX，无需安装 |
| MSI | `bundle/msi/*.msi` | Windows Installer 格式 |
| NSIS | `bundle/nsis/*.exe` | NSIS 安装程序 |

### Release 打包 (带版本号)

```bash
# 1. 更新版本号
#    - src-tauri/Cargo.toml: version = "x.y.z"
#    - package.json: "version": "x.y.z"

# 2. 创建 tag
git tag v1.x.x
git push origin v1.x.x

# 3. GitHub Actions 自动构建并发布
#    生成: UPX-Tools-{version}-x64-portable.exe
#          UPX-Tools-{version}-x64.msi
#          UPX-Tools-{version}-x64-setup.exe
```

---

## 7. 接口文档 (Tauri Commands)

### `process_upx` — 执行加壳/脱壳

```
前端调用: invoke('process_upx', { options: UpxOptions })

输入 (UpxOptions):
  mode: "compress" | "decompress"      // 操作模式
  input_file: String                    // 输入文件路径
  output_file: String                   // 输出文件路径
  compression_level: String             // "1"~"9" | "best"
  backup: bool                          // 是否创建.bak备份
  lzma: bool                            // LZMA压缩
  ultra_brute: bool                     // 极限压缩
  force: bool                           // 强制压缩

返回: Result<String, String>
  成功: "操作成功!\n输出: {path}\n原始大小: {size}\n处理后大小: {size}\n压缩率: {rate}%"
  失败: "[错误] {错误描述}\n\n解决方案:\n  - {建议}"
```

### `scan_folder` — 扫描exe/dll

```
输入 (ScanFolderOptions):
  folder_path: String
  include_subfolders: bool

返回: Result<Vec<String>, String>
  成功: ["path1.exe", "path2.dll", ...]
```

### `check_update` — GitHub 版本检查

```
返回: Result<UpdateInfo, String>
  UpdateInfo:
    has_update: bool
    current_version: String       // "v1.5.0"
    latest_version: String        // "v1.6.0"
    release_url: String           // GitHub Release URL
    release_notes: String         // Markdown 格式更新日志
    assets: [{ name, browser_download_url, size }]
```

### `save_config` / `load_config` — 配置持久化

```rust
save_config(config: AppConfig) -> Result<(), String>
load_config() -> Result<AppConfig, String>  // 文件不存在时返回默认值
```

配置文件位置: `{exe所在目录}/upx_gui_config.json`

---

## 8. 数据流与交互逻辑

### 8.1 用户操作流程

```
用户拖放文件到窗口
       │
       ▼
Tauri 触发 'tauri://drag-drop' 事件
       │
       ▼
main.js handleDragDrop()
  ├── collectFiles(paths)         // 分类: 文件直接添加 / 文件夹递归扫描
  ├── processDropByTarget(files, position)
  │   ├── getDropTarget(position) // 坐标碰撞检测 → 'compress' | 'decompress' | null
  │   ├── 命中按钮 → processBatchFiles(files, mode)
  │   └── 未命中 → storeFilesForLater() (等待点击按钮)
  │
  ▼
processBatchFiles(files, mode)
  ├── batchSize = max(2, min(cpuCores*2, 16))
  ├── for batch in files:
  │   └── Promise.all([  // 并发处理
  │       handler(file)  // handleCompressWithFile | handleDecompressWithFile
  │         → processUpx(mode, input, output)
  │           → invoke('process_upx', { options })
  │             → Rust: execute_upx()
  │               → Command::new("upx.exe").args(...).output()
  │               → GBK.decode(output.stdout)
  │               → parse_upx_error() 或 format_upx_output()
  │   ])
  └── addLog("批量处理完成! 成功: N 失败: M")
```

### 8.2 错误处理链路

```
UPX 进程执行失败 (非0退出码)
  │
  ▼
parse_upx_error(stdout, stderr)
  ├── 包含 "AlreadyPackedException"  → 文件已加壳 (中文解决方案)
  ├── 包含 "NotPackedException"      → 文件未加壳
  ├── 包含 "CantPackException"       → 无法压缩
  ├── 包含 "OverlayException"        → 附加数据冲突
  ├── 包含 "IOException"             → 文件访问失败
  ├── 包含 "NotCompressibleException" → 无法压缩
  └── 通用回退                       → 返回原始错误输出
  │
  ▼
Rust: Err(parse_upx_error(...))
  │
  ▼
JS: catch(error) → parseProcessError(errorMsg)
  ├── 包含 "[错误]"   → addLog(line, 'error')
  ├── 包含 "解决方案"  → addLog(line, 'warning')
  └── 包含 "- "       → addLog(line, 'hint')
```

---

## 附录

### 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.5.0 | 2026-02 | 当前最新版本 |

### 相关链接

- UPX 官方: https://github.com/upx/upx
- Tauri 文档: https://tauri.app
- 项目仓库: https://github.com/Y-ASLant/UPX-Tools
- Issues: https://github.com/Y-ASLant/UPX-Tools/issues

---

*本文档生成于 2026-05-21, 基于 commit 81f01b9, 由 WorkBuddy AI 助手自动生成*
