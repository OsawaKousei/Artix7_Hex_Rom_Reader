PREFIX = riscv64-unknown-elf-
CC = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy

CFLAGS = -march=rv32i -mabi=ilp32 -nostartfiles -nostdlib -Wl,-Tlinker.ld

all: rom.hex

# 1. コンパイル & リンク (ELF生成)
rom.elf: main.c linker.ld
	$(CC) $(CFLAGS) -o $@ $<

# 2. バイナリ抽出 (ELFヘッダなどを除去)
rom.bin: rom.elf
	$(OBJCOPY) -O binary $< $@

# 3. Hex変換 (重要: 32bit幅のテキストデータに整形)
# hexdumpを使って、4バイト(32bit)ずつ 16進数文字列として出力します。
# エンディアンの問題を回避し、Verilogの $readmemh が期待する形式にします。
rom.hex: rom.bin
	hexdump -v -e '1/4 "%08x" "\n"' $< > $@

clean:
	rm -f *.elf *.bin *.hex