//==============================================================================
// Module: prx32_memory
// Description: Synchronous Read-Only Memory (ROM) for RISC-V PRX32
//              - 4KB capacity (1024 words x 32-bit)
//              - Initialized from rom.hex file
//              - Byte-addressable (0x0000_0000 ~ 0x0000_0FFF)
//==============================================================================

`default_nettype none

module prx32_memory (
    input  wire logic        clk,
    input  wire logic [31:0] addr,    // CPU/Readerからのアドレス (Byte Address)
    output      logic [31:0] rdata    // 読み出しデータ
);

    // ---------------------------------------------------------
    // パラメータ定義
    // ---------------------------------------------------------
    // メモリ容量: 4KB = 1024ワード
    // アドレスマップ: 0x0000_0000 ～ 0x0000_0FFF (4096 bytes)
    localparam int unsigned MEM_DEPTH      = 1024;        // ワード数
    localparam int unsigned ADDR_WIDTH     = $clog2(MEM_DEPTH); // 10bit
    localparam int unsigned BYTE_ADDR_LSB  = 2;           // バイトアドレス下位2bit
    localparam int unsigned WORD_ADDR_MSB  = BYTE_ADDR_LSB + ADDR_WIDTH - 1; // 11

    // ---------------------------------------------------------
    // メモリ配列定義
    // ---------------------------------------------------------
    // 32-bit幅 x 1024深さのメモリ (Block RAMとして合成される)
    logic [31:0] mem [0:MEM_DEPTH-1];

    // ---------------------------------------------------------
    // 初期化 (Synthesis時にHexファイルをロードしてROM化する)
    // ---------------------------------------------------------
    // 注意:
    // - $readmemhはシミュレーション時とVivado合成時の両方で動作する
    // - ファイルパスはプロジェクト基準またはIPカタログの設定に依存
    // - Vivadoでは XDC で set_property file_type {Memory Initialization Files}
    //   または IP設定でCOE/MEMファイルを指定することも可能
    initial begin
        $readmemh("rom.hex", mem);
    end

    // ---------------------------------------------------------
    // 読み出しポート (Synchronous Read)
    // ---------------------------------------------------------
    // ワードアドレス変換用信号
    logic [ADDR_WIDTH-1:0] word_addr;

    // バイトアドレス -> ワードアドレス変換
    // RISC-Vはバイトアドレス(0, 4, 8, ...)を使用するが、
    // メモリ配列はワードインデックス(0, 1, 2, ...)でアクセスする
    // そのため、addr[11:2]を使用 (下位2bitを捨てる)
    assign word_addr = addr[WORD_ADDR_MSB:BYTE_ADDR_LSB];

    // 同期読み出し (Block RAM推論のため)
    always_ff @(posedge clk) begin
        rdata <= mem[word_addr];
    end

    // ---------------------------------------------------------
    // アサーション (Simulation Only)
    // ---------------------------------------------------------
    `ifndef SYNTHESIS
    // 範囲外アクセスの検出
    always_ff @(posedge clk) begin
        if (addr >= (MEM_DEPTH * 4)) begin
            $warning("Memory access out of range: addr=0x%08h (max=0x%08h)", 
                     addr, (MEM_DEPTH * 4) - 1);
        end
    end

    // アライメントチェック (ワードアクセスは4バイト境界である必要がある)
    always_ff @(posedge clk) begin
        if (addr[1:0] != 2'b00) begin
            $warning("Unaligned memory access detected: addr=0x%08h", addr);
        end
    end
    `endif

endmodule

`default_nettype wire
