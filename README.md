# portable-conda

在当前目录生成全功能, 便携式的 python.

可以运行 pip 和 conda.

所谓便携式, 是指可以将其拷贝到任何计算机的任何路径下, 都可以正常使用.

只支持 windows.

## 使用

在希望创建环境的目录用 PowerShell 执行:

```
irm "https://raw.githubusercontent.com/one-click-run/portable-conda/main/init.ps1" | iex
```

也可以直接指定版本:

```
$env:ONE_CLICK_RUN_PORTABLE_CONDA_SELECTEDMATCH = 'Miniconda3-py312_24.11.1-0-Windows-x86_64.exe'; irm 'https://raw.githubusercontent.com/one-click-run/portable-conda/main/init.ps1' | iex
```

## 注意

- 当环境目录发生变化时, 应当执行修复脚本.
- 不要使用 conda 创建虚拟环境, 否则当目录变化时, 虚拟环境将无法使用.

## 说明

本仓库提供的 exe 文件是 miniconda 官方安装程序的副本.
