# hello.s: A simple "Hello, World!" program for RISC-V 64-bit

```asm
.global _start

.section .data
hello_msg:
    .string "Hello, World!\n"
msg_len = . - hello_msg

.section .text
_start:
    # --- Print the "Hello, World!" string ---
    # The write() syscall is number 64 on RISC-V
    # ssize_t write(int fd, const void *buf, size_t count);
    # Arguments are passed in registers a0, a1, a2

    li a0, 1                # a0 = file descriptor (1 for stdout)
    la a1, hello_msg        # a1 = address of the string to print
    li a2, msg_len          # a2 = length of the string
    li a7, 64               # a7 = syscall number for write()
    ecall                   # Make the system call

    # --- Exit the program ---
    # The exit() syscall is number 93
    # void exit(int status);

    li a0, 0                # a0 = exit status (0 for success)
    li a7, 93               # a7 = syscall number for exit()
    ecall                   # Make the system call
```


```stdin
tim@Spring2026:~$ cd simple-test
tim@Spring2026:~/simple-test$ export PATH=/opt/riscv64/bin:$PATH
tim@Spring2026:~/simple-test$ which riscv64-unknown-elf-gcc
```


```stdout
opt/riscv64/bin/riscv64-unknown-elf-gcc
```


```stdin
tim@Spring2026:~/simple-test$ dir
```


```stdout
hellow_world.s
```


```stdin
tim@Spring2026:~/simple-test$ riscv64-unknown-elf-gcc -o hello hellow_world.s -static -nostartfiles
tim@Spring2026:~/simple-test$ ~/dir_2/gem5/build/RISCV/gem5.opt ~/dir_2/gem5/configs/deprecated/example/se.py -c ~/simple-test/hello
```


```stdout
gem5 Simulator System.  https://www.gem5.org
gem5 is copyrighted software; use the --copyright option for details.

gem5 version 25.1.0.0
gem5 compiled Apr 10 2026 15:47:45
gem5 started Apr 10 2026 16:23:46
gem5 executing on Spring2026, pid 250067
command line: /home/tim/dir_2/gem5/build/RISCV/gem5.opt /home/tim/dir_2/gem5/configs/deprecated/example/se.py -c /home/tim/simple-test/hello

warn: The se.py script is deprecated. It will be removed in future releases of  gem5.
Global frequency set at 1000000000000 ticks per second
src/mem/dram_interface.cc:690: warn: DRAM device capacity (8192 Mbytes) does not match the address range assigned (512 Mbytes)
src/arch/riscv/isa.cc:321: info: RVV enabled, VLEN = 256 bits, ELEN = 64 bits
src/arch/riscv/linux/se_workload.cc:73: warn: Unknown operating system; assuming Linux.
src/base/statistics.hh:279: warn: One of the stats is a legacy stat. Legacy stat is a stat that does not belong to any statistics::Group. Legacy stat is deprecated.
system.remote_gdb: Listening for connections on port 7000
**** REAL SIMULATION ****
Hello, World!
Exiting @ tick 6000 because exiting with last active thread context
```
