# Assertion (rflm_qlnk_ls_retry_cnt < 2) failed 分析报告

## 基本信息

| 项目 | 值 |
|------|-----|
| 断言字符串 | `Assertion (rflm_qlnk_ls_retry_cnt < 2) failed` |
| 字符串文件偏移 | `0x12D191A` (modem.b18) |
| 字符串长度 | 0x2E (46) 字节 |
| 字符串虚拟地址 | `0xC239191A` |
| 字符串物理地址 | `0x8FB9191A` |
| 源文件 | `qsf_hl_seq.c` |
| 固件文件 | modem.b18 (Segment #18, VA `0xC10C0000`, RW 数据段) |
| 目标平台 | Qualcomm Hexagon DSP (SM8150 / Xiaomi Raphael) |

## 断言表结构

该固件包含结构化的断言信息表，每条记录 12 字节：

```
struct assert_entry {
    uint32_t source_file_str_va;   // 源文件名字符串 VA
    uint32_t assert_msg_str_va;    // 断言消息字符串 VA  
    uint32_t line_info;            // bit[15:0] = 行号, bit[31:16] = flags
};
```

flags 含义：
- `0x0004` — **ASSERT** 类型条目
- `0x1802` — 日志/信息类型条目（非断言，仅记录）

## 关键断言表条目 (qsf_hl_seq.c 全部条目)

| 文件偏移 | 虚拟地址 | 文件名 | 断言/日志消息 | 行号 | 类型 |
|---------|---------|--------|-------------|------|------|
| 0x12D18DC | 0xC23918DC | qsf_hl_seq.c | Assertion (qdssEnabled <= 1) failed | 60 | ASSERT |
| **0x12D1F6C** | **0xC2391F6C** | **qsf_hl_seq.c** | **Assertion (rflm_qlnk_ls_retry_cnt < 2) failed** | **119** | **ASSERT** |
| 0x12D1F79 | 0xC2391F79 | qsf_hl_seq.c | QSF_HL_SEQ_LS_RETRY_TIMEOUT:Using MCPM WTR reset for timeout | 135 | LOG |
| 0x12D1F86 | 0xC2391F86 | qsf_hl_seq.c | QSF_HL_SEQ_LS_RETRY_TIMEOUT:Using soft WTR reset for mis-alignment | 144 | LOG |
| **0x12D1F93** | **0xC2391F93** | **qsf_hl_seq.c** | **Assertion (rflm_qlnk_ls_retry_cnt < 2) failed** | **191** | **ASSERT** |
| 0x12D1FA0 | 0xC2391FA0 | qsf_hl_seq.c | QSF_HL_SEQ_LS_START:retry attempted with 8kv2 family card | 229 | LOG |
| 0x12D1FAD | 0xC2391FAD | qsf_hl_seq.c | Assertion (rflmQlnkWtrDeviceFamily != RFLM_QLNK_WTR_FAMILY_8KV2) failed | 233 | ASSERT |
| 0x12D1FBA | 0xC2391FBA | qsf_hl_seq.c | Assertion (rflm_qlnk_sys_status.rflm_qlnk_link_status == RFLM_QLNK_LINK_STATUS_UP) failed | 272 | ASSERT |
| 0x12D1FC7 | 0xC2391FC7 | qsf_hl_seq.c | Assertion (rflm_qlnk_sys_status.rflm_qlnk_qsleep_status == RFLM_QLNK_QSLEEP_STATUS_ON) failed | 283 | ASSERT |
| 0x12D1FD4 | 0xC2391FD4 | qsf_hl_seq.c | Assertion ((rflm_qlnk_sys_status.rflm_qlnk_qsleep_status == ...)) failed | 284 | ASSERT |
| 0x12D1FE1 | 0xC2391FE1 | qsf_hl_seq.c | Assertion (rflm_qlnk_hs_retry_cnt < 10) failed | 303 | ASSERT |
| 0x12D1FEE | 0xC2391FEE | qsf_hl_seq.c | QSF_HL_SEQ_HS_RETRY_TIMEOUT:Retry not supported for 8kv1.x | 309 | LOG |
| 0x12D1FFB | 0xC2391FFB | qsf_hl_seq.c | QSF_HL_SEQ_HS_RETRY_TIMEOUT:Forcing QFPROM clk en via front door | 318 | LOG |

## 触发流程

```
Q-Link Link Start (LS) 启动
        │
        ▼
   ┌─────────────────────────────┐
   │   RFLM_QLNK_LS_START       │  ← RFLM Q-Link LS 序列开始
   │   (qsf_hl_seq_ls_start)     │
   └─────────────┬───────────────┘
                 │
        LS 操作超时或失败
                 │
                 ▼
   rflm_qlnk_ls_retry_cnt++
   (qsf_hl_seq_ls_retry_timeout)
        │
        ▼
   ┌─── Line 119 ─────────────────────────────────────┐
   │  assert(rflm_qlnk_ls_retry_cnt < 2)              │
   │                                                   │
   │  ● retry_cnt >= 2 → 断言触发！固件 Panic/重置     │
   │  ● retry_cnt < 2  → 继续恢复流程                  │
   └───────────────────────────────────────────────────┘
        │
        ▼
   ┌─── Line 135 ─────────────────────────────────────┐
   │  QSF_HL_SEQ_LS_RETRY_TIMEOUT:                     │
   │  使用 MCPM WTR reset 处理超时                      │
   └───────────────────────────────────────────────────┘
        │
        ▼
   ┌─── Line 144 ─────────────────────────────────────┐
   │  QSF_HL_SEQ_LS_RETRY_TIMEOUT:                     │
   │  使用 soft WTR reset 处理 mis-alignment            │
   └───────────────────────────────────────────────────┘
        │ (恢复操作后继续)
        ▼
   ┌─── Line 191 ─────────────────────────────────────┐
   │  assert(rflm_qlnk_ls_retry_cnt < 2)              │
   │  (第二次检查 — 恢复后再次验证)                     │
   │  retry_cnt >= 2 → 断言触发                        │
   └───────────────────────────────────────────────────┘
        │
        ▼
   ┌─── Line 229 ─────────────────────────────────────┐
   │  QSF_HL_SEQ_LS_START:                              │
   │  使用 8kv2 family card 重试                        │
   └───────────────────────────────────────────────────┘
        │
        ▼
   ┌─── Lines 233-284 ───────────────────────────────┐
   │  后续状态验证断言                                  │
   │  ● WTR device family 检查 (L233)                  │
   │  ● link status == UP 检查 (L272)                  │
   │  ● qsleep status 检查 (L283-284)                  │
   └───────────────────────────────────────────────────┘
        │
        ▼
   ┌─── Line 303 ─────────────────────────────────────┐
   │  assert(rflm_qlnk_hs_retry_cnt < 10)              │
   │  (HS = High Speed 阶段的重试计数器)                │
   └───────────────────────────────────────────────────┘
```

## 变量说明

### rflm_qlnk_ls_retry_cnt

| 项目 | 说明 |
|------|------|
| `rflm` | RF 前端模块 |
| `qlnk` | Q-Link — Qualcomm 专有高速数字接口，用于连接 MDM 和 WTR (RF 收发器) |
| `ls` | Link Start — 链路启动阶段 |
| `retry_cnt` | 重试计数器 |
| 阈值 | `< 2` (允许 1 次重试，第 2 次重试时触发断言) |

### 相关变量

| 变量 | 说明 |
|------|------|
| `rflm_qlnk_hs_retry_cnt` | HS (High Speed) 阶段重试计数器，阈值 `< 10` 在 Line 303 |
| `rflmQlnkWtrDeviceFamily` | WTR 设备家族类型，检查是否为 8KV2 |
| `rflm_qlnk_sys_status.rflm_qlnk_link_status` | 链路状态 (UP/DOWN) |
| `rflm_qlnk_sys_status.rflm_qlnk_qsleep_status` | QSleep 睡眠状态 |
| `rflm_qlnk_sys_status.rflm_qlnk_pll_gear_sel` | PLL 速率选择 |
| `rflm_qlnk_seq_qlink_cmd_id` | Q-Link 命令 ID |
| `rflm_qlnk_sdma_tfr_size_wrds` | SDMA 传输大小 |
| `rflm_qlnk_boot_type` | 启动类型 (Normal/QuickBoot) |
| `linkRetryCnt` | 链路重试次数 (阈值 3) |
| `qsleepCfg->qlnkScenario` | QSleep 场景配置 |
| `qsleepCfg->qlnkQslpLaneDisMsk` | QSleep 通道禁用掩码 |

### 变量解析线索

```
rflm_qlnk_sys_status 结构体字段 (从字符串推断):
├── rflm_qlnk_link_status       ← 链路连接状态 (UP/DOWN)
├── rflm_qlnk_qsleep_status     ← QSleep 休眠状态 (ON/ON_LEGACY_MODE/OFF)
├── rflm_qlnk_pll_gear_sel      ← PLL 时钟速率选择 (8.5Gbps/3Gbps/1.5Gbps)
└── rflm_qlnk_linux_metz_mode   ← Linux METZ 模式

枚举值:
RFLM_QLNK_LINK_STATUS_UP           = 1
RFLM_QLNK_LINK_STATUS_DOWN         = ?
RFLM_QLNK_QSLEEP_STATUS_ON         = ?
RFLM_QLNK_QSLEEP_STATUS_ON_LEGACY_MODE = ?
RFLM_QLNK_GEAR_SEL_8p5Gbps         = ?
RFLM_QLNK_GEAR_SEL_3Gbps           = ?
RFLM_QLNK_GEAR_SEL_1p5Gbps         = ?
RFLM_QLNK_WTR_FAMILY_8KV2          = ?
RFLM_QLNK_OP_MODE_HS2_1D1U         = HS2 1数据1时钟模式
RFLM_QLNK_OP_MODE_HS2_2D1U         = HS2 2数据1时钟模式
RFLM_QLNK_OP_MODE_HS2_3D1U         = HS2 3数据1时钟模式
```

## 触发条件

1. **首次 LS 失败** → `retry_cnt` 递增到 1 → 断言检查通过 (1 < 2)
2. **执行恢复操作** (MCPM WTR reset / soft WTR reset)
3. **再次 LS 失败** → `retry_cnt` 递增到 2 → **Line 119 断言触发** (2 < 2 = false)
4. 即使跳过 Line 119，Line 191 的二次检查同样会触发

## 可能的根本原因

| 类别 | 具体原因 | 说明 |
|------|---------|------|
| **RF 收发器** | WTR 未正确响应 | WTR (RF 收发器) 芯片初始化失败或不响应 MDM 的 Q-Link 请求 |
| **时钟/频率** | Q-Link PLL 未锁定 | PLL 无法锁定到目标频率，导致链路无法建立 |
| **校准数据** | NV 数据损坏 | RF 校准参数丢失或损坏，导致链路建立参数异常 |
| **固件加载** | Modem 固件加载异常 | PIL (Peripheral Image Loader) 加载 modem 固件时出错 |
| **硬件问题** | RF 电路物理损坏 | 主板 RF 部分物理损坏或连接不良 |
| **电源管理** | QSleep 状态异常 | 电源管理状态机进入异常状态，阻止 Q-Link 正常唤醒 |
| **时序问题** | XO 时钟漂移 | 睡眠/唤醒时序不同步，导致链路建立超时 |
| **版本不匹配** | WTR/MDM 固件版本不兼容 | WTR 固件与 Modem 固件版本不匹配 |

## 排查建议

### 1. 日志分析
- 查看 **QSF_HL_SEQ_LS_RETRY_TIMEOUT** 日志，确定使用的是哪种 reset 类型
- 检查 Line 135/144 的日志输出，确认 reset 后的状态
- 查看 Line 229 的日志，确定是否尝试了 8kv2 family card

### 2. NV 检查
- 检查 RF 校准数据是否完整
- 确认 Q-Link 相关的 NV 项是否配置正确

### 3. 硬件排查
- 检查 WTR 供电电压是否正常
- 确认 MDM 和 WTR 之间的差分信号线连接是否良好
- 检查 XO 时钟信号完整性

### 4. 固件版本
- 确认 modem 固件版本与 WTR 固件版本兼容
- 检查是否存在已知的 Q-Link 相关 bug 修复版本

## 相关日志字符串

```
Line 135:  QSF_HL_SEQ_LS_RETRY_TIMEOUT:Using MCPM WTR reset for timeout
Line 144:  QSF_HL_SEQ_LS_RETRY_TIMEOUT:Using soft WTR reset for mis-alignment
Line 229:  QSF_HL_SEQ_LS_START:retry attempted with 8kv2 family card
Line 309:  QSF_HL_SEQ_HS_RETRY_TIMEOUT:Retry not supported for 8kv1.x family
Line 318:  QSF_HL_SEQ_HS_RETRY_TIMEOUT:Forcing QFPROM clk en via front door
Line 272:  rflm_qlnk_check_mdm_cdr_pi_sync: WTR CDR pi sync check failed!
Line 283:  rflm_qlnk_check_mdm_cdr_pi_sync: MDM CDR pi sync check failed!
```

## 反编译分析

### 工具链

| 项目 | 说明 |
|------|------|
| 反编译器 | LLVM 21.1.8 + Hexagon 后端 (`llvm-objdump`) |
| 下载源 | `http://www.cluster.if.usp.br/sft/pub/tools/llvm/files/llvm-21.1.8-x86_64.tar.xz` |
| 架构 | Hexagon (v60/v65, `e_machine = 0xA4`) |
| ELF 重建 | 每个 LOAD 段创建独立 ELF 文件（单 PT_LOAD），以映射正确的虚拟地址 |

### 固件映像结构

| 段 | 文件 | 虚拟地址 | 大小 | 属性 |
|----|------|---------|------|------|
| #9 (code) | modem.b09 | `0xC08E0000` | 2.5 MB | R E |
| #10 (code) | modem.b10 | `0xC0B50000` | 1.3 MB | R E |
| #13 (code) | modem.b13 | `0xC0CA8440` | 842 KB | R E |
| #18 (data) | modem.b18 | `0xC10C0000` | 27 MB | RW |
| 其他 | b02,b04,b07,b08,b11,b12,b26,b29 | 见前文 | 合计 ~8 MB | R(E) |

### Hexagon immext 编码

Hexagon 使用**常量扩展机制** (immext) 编码 32 位立即数。指令不直接存储 32 位值，而是拆分为：

```
immext(#0xC239B080)  ──→  指令字 = 0x0C2366C2  (高 26 位地址)
└── 接下来的消费指令          ──→  提供低 6 位地址 + 寄存器
```

因此，**直接在二进制中搜索原始 32 位 LE 值无法找到指令流中的代码引用**。需通过 `llvm-objdump` 解码后的反汇编文本搜索。

### 关键反汇编发现

在 `modem.b09`（最大代码段，2.5MB）的反汇编中发现了 **64 处引用 `0xC239xxxx` 数据地址**，在 `modem.b10` 中发现 **2 处引用**。但这些引用全部指向 `0xC239Bxxx`/`0xC239Exxx`/`0xC2394xxx` 等地址范围内的日志/错误字符串，**没有任何直接引用指向断言表条目地址**（`0xC2391xxx` 范围）。

具体来说：

```
0xC094E44C:  immext(#0xC239B380)    ← 日志字符串引用
0xC094E450:  r0 = ##0xC239B3B5;     ← 日志消息字符串
             r2 = r3
0xC094E514:  call 0xC0823358        ← 日志/断言处理函数
             immext(#0xC239B400)    ← 日志字符串引用
```

### 断言机制架构

断言表条目**不直接被代码引用**的原因：Qualcomm Hexagon 固件使用**表注册机制**。断言处理流程如下：

```
编译时:
  ASSERT 宏 → 生成 12 字节 assert_entry 结构体
           → 由链接器收集到 `.assert_tbl` section（集中放置）

运行时:
  assert_handler (0xC0823358)
      ↓
  通过注册的 assert_table 指针遍历条目
      ↓
  匹配后读取 filename + message + line 并输出日志/触发 panic
```

证实了断言表是静态链接的元数据表，断言处理函数通过**表基地址 + 偏移**而非逐个绝对地址引用单个条目。

### 反汇编识别的 assert_handler

```
0xC0823358  → 被调用 30+ 次，参数为 0xC239xxxx 格式化字符串
              每次调用前使用 immext 加载日志/错误字符串地址
              该函数是固件的通用日志/断言处理入口
```

该地址位于段 #4 (`modem.b04`, RWE 段)，属于 QURT 运行时基础设施代码。

## 结论

### 触发条件（已确认）

1. **Q-Link Link Start (LS) 启动失败** → `rflm_qlnk_ls_retry_cnt` 递增
2. **重试后再次失败** → `rflm_qlnk_ls_retry_cnt == 2`
3. **Line 119 断言**: `assert(rflm_qlnk_ls_retry_cnt < 2)` → 触发 panic
4. **即使跳过 L119**: Line 191 二次检查同样会触发

### 根本原因分类

1. **RF/WTR 硬件** — WTR 收发器未响应或初始化异常
2. **PLL/时钟** — Q-Link PLL 未能锁定（时钟频率 8.5/3/1.5 Gbps）
3. **校准数据** — NV 参数损坏或丢失
4. **电源管理** — QSleep 状态机异常（Legacy mode / Lane disable）
5. **固件不匹配** — WTR 固件与 Modem 固件版本冲突
6. **硬件故障** — 差分信号线连接不良
7. **时序同步** — XO 时钟漂移导致 Wakeup 时序失配
8. **CDR 同步失败** — CDR PI sync 检查失败 (Line 272/283)

### 排查建议

1. 优先检查 **RF 校准（NV）数据**和 WTR 固件版本
2. 使用 QXDM 工具捕获 **LS_RETRY_TIMEOUT 日志**，区分 reset 类型
3. 检查硬件 **WTR 供电电压和差分信号**完整性
4. 尝试更新 Modem + WTR 固件到匹配版本

## Linux vs Android 环境差分分析（关键场景）

### 现象总结

| 环境 | 基带工作状态 | Modem 固件 | SIM 卡 | 硬件平台 | 触发时机 |
|------|------------|-----------|-------|---------|---------|
| **Android** | ✅ 上网/通话/短信均正常 | `modem.mdt` (相同) | 同一张卡 | 同一台设备 | 开机自动初始化 |
| **Linux** | ❌ Q-Link LS 断言触发 panic | `modem.mdt` (相同) | 同一张卡 | 同一台设备 | **用户打开移动宽带→搜网时触发** |

### 核心推断

**最关键线索**：断言不是在开机时触发，而是在用户打开 Ubuntu 设置→移动宽带→搜网时触发。

这意味着：
1. **modem 冷启动成功** — 开机时 Q-Link LS 初始化成功（否则开机就 panic）
2. **WTR 硬件正常** — Android 下基带正常工作已验证
3. **NV 数据正常** — 已通过写入恢复验证
4. **问题出在 QSleep 唤醒后的 Q-Link 重连** — modem 从低功耗状态恢复时 LS 失败

### 正常流程 vs 异常流程

```
冷启动 (开机):
  PIL 加载 modem.mdt → modem DSP 启动 → Q-Link LS 成功 → WTR 就绪 → 入网
                                                                         ↓
                                                          modem 进入 QSleep (低功耗待机)
                                                                         ↓
用户打开移动宽带 → ModemManager 发 QMI 搜网命令
                                                    ┌──────────────────────────────────────┐
                                                    │           QSleep 唤醒流程             │
                                                    │                                      │
  Android:                                           Linux (失败):                         │
  AP→SMP2P 唤醒信号 → modem 唤醒                      AP→SMP2P 唤醒信号 → modem 唤醒        │
      ↓                                                   ↓                                │
  Q-Link LS Resume → WTR 响应 ✅                         Q-Link LS Resume → WTR 无响应 ❌    │
      ↓                                                   ↓                                │
  搜网正常                                               retry_cnt++ → ≥2                   │
                                                           ↓                                │
                                                       assert() → PANIC                    │
                                                    └──────────────────────────────────────┘
```

### QSleep 唤醒机制详解

Qualcomm modem 在空闲时会进入 QSleep（深度睡眠）以省电，此时：

```
QSleep 状态下:
  ├── Modem DSP 时钟门控 (clock gated)
  ├── Q-Link 链路进入低功耗模式 (lane powered down)
  └── WTR 进入休眠 (部分电源域关闭)

唤醒过程:
  1. AP 侧通过 SMP2P 发送 Wakeup Request
  2. Modem DSP 恢复时钟
  3. Modem DSP 重新建立 Q-Link LS 连接 ← ❌ 此处失败
     └── 需要 WTR 从休眠恢复并响应握手
  4. 如果 Q-Link LS 失败 → retry_cnt++
     └── retry_cnt ≥ 2 → assert → PANIC
```

### Q-Link LS Resume 失败的可能原因

| 原因 | 说明 | 为什么 Android 正常 |
|------|------|-------------------|
| **QSleep 配置不匹配** | ModemManager/QMI 发送的唤醒命令格式或参数与 modem 固件预期不符 | Android RIL 使用正确的 QMI 唤醒序列 |
| **SMP2P 唤醒信号异常** | AP 发送的 wakeup 信号时序或电平不对，modem 未完全唤醒 | Android 内核有完整的 SMP2P 休眠/唤醒驱动支持 |
| **WTR QSleep 恢复失败** | WTR 从休眠恢复后 PLL 未锁定或 CDR 未同步 | Android 下 WTR firmware 正确处理了恢复流程 |
| **时钟恢复时序** | XO/REF_CLK 在唤醒时未稳定就发起 LS | Android 的 RPMh 时钟管理确保了时序 |
| **Q-Link lane 训练失败** | 低功耗模式下 lane 被关闭，唤醒后重新训练失败 | Android 通过正确的寄存器序列恢复 lane |

### 与 ModemManager/QMI 的关联

Linux 下搜网操作通过 ModemManager → libqmi → QMI 通道与 modem 通信：

```
ModemManager (用户空间)
    ↓
libqmi (QMI 协议栈)
    ↓
QCUSBNet / QMI 内核驱动
    ↓
SMP2P / GLINK 通道 (IPC)
    ↓
Modem DSP
    ↓
QSleep 唤醒 → Q-Link LS Resume
```

如果 QMI 通道未正确实现 QSleep 唤醒协商，或 ModemManager 在 modem 未完全唤醒时就下发搜网命令，可能导致 Q-Link LS 时序异常。

### 最终诊断

| 可能性 | 原因 | 验证方法 |
|--------|------|---------|
| **🔥 最可能** | **QSleep WTR 唤醒失败** — modem 从 QSleep 唤醒后，重新建立 Q-Link LS 时 WTR 未正确响应（PLL 未锁定/CDR 失步/wakeup 时序不对） | 对比 Android/Linux 下搜网时的 QXDM log，检查唤醒序列 |
| **🔥 很可能** | **QMI/SMP2P 唤醒协商不完整** — ModemManager 或内核 QMI 驱动在唤醒时缺少某些握手步骤 | `dmesg \| grep -E "qmi|smp2p|glink\|mba"` 检查唤醒交互日志 |
| **⏺ 需排查** | **QSleep 状态机残留** — modem 在 Linux 下 boot 后进入的 QSleep 模式与 Android 不同（如 lane disable mask 配置差异） | 检查 NV 中 QSleep 相关配置项 |
| **⏺ 需排查** | **时钟门控差异** — Linux 下某些 GCC 时钟门控策略导致唤醒时时钟恢复时序不对 | 对比 RPMh 时钟请求日志 |
| ❌ **冷启动初始化** | **已排除** — 如果在开机时就失败，断言会在 boot 时触发，而不是在用户操作搜网时 | — |
| ❌ **NV 数据** | **已排除** — 用户实测恢复备份后基带恢复，证明 modem 能正确读取 flash 上的 NV 数据 | — |
| ❌ **硬件** | **已排除** — Android 下基带上网/通话/短信均正常 | — |

### Linux 排查建议

1. **确认断言触发时的 dmesg 日志**：
   ```bash
   # 触发断言后抓取全部日志
   dmesg -T | grep -E "(mss|modem|subsys|qmi|smp2p|glink|pil)" > modem_log.txt
   ```

2. **检查 ModemManager 状态**：
   ```bash
   mmcli -m 0   # 查看 modem 状态
   mmcli -m 0 --command='--verbose'  # 启用详细日志
   ```

3. **检查 QMI 内核驱动状态**：
   ```bash
   ls /dev/ | grep qmi
   # 或检查 cdc-wdm 设备
   ls /dev/cdc-wdm*
   ```

4. **检查 SMP2P/GLINK 通道**：
   ```bash
   dmesg | grep -E "smp2p|glink"
   ```

5. **对比搜网时的 QXDM log**：在 Android 和 Linux 下分别抓取搜网时的 modem 日志，对比 QSleep 唤醒序列差异

6. **尝试禁掉省电选项**：
   ```bash
   # 通过 ModemManager 禁掉低功耗模式
   mmcli -m 0 --set-power-state=high
   # 或通过 echo 控制
   echo on > /sys/devices/platform/soc/*/mss_power/state 2>/dev/null
   ```

## 附加说明

1. 该分析基于 Qualcomm Hexagon DSP 固件二进制 (`modem.b18`) 的静态分析，包含 ELF 结构解析、字符串特征匹配和 Hexagon 反汇编验证
2. 使用 `hexagon-llvm-objdump`（LLVM 21.1.8）对 11 个代码段进行完整反汇编
3. 该断言在 `qsf_hl_seq.c` 中出现了两次（Line 119 和 Line 191），分别在初始失败和恢复操作后进行检查
4. 同一个源文件中的另一个 HS 阶段重试计数器 `rflm_qlnk_hs_retry_cnt` 的阈值为 10（Line 303）
5. 断言处理函数 `0xC0823358` 被 30+ 次调用，是固件通用日志断言基础设施的一部分

---

## 完整启动链路分析与根因确认（v2 — 部分结论已被 v3 修正）

> **v3 修正**：ModemManager **不是根因**；`qmicli` 单独 OFFLINE→ONLINE 同样触发断言。  
> 本节 MM/U-Boot 链路分析仍有参考价值，但「改 MM 流程即可修复」的结论已废弃。见文末 **v3**。

> 基于 XBL/ABL/U-Boot/ModemManager 源码的全链路分析。

### 启动链路对比

```
Android: XBL → ABL → kernel + DT → Android RIL (经 QMI 直接使用 modem)
Linux:   XBL → ABL → U-Boot → EFI stub → kernel + DT → ModemManager (qcom-soc plugin)
```

### XBL/ABL 检查结论

- **XBL** (Xiaomi BootLoader) — 初始化 PLL/DDR/PMIC，加载 ABL。签名 ELF，无法反编译。
- **ABL** (Android BootLoader) — 加载 boot image（内核+DT）、选择 slot、设置 AOP mailbox 通信。
- ABL **不直接操作** MSS/WTR 电源域或 Q-Link GPIO。MSS 电源管理完全通过内核 PIL 驱动（SCM/AOP 调用）完成。

### U-Boot 检查结论

对 `/home/nuanyang/k20/xiaomi_raphael_uboot` 完整源码审查，确认 U-Boot：

| 组件 | 状态 | 说明 |
|------|------|------|
| MSS 电源域 (GDSC) | ❌ 不存在 | `clock-sm8150.c` 的 power_domains 只有 USB/PCIE/UFS/EMAC，无 MSS |
| MSS 时钟 | ❌ 不存在 | GCC 时钟列表没有 `GCC_MSS_*` |
| AOP QMP 通信 | ❌ 不存在 | 整个 U-Boot 没有 `aoss_qmp` 驱动 |
| SCM 安全调用 | ❌ 不存在 | 没有 `qcom_scm` 驱动 |
| QLINK GPIO 操作 | ❌ 不存在 | GPIO 61/62/63 从未被触及 |
| MSS 复位操作 | ❌ 不存在 | 没有 `GCC_MSS_BCR` |
| EFI 退出回调 | ❌ 不存在 | 没有 `ExitBootServices` 钩子 |
| Raphael 板级初始化 | ❌ 不存在 | `qcom_board_init()` 和 `qcom_late_init()` 均为默认空函数 |

**结论：U-Boot 不操作任何 MSS/WTR 相关硬件，不是导致断言的原因。**

### ModemManager 源码分析

关键文件：`mm/src/ModemManager/src/plugins/qcom-soc/mm-broadband-modem-qmi-qcom-soc.c`

Raphael 专用的 `modem_power_up` 钩子覆盖了标准 QMI 上电流程：

```
raphael_modem_power_up()                     ← 覆盖 MMIfaceModem::modem_power_up
  ├── Step MODES: mm_shared_qmi_set_current_modes(self, LTE-only, LTE-only)
  │   └── 通过 QMI NAS 命令限制到 LTE-only
  ├── Step BANDS: mm_shared_qmi_set_current_bands(self, 10 LTE bands)
  │   └── 通过 QMI NAS 命令限制频段
  └── Step ONLINE: parent_modem_power_up(self)
      └── mm-broadband-modem-qmi.c: common_power_up_down_off(self, QMI_DMS_OPERATING_MODE_ONLINE)
          └── QMI 客户端 → DMS.SetOperatingMode(ONLINE)
              └── modem FW 响应 → 尝试重建 Q-Link LS
```

### 你的工具脚本分析

`mm/` 目录下的脚本执行顺序：

```
启动时（systemd 服务）:
  1. raphael-modem-offline.service
     → wait_modem() + wait_qmi()
     → DMS.SetOperatingMode(OFFLINE)     ← ★ 关键步骤
     → 轮询确保 modem 保持 OFFLINE

  2. raphael-lte-prepare.service
     → wait_qmi()
     → DMS.SetOperatingMode(OFFLINE) 再次确认
     → NAS.SetSystemSelectionPreference(LTE, automatic)
     → mmcli -m 0 --set-current-bands=<bands>

用户触发:
  3. raphael-rf-enable.sh / mmcli -m 0 --enable
     → MM Raphael plugin: NAS Set Modes (LTE)
     → MM Raphael plugin: NAS Set Bands (LTE bands)
     → QMI DMS.SetOperatingMode(ONLINE)  ← ★ 此处触发断言
```

### 核心差异：Android vs Linux

| 环节 | Android (RIL) | Linux (ModemManager) |
|------|---------------|---------------------|
| **Modem 冷启动** | PIL 加载 → modem 进入 ONLINE | PIL 加载 → modem 进入 ONLINE |
| **步骤 2** | RIL 直接发送 NAS/WDS QMI 命令 | **`DMS.SetOperatingMode(OFFLINE)`** |
| **步骤 3** | Modem 持续保持 ONLINE | OFFLINE 状态下设置 bands/modes |
| **步骤 4** | — | **`DMS.SetOperatingMode(ONLINE)`** → Q-Link LS 重试 |
| **WTR 状态** | 仅冷启动初始化 1 次 | 冷启动初始化 + **OFFLINE→ONLINE 再初始化 1 次** |
| **Q-Link LS** | 仅 1 次（冷启动） | **2 次**（冷启动 + 状态恢复） |

### 断言触发完整路径

```
  Kernel PIL 加载 modem.mdt
       ↓
  Modem DSP 冷启动
       ↓
  Q-Link LS 成功 → WTR 初始化完成
       ↓
  (time passes...)
       ↓
  ① raphael-modem-offline.sh:
     DMS.SetOperatingMode(OFFLINE)
       ↓
     Modem FW 对 WTR 执行 QSleep/power-down:
     ├── Q-Link 链路进入低功耗 (lane powered down)
     ├── WTR 部分电源域关闭
     ├── RFFE 配置可能丢失
     └── XO 时钟可能被 gate
       ↓
  ② raphael-lte-prepare.sh:
     在 OFFLINE 状态下配置 NAS preferences
       ↓
  ③ mmcli -m 0 --enable:
     a. Raphael plugin: NAS Set Modes (LTE)
     b. Raphael plugin: NAS Set Bands (10 LTE bands)
     c. QMI: DMS.SetOperatingMode(ONLINE)
        ↓
     Modem FW 恢复流程:
        ├── 解除时钟门控
        ├── 恢复 Q-Link PHY
        ├── 发送 Q-Link Link Start (LS) ← ★★★
        │   └── 等待 WTR PHY 同步
        │       ├── 超时 → retry_cnt = 1
        │       ├── MCPM WTR reset (qsf_hl_seq.c:135)
        │       ├── 重试 LS → 超时 → retry_cnt = 2
        │       ├── Soft WTR reset (qsf_hl_seq.c:144)
        │       └── 重试 LS → 超时 → retry_cnt = 2
        └── qsf_hl_seq.c:119:
            assert(rflm_qlnk_ls_retry_cnt < 2) → PANIC
```

### WTR Q-Link LS 唤醒失败的潜在原因

#### 1. RFFE 总线状态丢失
- **原理**: OFFLINE 时 modem FW 可能将 WTR 的 RFFE (RF Front End) 寄存器配置重置为默认值。ONLINE 后 modem FW 尝试通过 RFFE 总线重写配置，但重写序列与 WTR 当前状态不匹配。
- **证据**: `qsf_hl_seq.c` 行 135 有 `"Using MCPM WTR reset for timeout"`，说明固件意识到 RFFE/WTR 需要复位才能恢复。
- **类比**: 相当于系统从挂起恢复后，外设寄存器状态与驱动预期不一致。

#### 2. Q-Link PHY 状态机不一致
- **原理**: Q-Link 是一种高速数字接口（SerDes-like），WTR 和 Modem DSP 两侧都有复杂的 PHY 状态机。OFFLINE→ONLINE 转换时，两侧状态机可能进入不同的 sub-state，导致 Link Start 握手无法完成。
- **Q-Link LS 协议**: 涉及 CDR (Clock Data Recovery) 同步、lane 对齐、training pattern 交换。任何一步失败都会导致超时。
- **证据**: 断言表中 Line 272 的 `"Assertion (rflm_qlnk_sys_status.rflm_qlnk_link_status == RFLM_QLNK_LINK_STATUS_UP)"` 进一步验证了链路状态检查。

#### 3. PMIC/WTR 电源域时序
- **原理**: OFFLINE 后 AOP/RPMh 可能将供给 WTR 的 PMIC LDO 降压或关闭。ONLINE 时上电顺序（power rail ramp-up timing）不满足 WTR 要求，导致 WTR 内部某些电路未完全复位。
- **SM8150 关键电源**: WTR 需要 `vdda_qlink_lv`（来自 `vreg_l5a_0p875`）、`vdda_qlink_hv_ck`（来自 `vreg_l3c_1p2`）等专用 LDO。
- **Android vs Linux 差异**: RPMh 驱动配置、regulator 约束可能导致上电时序差异。
- **设备树检查**: 上游 kernel DT 中 `vreg_l5a_0p875` 设置了 `regulator-allow-set-load` 和 LPM/HPM 切换，可能影响 WTR 供电稳定性。

#### 4. Clock PLL 锁定超时
- **原理**: WTR 的 Q-Link PHY 需要参考时钟生成高速串行时钟（8.5/3/1.5 Gbps）。OFFLINE 时参考时钟可能被 gate，ONLINE 后 PLL 重新锁定需要一定时间。如果 modem FW 在 PLL 未锁定时就发起 LS，握手必然失败。
- **关键时钟**: `vreg_l3c_1p2` 标签为 `vdda_qlink_hv_ck`，明确是 Q-Link HV（High Voltage）时钟域的供电。
- **可能的根因**: PLL 重锁定时间比 modem FW 预期的要长，或者 PLL 锁定指示信号未正确传递。

### ~~推荐修复方向（v2，已废弃）~~

> **注意**：以下 A/B/C 方案仅为**绕过触发条件**的权宜之计，**不是根因修复**。  
> 实测用 `qmicli` 直接执行 `DMS.SetOperatingMode(OFFLINE→ONLINE)` 同样会触发断言，与 ModemManager 无关。  
> 见下文 **v3：根因修正**。

#### ~~方案 A：跳过 OFFLINE 状态~~（绕过，非修复）
#### ~~方案 B：使用 RESET 替代 OFFLINE→ONLINE~~（绕过，非修复）
#### ~~方案 C：冷启动后不操作 modem~~（绕过，非修复）

#### 方案 D：排查电源/时钟差异（**根因修复方向，保留**）
对比 Android 和 Linux 下 RPMh 寄存器状态、PMIC LDO 电压设置和 GCC 时钟门控策略。重点检查 `vreg_l5a_0p875`（`vdda_qlink_lv`）和 `vreg_l3c_1p2`（`vdda_qlink_hv_ck`）的上电时序和电压值。

---

### 最终结论（v2，部分过时）

| 项目 | 值 |
|------|-----|
| **断言条件** | `rflm_qlnk_ls_retry_cnt < 2` 在 `qsf_hl_seq.c:119` 触发 |
| **直接原因** | modem FW 在 RF 重新上电（OFFLINE→ONLINE 或等效路径）时，Q-Link LS 重试 2 次均超时 |
| **根本原因** | **WTR 在 QSleep/power-down 后无法正确恢复 Q-Link 链路**（RFFE/PHY/PMIC/PLL 之一或组合） |
| **触发入口** | 任何导致 modem RF 重新 enable 的操作（`qmicli` / MM / 设置界面搜网） |
| **~~环境差异~~** | ~~Android RIL 不做 OFFLINE→ONLINE~~ → Android 未走 WTR 恢复路径，不代表 Linux 栈本身有误 |
| **排除因素** | ✅ 硬件正常 | ✅ NV 数据正常 | ✅ U-Boot 无关 | ✅ 冷启动初始化正常 |

---

## 根因修正（v3 — 2026-06-26）

### 关键纠正：ModemManager 不是根因

| 误区（v2） | 事实（v3） |
|-----------|-----------|
| Linux ModemManager 的 OFFLINE 流程导致断言 | **`qmicli -d qrtr://0 --dms-set-operating-mode=offline` 后再 `online` 同样死机** |
| 改 MM 脚本/插件即可修复 | MM 只是众多触发路径之一；**问题在 modem 固件 + AP 平台层** |
| Android 正常因为 RIL 更"正确" | Android **冷启动后保持 ONLINE**，从未触发 WTR Q-Link **二次 LS 恢复** |

**结论**：断言的充分条件是 **modem 固件尝试在 WTR 已 power-down 后重新建立 Q-Link LS，且 WTR 未能在 2 次重试内响应**。  
用户空间用 MM 还是 qmicli 只决定**何时**触发，不决定**能否**成功。

### 断言本质（modem 固件内部）

```
Modem 冷启动
  → Q-Link LS #1 成功（WTR 初始化 OK）     ← 开机不 panic 的原因
  → modem 进入 QSleep / RF standby
  → 用户或脚本请求 RF 重新 enable
      （DMS OFFLINE→ONLINE / NAS 搜网 / mmcli --enable）
  → modem FW: qsf_hl_seq_ls_start()
  → WTR 从休眠唤醒，应响应 Q-Link 握手
  → 超时 ×2 → rflm_qlnk_ls_retry_cnt == 2
  → assert(rflm_qlnk_ls_retry_cnt < 2) → remoteproc crash
```

固件在超时后会尝试 MCPM WTR reset（L135）和 soft WTR reset（L144），仍失败后触发断言。  
说明 **WTR 侧 PHY/PLL/CDR 在 Linux 平台环境下无法完成 LS 恢复**，而非 QMI 命令格式问题。

### Linux 平台层可疑点（AP 内核 / DT）

modem 固件通过 RPMh/AOP 管理 WTR 电源，但 AP 侧 regulator 框架和时钟配置会影响 rail 实际状态：

| 层级 | 节点/资源 | Raphael 现状 | 风险 |
|------|----------|-------------|------|
| **PMIC LDO** | `vreg_l5a_0p875` → `vdda_qlink_lv` | 允许 LPM/HPM 切换，无 always-on | OFFLINE 后 rail 可能降压，WTR Q-Link LV 域不稳定 |
| **PMIC LDO** | `vreg_l3c_1p2` → `vdda_qlink_hv_ck` | 无 always-on | Q-Link PHY HV/PLL 参考域可能被 gate |
| **RPMh PD** | `mss.lvl` | remoteproc 已关联 `SM8150_MSS` | modem 运行时应保持；需对比 OFFLINE 前后 `/sys/kernel/debug/rpmh/regulator-summary` |
| **RPMh 时钟** | `qphy.lvl` / `RPMH_QLINK_CLK` | **DT 无 consumer** | SM8150 mainline 未像 UFS 那样显式持有 qlink 时钟 |
| **GPIO** | GPIO 61/62 QLINK_REQUEST/ENABLE, GPIO 63 WMSS_RESET_N | 仅有 line-name，**无 pinctrl** | 需确认 WMSS_RESET_N 未被误拉低 |
| **IPA SMP2P** | modem HWP clock query | `modem-ipa-fixes.patch` 已修 | OFFLINE→ONLINE 时 modem 会再次 query；未打补丁则 HWP 超时可能加剧 RF 异常 |

### 已实施的内核修复

补丁：`patchs/qlink-wtr-fix.patch`（随 `raphael-kernel_build.sh` 自动 apply）

```dts
/* vreg_l5a_0p875 — vdda_qlink_lv */
regulator-boot-on;
regulator-always-on;
/* 移除 LPM 模式 — Q-Link 需要稳定 HPM */

/* vreg_l3c_1p2 — vdda_qlink_hv_ck */
regulator-boot-on;
regulator-always-on;
```

目标：确保 WTR Q-Link 专用 LDO 在 modem RF 状态切换全程保持供电，避免 Linux regulator 框架将 rail 切入 LPM 导致 LS 握手失败。

### 验证步骤（修内核后）

```bash
# 1. 刷入含 qlink-wtr-fix + modem-ipa-fixes 的新内核
# 2. 冷启动，确认 modem running
qmicli -d qrtr://0 --dms-get-operating-mode

# 3. 最小复现（不依赖 MM）
qmicli -d qrtr://0 --dms-set-operating-mode=offline
sleep 2
qmicli -d qrtr://0 --dms-set-operating-mode=online
# 期望：remoteproc 保持 running，无 assert

# 4. 若仍 crash，抓平台状态对比
grep -iE 'qlink|mss|modem|fatal' /sys/kernel/debug/regulator/regulator_summary
dmesg | grep -iE 'rpmh|regulator|ipa.*smp2p|modem'
```

### 若 DT 修复仍不足 — 后续排查优先级

1. **QXDM / modem 日志**：确认 LS_RETRY_TIMEOUT 走的是 MCPM reset 还是 soft reset；CDR pi sync 是否失败（L272/L283）
2. **对比 Android 同机 OFFLINE→ONLINE**（在 Android 下用 qmicli 测）：若 Android 也 crash → 纯固件路径问题；若 Android 正常 → 继续查 Linux DT/regulator/IPA 差异
3. **`mss.lvl` / `qphy.lvl` RPMh 状态**：OFFLINE 前后是否被 AP 侧错误降级
4. **GPIO 63 WMSS_RESET_N**：用 `gpioinfo` 确认 WTR 未处于 reset

### v3 最终结论

| 项目 | 值 |
|------|-----|
| **断言条件** | `rflm_qlnk_ls_retry_cnt < 2` @ `qsf_hl_seq.c:119/191` |
| **本质问题** | **WTR Q-Link Link Start 恢复失败**（modem 固件层） |
| **触发方式** | 任何 RF re-enable（`qmicli` / MM / UI 搜网） |
| **与 MM 关系** | **无关**（MM 非根因，仅为触发入口之一） |
| **修复层级** | **内核 DT + IPA SMP2P**（平台供电/时钟），不是 userspace 流程 |
| **已提交修复** | `qlink-wtr-fix.patch`：Q-Link LDO always-on + 禁 LPM |
| **成功标准** | `qmicli` OFFLINE→ONLINE 后 modem 不 crash，Q-Link LS 恢复成功 |
