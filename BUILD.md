# LanternLaw 构建与部署指南

本文档记录 LanternLaw HarmonyOS 项目的常用构建和部署命令。

## 环境变量

```bash
# 设置 HarmonyOS SDK 路径
export DEVECO_SDK_HOME="/d/ProgramFiles/DevEcoStudio/sdk"
```

## 构建命令

### 清理构建缓存
```bash
node /d/ProgramFiles/DevEcoStudio/tools/hvigor/bin/hvigorw.js clean
```

### 构建 HAP 包
```bash
DEVECO_SDK_HOME="/d/ProgramFiles/DevEcoStudio/sdk" node /d/ProgramFiles/DevEcoStudio/tools/hvigor/bin/hvigorw.js assembleHap --mode module -p module=entry@default
```

### 构建输出位置
```
entry/build/default/outputs/default/entry-default-unsigned.hap
```

## 设备管理

### 查看已连接设备
```bash
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe list targets
```

### 安装应用到设备
```bash
# 模拟器/真机通用（-t 指定设备，-s 是设置 server 监听端口，不是选择设备）
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe -t 127.0.0.1:5557 install entry/build/default/outputs/default/entry-default-signed.hap
```

### 启动应用
```bash
# bundleName: com.cloudchw.lanternlaw
# abilityName: EntryAbility
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe -t 127.0.0.1:5557 shell aa start -b com.cloudchw.lanternlaw -a EntryAbility
```

### 卸载应用
```bash
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe -t 127.0.0.1:5557 shell bm uninstall -n com.cloudchw.lanternlaw
```

## 日志查看

### 查看应用日志
```bash
# 查看所有 LanternLaw 日志
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe -t 127.0.0.1:5557 shell hilog | grep LanternLaw

# 查看错误日志
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe -t 127.0.0.1:5557 shell hilog | grep -i "lanternlaw.*error"

# 清除历史日志
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe -t 127.0.0.1:5557 shell hilog -r
```

### 筛选特定标签
```bash
# JSAPP 日志
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe shell hilog | grep "A03d00/JSAPP"

# 筛选错误和异常
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe shell hilog | grep -iE "TypeError|Error name|FATAL|exception"
```

## 签名配置

### 项目配置文件位置
```
build-profile.json5      # 包含签名配置（已在 .gitignore 中排除）
build-profile.json5.dist # 配置模板（可提交到仓库）
```

### 签名文件位置
```
signature/              # 签名文件目录（已在 .gitignore 中排除）
```

### 自动签名
使用 DevEco Studio 自动生成签名：
1. 打开 DevEco Studio
2. File -> Project Structure -> Signing Configs
3. 勾选 "Automatically generate signature"
4. 登录华为账号

## 快速部署流程

### 一键构建并部署到模拟器
```bash
# 构建
DEVECO_SDK_HOME="/d/ProgramFiles/DevEcoStudio/sdk" node /d/ProgramFiles/DevEcoStudio/tools/hvigor/bin/hvigorw.js assembleHap --mode module -p module=entry@default

# 安装并启动
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe app install entry/build/default/outputs/default/entry-default-unsigned.hap && \
/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe shell aa start -b com.cloudchw.lanternlaw -a EntryAbility

# 查看日志
sleep 2 && /d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe shell hilog | grep LanternLaw
```

## 应用信息

| 项目 | 值 |
|------|-----|
| Bundle Name | com.cloudchw.lanternlaw |
| Version | 1.0.0 (1000000) |
| Vendor | cloudchw |
| Main Ability | EntryAbility |
| SDK Version | 6.0.2(22) |

## 常见问题

### 构建失败：签名配置问题
```bash
# 检查签名配置是否正确配置
# 确保签名文件存在于 signature/ 目录
# 或使用 DevEco Studio 自动签名功能
```

### 安装失败：设备连接问题
```bash
# 检查设备列表
hdc list targets

# 确保 DevEco Studio 模拟器已启动
# 或真机已连接并开启 USB 调试
```

### 应用启动崩溃：查看崩溃日志
```bash
hdc shell hilog | grep -i "fatal\|crash\|exception"
```

## 开发调试

### DevEco Studio 位置
```
D:\ProgramFiles\DevEcoStudio
```

### SDK 位置
```
D:\ProgramFiles\DevEcoStudio\sdk
```

### HDC 工具路径
```
D:\ProgramFiles\DevEcoStudio\sdk\default\openharmony\toolchains\hdc.exe
```
