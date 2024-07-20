# Config Linux Network Driver with Rust
We use WSL2 with Ubuntu 22.04 to conduct all the assignment

## Questions & Answers

###  在该文件夹中调用make LLVM=1，该文件夹内的代码将编译成一个内核模块。请结合你学到的知识，回答以下两个问题：

Q1、编译成内核模块，是在哪个文件中以哪条语句定义的？
A1：In the file `Kbuild`, the code `obj-m := r4l_e1000_demo.o` defined it.

Q2、该模块位于独立的文件夹内，却能编译成Linux内核模块，这叫做out-of-tree module，请分析它是如何与内核代码产生联系的？
A2: In the `Makefile`, `KDIR ?= ../linux; $(MAKE) -C $(KDIR) M=$$PWD` commands will change to the directory of the kernel and point out the module by `M'$$PWD`.

## Step 1: Build Linux Bootable Image

```bash
cd src_e1000
bash build_image.sh
```

## Step 2: Modify Network Configuration

After entering the QEMU virtual machine, conduct following commands:

```bash
insmod r4l_e1000_demo.ko
ip link set eth0 up
ip addr add broadcast 10.0.2.255 dev eth0
ip addr add 10.0.2.15/255.255.255.0 dev eth0 
ip route add default via 10.0.2.1
ping 10.0.2.2
```

The output of some commands shows below:
```
~ # insmod r4l_e1000_demo.ko
[  210.873311] r4l_e1000_demo: loading out-of-tree module taints kernel.
[  210.882634] r4l_e1000_demo: Rust for linux e1000 driver demo (init)
[  210.885130] insmod (79) used greatest stack depth: 13024 bytes left
~ # ip link set eth0 up
ip: RTNETLINK answers: Invalid argument
~ # ip addr add 10.0.2.15/255.255.255.0 dev eth0
ip: RTNETLINK answers: File exists
~ # ip route add default via 10.0.2.1
ip: RTNETLINK answers: File exists
~ # ping 10.0.2.2
PING 10.0.2.2 (10.0.2.2): 56 data bytes
64 bytes from 10.0.2.2: seq=0 ttl=255 time=11.807 ms
64 bytes from 10.0.2.2: seq=1 ttl=255 time=0.756 ms
64 bytes from 10.0.2.2: seq=2 ttl=255 time=0.434 ms
64 bytes from 10.0.2.2: seq=3 ttl=255 time=0.403 ms
64 bytes from 10.0.2.2: seq=4 ttl=255 time=0.421 ms
64 bytes from 10.0.2.2: seq=5 ttl=255 time=0.410 ms
64 bytes from 10.0.2.2: seq=6 ttl=255 time=0.561 ms
64 bytes from 10.0.2.2: seq=7 ttl=255 time=0.399 ms
64 bytes from 10.0.2.2: seq=8 ttl=255 time=1.516 ms
64 bytes from 10.0.2.2: seq=9 ttl=255 time=0.432 ms
^C
--- 10.0.2.2 ping statistics ---
10 packets transmitted, 10 packets received, 0% packet loss
round-trip min/avg/max = 0.399/1.713/11.807 ms
```

## Step 4: Exit QEMU

Press `Ctrl-A X` to exit the QEMU.