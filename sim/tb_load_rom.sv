//==============================================================================
// Testbench: tb_load_rom (tb_memory)
// Description: Self-checking testbench for prx32_memory ROM module
//              - Generates clock
//              - Sequentially changes addresses
//              - Verifies data read from BRAM/ROM
//              - Automated verification with expected value comparison
//==============================================================================

`timescale 1ns / 1ps

module tb_load_rom;

    // ---------------------------------------------------------
    // 1. 定数定義
    // ---------------------------------------------------------
    // 100MHz クロック周期
    localparam time CLK_PERIOD = 10ns;
    
    // テストケース数
    localparam int NUM_TEST_CASES = 5;

    // ---------------------------------------------------------
    // 2. 信号定義
    // ---------------------------------------------------------
    logic        clk;
    logic [31:0] addr;
    logic [31:0] rdata;

    // テスト管理変数
    int error_count = 0;
    int test_count = 0;

    // ---------------------------------------------------------
    // 3. テスト対象モジュール (DUT) のインスタンス化
    // ---------------------------------------------------------
    prx32_memory dut (
        .clk   (clk),
        .addr  (addr),
        .rdata (rdata)
    );

    // ---------------------------------------------------------
    // 4. クロック生成 (10ns周期 = 100MHz)
    // ---------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // ---------------------------------------------------------
    // 5. タスク定義 (メモリ読み出し・検証)
    // ---------------------------------------------------------
    
    // タスク: 指定アドレスから読み出し、期待値と比較
    // - 注意: prx32_memory は同期読み出しのため、1クロック遅延がある
    task automatic check_read(input logic [31:0] test_addr, input logic [31:0] expected_data);
        logic [31:0] received_data;
        begin
            // アドレスを設定
            addr = test_addr;
            $display("[READ]  Time=%0t: Setting addr=0x%08h", $time, test_addr);
            
            // 1クロック待機（同期読み出しのため）
            @(posedge clk);
            
            // さらに1クロック待機してデータを安定化
            @(posedge clk);
            #1; // セットアップ時間を考慮した微小遅延
            
            // データを取得
            received_data = rdata;

            // 結果比較
            test_count++;
            if (received_data !== expected_data) begin
                $error("[FAIL]  Test #%0d: Time=%0t: Data mismatch at addr=0x%08h! Expected=0x%08h, Received=0x%08h", 
                       test_count, $time, test_addr, expected_data, received_data);
                error_count++;
            end else begin
                $display("[PASS]  Test #%0d: Time=%0t: Data match at addr=0x%08h! Data=0x%08h", 
                         test_count, $time, test_addr, received_data);
            end
        end
    endtask

    // ---------------------------------------------------------
    // 6. テストシナリオ実行
    // ---------------------------------------------------------
    initial begin
        // 初期化
        addr = 32'h0000_0000;

        // VCDダンプ (オプション: Vivado Simulatorでは不要だがIVerilog等で有用)
        // $dumpfile("tb_load_rom.vcd");
        // $dumpvars(0, tb_load_rom);

        // 初期安定化期間
        repeat(10) @(posedge clk);

        $display("========================================");
        $display("=== ROM Read Testbench Start        ===");
        $display("=== Clock: 100MHz                   ===");
        $display("=== Memory: 4KB ROM (1024 words)    ===");
        $display("========================================");
        $display("");

        // ---------------------------------------------------------
        // テストケース実行
        // main.c で定義した配列の先頭から順番に読み出し検証
        // ---------------------------------------------------------
        
        // Test 1: Addr 0x00000000 -> 期待値 0x00000001
        check_read(32'h0000_0000, 32'h0000_0001);
        
        // Test 2: Addr 0x00000004 -> 期待値 0x00000003
        check_read(32'h0000_0004, 32'h0000_0003);
        
        // Test 3: Addr 0x00000008 -> 期待値 0x00000007
        check_read(32'h0000_0008, 32'h0000_0007);
        
        // Test 4: Addr 0x0000000C -> 期待値 0x0000000F
        check_read(32'h0000_000C, 32'h0000_000F);
        
        // Test 5: Addr 0x00000010 -> 期待値 0x000000FF
        check_read(32'h0000_0010, 32'h0000_00FF);

        // 追加の安定化期間
        repeat(10) @(posedge clk);

        // ---------------------------------------------------------
        // テスト結果サマリー
        // ---------------------------------------------------------
        $display("");
        $display("========================================");
        if (error_count == 0) begin
            $display("=== ALL TESTS PASSED (%0d/%0d)        ===", test_count, test_count);
            $display("========================================");
        end else begin
            $display("=== TESTS FAILED: %0d/%0d errors     ===", error_count, test_count);
            $display("========================================");
        end
        $display("");
        
        // シミュレーション終了
        #(CLK_PERIOD * 10);
        $finish;
    end

    // ---------------------------------------------------------
    // 7. タイムアウト監視
    // ---------------------------------------------------------
    initial begin
        // シミュレーションが無限ループに陥らないよう、タイムアウトを設定
        #10us;  // 10マイクロ秒でタイムアウト
        $display("========================================");
        $error("=== SIMULATION TIMEOUT               ===");
        $display("========================================");
        $finish;
    end

    // ---------------------------------------------------------
    // 8. アサーション (SVA) - メモリアクセスの妥当性検証
    // ---------------------------------------------------------
    
    // アサーション: アドレスが範囲内であることを確認
    // メモリ容量: 4KB = 4096 bytes = 0x0000_0000 ~ 0x0000_0FFF
    property p_addr_in_range;
        @(posedge clk) (addr < 32'h0000_1000);
    endproperty
    assert property (p_addr_in_range)
        else $warning("Assertion warning: Address 0x%08h is out of range (>= 0x1000)", addr);

    // アサーション: ワードアクセスは4バイト境界アライメント
    property p_addr_aligned;
        @(posedge clk) (addr[1:0] == 2'b00);
    endproperty
    assert property (p_addr_aligned)
        else $warning("Assertion warning: Address 0x%08h is not 4-byte aligned", addr);

endmodule
