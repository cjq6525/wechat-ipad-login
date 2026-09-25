# WeChat iPad Login Tweak

让 iPhone 上的微信被服务端识别为 iPad 设备，从而支持 iPad 多设备同时登录。UI 界面保持 iPhone 布局不变。

## 前置条件

- iPhone 14 Pro Max / iOS 16.2 / Dopamine 越狱
- 已安装 Theos（rootless 模式）
- WeChat（com.tencent.xin）

## 编译

```bash
make package FINAL=1
```

## 安装

```bash
make install FINAL=1
```

安装后微信会自动重启。重新登录微信即可看到 iPad 已上线提示（另一台设备）。

## 开关控制

通过 SSH 在终端执行：

```bash
# 关闭
defaults write com.user.wechatipadlogin enabled -bool false
killall WeChat

# 开启
defaults write com.user.wechatipadlogin enabled -bool true
killall WeChat
```

## 项目结构

```
wechat-ipad-login/
├── Makefile              # Theos 构建配置（rootless）
├── control               # deb 包描述
├── WeChatIPadLogin.plist # 过滤器：仅注入 com.tencent.xin
├── Tweak.x               # Hook 逻辑
└── README.md
```

## 工作原理

| Hook 点 | 伪造值 | 用途 |
|---------|--------|------|
| `sysctlbyname("hw.machine")` | `iPad16,3` | 主指纹：设备型号标识 |
| `sysctlbyname("hw.model")` | `J720AP` | 辅助指纹：内部硬件代号 |
| `sysctl(CTL_HW, HW_MACHINE)` | `iPad16,3` | 兼容旧版 sysctl 调用 |
| `sysctl(CTL_HW, HW_MODEL)` | `J720AP` | 兼容旧版 sysctl 调用 |
| `uname()->machine` | `iPad16,3` | utsname 备用指纹 |
| `[UIDevice model]` | `"iPad"` | UIKit 层设备类型字符串 |

注意：`userInterfaceIdiom` 未被 Hook，因此 UI 仍为 iPhone 布局。

## 更改 iPad 型号

编辑 `Tweak.x` 顶部的 `#define` 即可：

```c
#define FAKE_MACHINE        "iPad13,4"   // iPad Pro 11" M1
#define FAKE_INTERNAL_MODEL "J617AP"
```

常用 iPad 型号：

| machine | 型号 | 内部代号 |
|---------|------|----------|
| iPad16,3 | iPad Pro 13" M4 | J720AP |
| iPad14,3 | iPad Pro 11" M2 | J617AP |
| iPad13,4 | iPad Pro 11" M1 | J617AP |
| iPad13,18 | iPad 10th Gen | J272AP |
| iPad14,6 | iPad mini 6 | J311AP |

## 免责声明

仅供学习和研究使用。使用此插件可能违反微信用户协议，账号存在被限制的风险，请自行承担。
