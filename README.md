# Artix-7 Hex ROM Reader プロジェクト

[![FPGA](https://img.shields.io/badge/FPGA-Xilinx%20Artix--7-red)](https://www.xilinx.com/)
[![Language](https://img.shields.io/badge/Language-SystemVerilog-blue)](https://en.wikipedia.org/wiki/SystemVerilog)
[![Tool](https://img.shields.io/badge/Tool-Vivado-orange)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Toolchain](https://img.shields.io/badge/Toolchain-RISC--V%20GCC-green)](https://github.com/riscv-collab/riscv-gnu-toolchain)

## 📝 プロジェクト概要

**Xilinx Artix-7 FPGA (Basys 3 ボード)** を使用したROM読み出し・LED表示システムです。RISC-Vツールチェーンでコンパイルしたデータ配列をBlock RAMに初期化し、ダミーCPUで順次読み出してLEDに表示します。FPGA上でのメモリ初期化、同期読み出し、クロス技術（ソフトウェアとハードウェアの連携）の基礎を学習しました。

> **Note**: このリポジトリは個人的な学習成果の記録・共有を目的としています。

### 🎯 学習目標

- ✅ Block RAM (BRAM) の推論と初期化 (`$readmemh`) の理解
- ✅ RISC-V GCC を用いたクロスコンパイル環境の構築
- ✅ リンカスクリプトによるメモリレイアウト制御
- ✅ ダミーCPU (アドレスカウンタ) の実装
- ✅ 低速クロック生成 (分周器) の実装
- ✅ 階層的モジュール設計 (トップモジュール、メモリ、リーダー)
- ✅ SystemVerilog による合成可能なRTL記述の習得
- ✅ セルフチェック機能付きテストベンチの作成
- ✅ 実機でのLEDパターン表示動作確認 **（予定）**

---

## 🛠️ 開発環境

| 項目 | 詳細 |
|------|------|
| **開発ボード** | Digilent Basys 3 |
| **FPGA デバイス** | Xilinx Artix-7 XC7A35T-1CPG236C |
| **設計言語** | SystemVerilog (IEEE 1800-2017) |
| **開発ツール** | Xilinx Vivado Design Suite |
| **制約言語** | Xilinx Design Constraints (XDC) |
| **シミュレータ** | Vivado Simulator (XSIM) |
| **ソフトウェアツールチェーン** | RISC-V GNU Toolchain (riscv64-unknown-elf-gcc) |
| **メモリ仕様** | 4KB ROM (1024 words × 32-bit), Byte-addressable |

---

## 📂 プロジェクト構成

```
Artix7_Hex_Rom_Reader/
├── Artix7_Hex_Rom_Reader.xpr          # Vivado プロジェクトファイル
├── Artix7_Hex_Rom_Reader.srcs/
│   ├── sources_1/new/
│   │   └── (RTLファイルは rtl/ フォルダで管理)
│   ├── sim_1/new/
│   │   └── (テストベンチは sim/ フォルダで管理)
│   └── constrs_1/new/
│       └── Basys3_Master.xdc          # 【制約ファイル】ピンアサイン・クロック定義
├── rtl/
│   ├── load_rom.sv                    # 【RTL】メモリモジュール (prx32_memory)
│   ├── rom_reader.sv                  # 【RTL】ダミーCPU (アドレスカウンタ)
│   └── basys3_top.sv                  # 【RTL】トップモジュール (全体統合)
├── sim/
│   └── tb_load_rom.sv                 # 【テストベンチ】セルフチェック機能付き
├── sw/
│   ├── main.c                         # 【C言語】LEDパターン定義 (配列データ)
│   ├── linker.ld                      # 【リンカスクリプト】メモリレイアウト定義
│   ├── Makefile                       # 【ビルドスクリプト】rom.hex生成
│   └── rom.hex                        # 【生成物】メモリ初期化ファイル (32-bit幅)
└── README.md                          # このファイル
```

---

## 🔧 設計仕様

### 📦 メモリ仕様

| パラメータ | 値 |
|-----------|-----|
| **容量** | 4KB (1024 words) |
| **データ幅** | 32-bit |
| **アドレッシング** | バイトアドレス (0x0000_0000 ～ 0x0000_0FFF) |
| **アクセス** | 同期読み出し (1クロックレイテンシ) |
| **初期化方法** | `$readmemh("rom.hex", mem)` |
| **FPGA リソース** | Block RAM (RAMB36E1) |

### 🔄 ダミーCPU仕様

| パラメータ | 値 |
|-----------|-----|
| **役割** | プログラムカウンタ (PC) 相当のアドレス生成器 |
| **更新周期** | 約 0.5秒 (50,000,000 クロック @ 100MHz) |
| **アドレス増分** | +4 (ワードアライメント) |
| **表示パターン数** | 10個 (0x00, 0x04, ..., 0x24) |
| **ループ動作** | 10個目の後、0番地に戻る |

---

## 🧩 モジュール構成

### 1. `basys3_top.sv` (トップモジュール)

全体を統合し、Basys3ボードのピンに接続するトップレベルモジュール。

#### ポート定義

| 信号名 | 方向 | 型 | 説明 |
|--------|------|-----|------|
| `clk` | input | logic | Basys 3 の 100MHz システムクロック (W5ピン) |
| `btnC` | input | logic | センターボタン (リセット, Active High, U18ピン) |
| `led[15:0]` | output | logic | ユーザーLED (読み出しデータの下位16bit) |

#### モジュール接続図

```
┌──────────────────────────────────────────┐
│          basys3_top (Top Level)          │
│                                          │
│  ┌──────────────┐      ┌──────────────┐ │
│  │ rom_reader   │─addr→│ prx32_memory │ │
│  │ (Dummy CPU)  │      │  (4KB ROM)   │ │
│  └──────────────┘      └──────┬───────┘ │
│         ↑                     │         │
│       clk, reset            rdata       │
│                               ↓         │
│                          led[15:0]      │
└──────────────────────────────────────────┘
```

---

### 2. `rom_reader.sv` (ダミーCPU)

低速クロックでアドレスを順次生成するモジュール。

#### 主要ブロック

##### 2.1. 低速パルス生成器

```systemverilog
localparam TIMER_MAX = 50_000_000 - 1;  // 0.5秒周期
```

- **目的**: 100MHz クロックから 0.5秒ごとのティックパルスを生成
- **実装**: 32-bitカウンタでクロックサイクルをカウント
- **出力**: `tick` 信号 (1クロック幅のパルス)

##### 2.2. アドレスカウンタ (Program Counter)

```systemverilog
if (addr == 32'h0000_0024) begin
    addr <= 32'h0000_0000;  // 10個目で巻き戻し
end else begin
    addr <= addr + 32'h0000_0004;  // +4 (word境界)
end
```

- **初期値**: 0x0000_0000
- **増分**: +4 (32-bitワードアドレッシング)
- **範囲**: 0x00 ～ 0x24 (10ワード)

#### 出力信号

| 信号名 | 型 | 説明 |
|--------|-----|------|
| `addr[31:0]` | output | バイトアドレス (0x00, 0x04, 0x08, ..., 0x24) |

---

### 3. `prx32_memory.sv` (ROMモジュール)

Block RAMを用いた同期読み出しメモリ。

#### パラメータ定義

```systemverilog
localparam int unsigned MEM_DEPTH      = 1024;        // 1024 words
localparam int unsigned ADDR_WIDTH     = 10;          // log2(1024)
localparam int unsigned BYTE_ADDR_LSB  = 2;           // 下位2bit (バイトオフセット)
localparam int unsigned WORD_ADDR_MSB  = 11;          // addr[11:2]
```

#### アドレス変換

```
バイトアドレス (32-bit)       ワードアドレス (10-bit)
  addr[31:0]          →         addr[11:2]
  
例: 0x0000_0004 → インデックス 1
    0x0000_0008 → インデックス 2
```

#### 初期化

```systemverilog
initial begin
    $readmemh("rom.hex", mem);
end
```

- Vivado合成時に `rom.hex` からデータを読み込み、Block RAMに焼き込む
- ファイルフォーマット: 各行に32-bit Hexデータ (リトルエンディアン)

#### 主要信号

| 信号名 | 方向 | 型 | 説明 |
|--------|------|-----|------|
| `clk` | input | logic | システムクロック |
| `addr[31:0]` | input | logic | バイトアドレス |
| `rdata[31:0]` | output | logic | 読み出しデータ (1クロック遅延) |

#### アサーション (シミュレーション専用)

```systemverilog
// 範囲外アクセス検出
if (addr >= (MEM_DEPTH * 4)) $warning(...);

// アライメントチェック (4バイト境界)
if (addr[1:0] != 2'b00) $warning(...);
```

---

## 💾 ソフトウェア側の実装 (`sw/`)

### `main.c` - LEDパターン定義

```c
__attribute__((section(".text")))
const unsigned int led_patterns[] = {
    0x00000001,  // LED[0] ON
    0x00000003,  // LED[1:0] ON
    0x00000007,  // LED[2:0] ON
    0x0000000F,  // LED[3:0] ON
    0x000000FF,  // 8bit ON
    0x00005555,  // 縞模様
    0x0000AAAA,  // 縞模様 (反転)
    0xFFFF0000,  // 上位16bit (下位16bitは消灯)
    0x0000FFFF,  // 全点灯
    0x00000000   // 全消灯
};
```

- **セクション指定**: `.text` セクションに配置 (アドレス0番地から開始)
- **データ型**: `const unsigned int` (32-bit)
- **パターン数**: 10個

---

### `linker.ld` - リンカスクリプト

```ld
MEMORY {
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS {
    .text : {
        *(.text)
        *(.rodata)
    } > ROM
}
```

- **ROM領域**: 0x0000_0000 ～ 0x0000_0FFF (4KB)
- **配置ルール**: `.text` および `.rodata` セクションをROMに配置

---

### `Makefile` - ビルドフロー

```makefile
rom.hex: rom.bin
    hexdump -v -e '1/4 "%08x" "\n"' $< > $@
```

#### ビルドステップ

1. **コンパイル & リンク**: `main.c` → `rom.elf` (RISC-V ELF)
2. **バイナリ抽出**: `rom.elf` → `rom.bin` (生のバイナリデータ)
3. **Hex変換**: `rom.bin` → `rom.hex` (4バイト幅16進数テキスト)

#### 生成される `rom.hex` の例

```
00000001
00000003
00000007
0000000f
000000ff
00005555
0000aaaa
ffff0000
0000ffff
00000000
```

- 各行が1ワード (32-bit) を表す
- リトルエンディアン形式

---

## 🧪 テストベンチ (`tb_load_rom.sv`)

### 特徴

- ✅ **セルフチェック機能**: 期待値との自動比較
- ✅ **同期読み出し対応**: 1クロックレイテンシを考慮したタイミング調整
- ✅ **包括的テストケース**: 5つのアドレスで検証
- ✅ **タイムアウト機能**: 無限ループ防止 (10μs)
- ✅ **SVA (SystemVerilog Assertion)**: アドレス範囲とアライメントの検証

### テストケース

| # | アドレス | 期待値 | 説明 |
|---|----------|--------|------|
| 1 | 0x0000_0000 | 0x0000_0001 | LED[0] ON |
| 2 | 0x0000_0004 | 0x0000_0003 | LED[1:0] ON |
| 3 | 0x0000_0008 | 0x0000_0007 | LED[2:0] ON |
| 4 | 0x0000_000C | 0x0000_000F | LED[3:0] ON |
| 5 | 0x0000_0010 | 0x0000_00FF | 8-bit ON |

### テストタスク

```systemverilog
task automatic check_read(input logic [31:0] test_addr, 
                          input logic [31:0] expected_data);
    // アドレス設定
    addr = test_addr;
    
    // 同期読み出しのため1クロック待機
    @(posedge clk);
    @(posedge clk);
    #1;
    
    // データ検証
    if (rdata !== expected_data) $error(...);
endtask
```

### 実行結果例

```
========================================
=== ROM Read Testbench Start        ===
=== Clock: 100MHz                   ===
=== Memory: 4KB ROM (1024 words)    ===
========================================

[READ]  Time=... Setting addr=0x00000000
[PASS]  Test #1: Time=... Data match at addr=0x00000000! Data=0x00000001
...
========================================
=== ALL TESTS PASSED (5/5)           ===
========================================
```

---

## 🎛️ 制約ファイル (`Basys3_Master.xdc`)

### クロック定義

```tcl
# 100MHz システムクロック (W5ピン)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
```

- **周期**: 10.00ns (100MHz)
- **デューティ比**: 50% (0-5ns High, 5-10ns Low)

### リセット (センターボタン)

```tcl
# Center Button: Reset (Active High)
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]
```

### LED ピンアサイン (16-bit)

```tcl
set_property PACKAGE_PIN U16 [get_ports {led[0]}]   # 右端
...
set_property PACKAGE_PIN L1 [get_ports {led[15]}]   # 左端
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
```

- **配置**: LED0 (右端) ～ LED15 (左端)
- **極性**: アクティブハイ (1 = 点灯, 0 = 消灯)

### コンフィギュレーション設定

```tcl
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
```

---

## 🚀 使い方

### 1. ソフトウェアのビルド

```bash
cd sw/
make clean
make
```

**生成ファイル**:
- `rom.elf`: RISC-V ELF実行ファイル
- `rom.bin`: 生バイナリデータ
- `rom.hex`: Verilog用Hexファイル ✅

### 2. Vivado プロジェクトを開く

```bash
cd ..
vivado Artix7_Hex_Rom_Reader.xpr
```

### 3. シミュレーション実行

```bash
# Vivado GUI で実行
# Flow Navigator → Run Simulation → Run Behavioral Simulation
```

**確認ポイント**:
- `tb_load_rom` が正常終了 (ALL TESTS PASSED)
- 波形ビューアで `addr`, `rdata`, `led` の値を確認

### 4. 合成・実装・ビットストリーム生成

```bash
# Vivado Tcl Console または GUI で実行
launch_runs synth_1 -jobs 8
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
```

**生成ファイル**:
- `*.runs/impl_1/basys3_top.bit` ✅

### 5. FPGA への書き込みと動作確認

#### ハードウェア接続
1. Basys 3 ボードをPCに接続 (USB ケーブル)
2. 電源スイッチをON

#### ビットストリーム書き込み

```bash
# Vivado Hardware Manager で実行
open_hw_manager
connect_hw_server
open_hw_target

set_property PROGRAM.FILE {runs/impl_1/basys3_top.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]
```

#### 動作確認

1. **センターボタン (btnC) を押す** → すべてのLEDがリセット (消灯)
2. **ボタンを離す** → 自動的にパターン表示開始
3. **約0.5秒ごとにLEDパターンが切り替わる** ✅

**期待される動作シーケンス**:
```
Time    LED表示 (16進数)
----    ----------------
0.0s    0x0001  (LED0のみ点灯)
0.5s    0x0003  (LED0, LED1点灯)
1.0s    0x0007  (LED0-2点灯)
1.5s    0x000F  (LED0-3点灯)
2.0s    0x00FF  (LED0-7点灯)
2.5s    0x5555  (縞模様)
3.0s    0xAAAA  (縞模様反転)
3.5s    0x0000  (全消灯 ※上位16bitのみ有効)
4.0s    0xFFFF  (全点灯)
4.5s    0x0000  (全消灯)
5.0s    0x0001  (最初に戻る)
```

---
