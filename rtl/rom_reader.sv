//==============================================================================
// Module: rom_reader
// Description: Dummy CPU that generates sequential addresses at a slow rate
//              - Acts as a simple address counter for ROM reading
//              - Generates tick pulse approximately every 0.5 seconds
//              - Increments address by 4 (word-aligned) on each tick
//              - Wraps around after 16 words (64 bytes)
//==============================================================================

`default_nettype none

module rom_reader (
    input  wire logic        clk,      // System clock (100MHz for Basys3)
    input  wire logic        reset,    // Synchronous reset (active-high)
    output      logic [31:0] addr      // Byte address output (0x00, 0x04, 0x08, ...)
);

    // ---------------------------------------------------------
    // 1. 低速パルス生成 (約0.5秒ごとに1回 1になる信号)
    // ---------------------------------------------------------
    // 100MHz = 100,000,000 サイクル/秒
    // 0.5秒 = 50,000,000 サイクル
    localparam TIMER_MAX = 50_000_000 - 1;
    
    logic [31:0] timer_count;
    logic        tick;

    always_ff @(posedge clk) begin
        if (reset) begin
            timer_count <= 32'h0000_0000;
            tick        <= 1'b0;
        end else begin
            if (timer_count == TIMER_MAX) begin
                timer_count <= 32'h0000_0000;
                tick        <= 1'b1;
            end else begin
                timer_count <= timer_count + 1;
                tick        <= 1'b0;
            end
        end
    end

    // ---------------------------------------------------------
    // 2. アドレス生成 (Program Counter相当)
    // ---------------------------------------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            addr <= 32'h0000_0000;
        end else if (tick) begin
            // 0.5秒ごとに次のワードへ (+4)
            // 10個のパターンを表示したら最初に戻る (10 * 4 = 40 = 0x28)
            if (addr == 32'h0000_0024) begin
                addr <= 32'h0000_0000;
            end else begin
                addr <= addr + 32'h0000_0004;
            end
        end
    end

endmodule

`default_nettype wire
