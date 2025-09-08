# galeJSON

跨平台 JSON 编辑器，支持多语言界面，基于 Delphi FMX 开发。

## 功能特性
- 支持 Windows/macOS
- 多标签文档编辑
- JSON 语法高亮与格式化
- 多语言界面（简体中文、繁體中文、English、日本語、한국어、Français、Deutsch、Español、Русский、Italiano、Português、Nederlands）
- 最近文件、自动保存、日志查看
- 支持暗黑模式

## 目录结构
```
├── galeJSON.dpr / .dproj   # Delphi项目文件
├── FormMain.fmx/.pas       # 主窗体
├── lang.json               # 多语言资源文件
├── Win64/Win32/OSX64       # 各平台输出目录
├── utils/                  # 工具单元
└── ...
```

## 快速开始
1. 使用 Delphi 11 或更高版本打开 `galeJSON.dproj`
2. 编译并运行（支持 Win64/Win32/OSX64 平台）
3. 多语言界面自动根据 `lang.json` 加载

## 多语言支持
- 所有界面文本均可在 `lang.json` 中自定义
- 新增语言只需仿照现有结构添加即可

## 参与贡献
欢迎提交 issue 或 PR，完善翻译、功能或修复 bug。

## License
MIT
