// main.c
// セクションを .text に指定して、アドレス0番地から配置されるようにする
__attribute__((section(".text")))
const unsigned int led_patterns[] = {
    0x00000001, // LED[0] ON
    0x00000003, // LED[1:0] ON
    0x00000007, // LED[2:0] ON
    0x0000000F, // LED[3:0] ON
    0x000000FF, // 8bit ON
    0x00005555, // 縞模様
    0x0000AAAA, // 縞模様 (反転)
    0xFFFF0000, // 上位16bit (LEDには表示されないはず) -> 下位16bitは0消灯
    0x0000FFFF, // 全点灯
    0x00000000  // 全消灯 (ループの最後)
};

// ダミーのエントリポイント (無限ループ)
void _start() {
    while(1);
}