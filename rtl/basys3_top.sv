//==============================================================================
// Module: basys3_top
// Description: Top-level module for Basys3 board integration
//              - Connects rom_reader (dummy CPU) and prx32_memory (ROM)
//              - Displays lower 16 bits of ROM data on LEDs
//              - Uses center button as reset
//              - Target: Digilent Basys3 (Artix-7 XC7A35T)
//==============================================================================

`default_nettype none

module basys3_top (
    input  wire logic        clk,      // Basys3 W5 (100MHz)
    input  wire logic        btnC,     // Center Button (Reset)
    output      logic [15:0] led       // User LEDs
);

    // ---------------------------------------------------------
    // 内部信号定義
    // ---------------------------------------------------------
    logic [31:0] addr;      // Address bus from rom_reader to memory
    logic [31:0] rdata;     // Read data from memory
    logic        reset;     // Internal reset signal

    // ---------------------------------------------------------
    // リセット処理
    // ---------------------------------------------------------
    // リセットはボタン入力 (アクティブハイ) をそのまま使用
    assign reset = btnC;

    // ---------------------------------------------------------
    // モジュール接続
    // ---------------------------------------------------------
    
    // 1. アドレス生成 (ダミーCPU)
    rom_reader u_reader (
        .clk   (clk),
        .reset (reset),
        .addr  (addr)
    );

    // 2. メモリ (命令/データ保持)
    prx32_memory u_memory (
        .clk   (clk),
        .addr  (addr),
        .rdata (rdata)
    );

    // ---------------------------------------------------------
    // 3. LED出力
    // ---------------------------------------------------------
    // 読み出した32bitデータの下位16bitをLEDに表示
    assign led = rdata[15:0];

endmodule

`default_nettype wire
