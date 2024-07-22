# Assign 1： Build and Compile Linux Kernel
We use WSL2 with Ubuntu 22.04 to conduct all the assignment

## Step 1: Install required dependecies
```bash
sudo apt install git curl
sudo apt install build-essential libtool texinfo gzip zip unzip patchutils cmake ninja-build automake bison flex gperf grep sed gawk bc zlib1g-dev libexpat1-dev libmpc-dev libncurses-dev libglib2.0-dev libfdt-dev libpixman-1-dev libelf-dev libssl-dev
sudo apt-get install clang-format clang-tidy clang-tools clang clangd libc++-dev libc++1 libc++abi-dev libc++abi1 libclang-dev libclang1 liblldb-dev libllvm-ocaml-dev libomp-dev libomp5 lld lldb llvm python3-clang
```

## Step 2: Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Step 3: Build Busybox

```bash
cd ./busybox-1.36.1/
make menuconfig
# Set the following config to yes
# General setup
#         ---> [*] Rust support
make install -j$(nproc)
```
![alt text](./images/busybox_config.png)

## Step 4: Install QEMU
QEMU will be used in later Assignments

```bash
apt install qemu-system-x86
qemu-system-x86_64 --version
```

## Step 5: Config Linux files

```bash
cd ../linux
# 将此目录中的rustc重置为特定版本
# 可提前为rustup设置代理，以便加速下载过程，参考上一节“安装Rust”中的说明
rustup override set $(scripts/min-tool-version.sh rustc)
# 添加rust-src源代码
rustup component add rust-src
# 安装clang llvm，该项一般在配置内核时已经安装，若已安装此处可忽略
apt install clang llvm

# 可为cargo仓库crates.io设置使用镜像，参考上一节“安装Rust”中的说明
# 安装bindgen工具，注意在0.60版本后，bindgen工具的命令行版本位于bindgen-cli包中
cargo install --locked --version $(scripts/min-tool-version.sh bindgen) bindgen
# 安装rustfmt和clippy
rustup component add rustfmt
rustup component add clippy
# 检查内核rust支持已经启用
make LLVM=1 rustavailable
```
## Step 6: Compile Linux kernel with Rust

```bash
cd linux/
make x86_64_defconfig
make LLVM=1 menuconfig
# Set the following config to yes
# General setup
#         ---> [*] Rust support
make LLVM=1 -j$(nproc)
```
![alt text](./images/assign1_linux_kernel_config.png)

When succeed, you will see file `vmlinux` in the `linux/` folder.


# Assign 2: Config Linux Network Driver with Rust
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

## Step 2: Turn Off the e1000 Network Driver
Back to `linux/` and re-run make LLVM=1 menuconfig, then:
```
Device Drivers --->
    [*] Network device support --->
        [*] Ethernet driver support --->
            <> Intel devices, Intel(R) PRO/1000 Gigabit Ethernet support
```
![alt text](./images/assign2_turn_off.png)

## Step 3: Modify Network Configuration

After recompile the kernal code and entering the QEMU virtual machine, conduct following commands:

```bash
insmod r4l_e1000_demo.ko
ip link set eth0 up
ifconfig eth0 broadcast 10.0.2.255
ip addr add 10.0.2.15/255.255.255.0 dev eth0 
ip route add default via 10.0.2.1
ping 10.0.2.2
```

The output of commands shows below:
![alt text](./images/assign2_code_output.png)

## Step 4: Exit QEMU
Press `Ctrl-A X` to exit the QEMU.


# Assign 3: Add Module to Linux with Rust
We use WSL2 with Ubuntu 22.04 to conduct all the assignment

## Step 1: Write Module Code
Create a file in `linux/samples/rust/` folder, named `rust_helloworld.rs`:
```rust
// SPDX-License-Identifier: GPL-2.0
//! Rust minimal sample.
      
use kernel::prelude::*;
      
module! {
  type: RustHelloWorld,
  name: "rust_helloworld",
  author: "whocare",
  description: "hello world module in rust",
  license: "GPL",
}
      
struct RustHelloWorld {}
      
impl kernel::Module for RustHelloWorld {
  fn init(_name: &'static CStr, _module: &'static ThisModule) -> Result<Self> {
      pr_info!("Hello World from Rust module\n");
      Ok(RustHelloWorld {})
  }
}

```
![alt text](./images/assign3_code_content.png)

## Step 2: Modify Makefile and Kconfig
In `linux/sample/rust/Makefile`, add codes below:
```bash
obj-$(CONFIG_SAMPLE_RUST_HELLOWORLD)	+= rust_helloworld.o
```

In `linux/sample/rust/Kconfig`, add codes below:
```bash
config SAMPLE_RUST_HELLOWORLD
	tristate "Print Helloworld in Rust"
	help
	  This option builds the Rust module samples.

	  To compile this as a module, choose M here:
	  the module will be called rust_helloworld.

	  If unsure, say N.
```

## Step 3: Configure and Re-build the Kernel
Modify the configuration:
```
Kernel hacking
 [*] Sample kernel code  ---> 
     [*]   Rust samples  --->  
         <M>   HelloWorld 
```
![alt text](./images/assign3_module_helloworld.png)

## Step 4: Move Module to Target Folder
run follwoing code:
```bash
# Inside linux/ folder
mv ./samples/rust/rust_helloworld.ko ../src_e1000/rootfs
```

## Step 5: Run the Module
```bash
cd ../src_e1000
bash build_image.sh
```
Inside the QEMU:
```bash
insmod rust_helloworld.ko
dmesg | tail
```

![alt text](./images/assign3_output_helloworld.png)


# Assign 4: Character Device
We use WSL2 with Ubuntu 22.04 to conduct all the assignment

## Step 1: Write the Module
Write codes below into the `rl4_e1000_demo.rs` file:


# Assign 5: Add Remove Module for e1000
We use WSL2 with Ubuntu 22.04 to conduct all the assignment

Q：作业5中的字符设备/dev/cicv是怎么创建的？它的设备号是多少？它是如何与我们写的字符设备驱动关联上的？

A: Inside `build_image.sh`, the line `echo "mknod /dev/cicv c 248 0" >> etc/init.d/rcS` create `/dev/cicv`; Device Number is `248` which is linked by the system.

## Step 1: Create Read Write Functions
Goto the file `samples/rust/rust_chrdev.rs` and implement read write funcs:
```rust
    fn write(_this: &Self,_file: &file::File,_reader: &mut impl kernel::io_buffer::IoBufferReader,_offset:u64,) -> Result<usize> {
        let mut buf = _this.inner.lock();
        let offset = _offset.try_into()?;
        let len = core::cmp::min(_reader.len(), buf.len().saturating_sub(offset));
        _reader.read_slice(&mut buf[offset..][..len])?;
        Ok(len)
    }

    fn read(_this: &Self,_file: &file::File,_writer: &mut impl kernel::io_buffer::IoBufferWriter,_offset:u64,) -> Result<usize> {
        let mut buf = _this.inner.lock();
        let offset = _offset.try_into()?;
        let len = core::cmp::min(_writer.len(), buf.len().saturating_sub(offset));
        _writer.write_slice(&mut buf[offset..][..len])?;
        Ok(len)
    }
```

## Step 2: Change configuration of Kenel
Make following change and recompile the kernel
```
Kernel hacking
  ---> Sample Kernel code
      ---> Rust samples
              ---> <*>Character device (NEW)

```

## Step 3: Run the Test
![alt text](./images/assign5_chrdev_hello.png)

# Mini Project
We use WSL2 with Ubuntu 22.04 to conduct all the assignment

## Step 1: Build the Script and Run
run this [file](../r4l_experiment/build_script.sh)

## Step 2: Set NSF server
```bash
sudo apt-get install nfs-kernel-server
sudo bash -c "echo \
'$R4L_EXP/driver     127.0.0.1(insecure,rw,sync,no_root_squash)' \
    >> /etc/exports"
sudo /etc/init.d/rpcbind restart
sudo /etc/init.d/nfs-kernel-server restart
```

```
# Add this line in init script. Put it just after the line of sleep 0.5.
mount -t nfs -o nolock host_machine:/path/to/working/directory /mnt

# 然后rebuild initramfs
cd $R4L_EXP/initramfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
```
![alt text](./images/assign6_set_nsf.png)

## Step 4: Set up telnet server
First set `pts device node`
```bash
cd $R4L_EXP/initramfs

mkdir dev/pts
mknod -m 666 dev/ptmx c 5 2

# 同样在init脚本中设置自动挂载，在NFS设置后面加入
mount -t devpts devpts  /dev/pts

# 然后rebuild initramfs
cd $R4L_EXP/initramfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
```

Add following args of QEMU in `boot.sh`:
```bash
-netdev user,id=host_net,hostfwd=tcp::7023-:23 \
-device e1000,mac=52:54:00:12:34:50,netdev=host_net \
```
Run the command below in the host to connectthe QEMU Linux:
```bash
telnet localhost 7023
```

## Step 4.1: Enable telnet server
```bash
# 同样在init脚本中设置自动启动，在telnetserver设置后面加入
telnetd -l /bin/sh
# 然后rebuild initramfs
cd $R4L_EXP/initramfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
```

## Step 5: Create Rust Module
In host, run the following to check the telnet works:
```bash
cd $R4L_EXP/driver/002_completion
make KERNELDIR=../../../linux
```

![alt text](./images/assign6_test002_connection.png)

Now, copy and modify `002_completion` into `r4l_experiment/driver/003_completion_rust`:

- `Kbuild`:

```bash
obj-m := rust_completion.o
```

- `Makefile`:

```makefile
ifneq ($(KERNELRELEASE),)

# In kbuild context
module-objs := rust_completion.o	
obj-m := rust_completion.o

CFLAGS_hello_world.o := -DDEBUG
else
KDIR := ../../../linux
PWD := $(shell pwd)

all:
	$(MAKE) LLVM=1 -C $(KDIR)  M=$(PWD) modules

.PHONY: clean
clean:
	rm -f *.ko *.o .*.cmd .*.o.d *.mod *.mod.o *.mod.c *.symvers *.markers *.unsigned *.order *~
endif
```

- `rust_completion.rs`:
```rust
// SPDX-License-Identifier: GPL-2.0

//! Rust character device sample.

use core::result::Result::Err;

use kernel::prelude::*;
use kernel::sync::Mutex;
use kernel::{chrdev, file};
use kernel::task::Task;

const GLOBALMEM_SIZE: usize = 0x1000;

module! {
    type: RustChrdev,
    name: "rust_completion",
    author: "R4L experiments",
    description: "Rust completion of experiemnt",
    license: "GPL",
}

static GLOBALMEM_BUF: Mutex<[u8;GLOBALMEM_SIZE]> = unsafe {
    Mutex::new([0u8;GLOBALMEM_SIZE])
};

struct RustFile {
    #[allow(dead_code)]
    inner: &'static Mutex<[u8;GLOBALMEM_SIZE]>,
}

#[vtable]
impl file::Operations for RustFile {
    type Data = Box<Self>;

    fn open(_shared: &(), _file: &file::File) -> Result<Box<Self>> {
        Ok(
            Box::try_new(RustFile {
                inner: &GLOBALMEM_BUF
            })?
        )
    }

    fn write(_this: &Self,_file: &file::File,_reader: &mut impl kernel::io_buffer::IoBufferReader,_offset:u64,) -> Result<usize> {
        pr_info!("fn write() is invoked\n");
        let task = Task::current();
        pr_info!("process {} awakening the readers...\n", task.pid());
        
        let mut buf = _this.inner.lock();
        let offset = _offset.try_into()?;
        let len = core::cmp::min(_reader.len(), buf.len().saturating_sub(offset));
        _reader.read_slice(&mut buf[offset..][..len])?;
        Ok(len)
    }

    fn read(_this: &Self,_file: &file::File,_writer: &mut impl kernel::io_buffer::IoBufferWriter,_offset:u64,) -> Result<usize> {
        pr_info!("fn read() is invoked\n");
        let task = Task::current();
        pr_info!("process {} is going to sleep\n", task.pid());

        let mut buf = _this.inner.lock();
        let offset = _offset.try_into()?;
        let len = core::cmp::min(_writer.len(), buf.len().saturating_sub(offset));
        _writer.write_slice(&mut buf[offset..][..len])?;
        Ok(len)
    }
}

struct RustChrdev {
    _dev: Pin<Box<chrdev::Registration<2>>>,
}

impl kernel::Module for RustChrdev {
    fn init(name: &'static CStr, module: &'static ThisModule) -> Result<Self> {
        pr_info!("Rust completion module (init)\n");

        let mut chrdev_reg = chrdev::Registration::new_pinned(name, 0, module)?;

        // Register the same kind of device twice, we're just demonstrating
        // that you can use multiple minors. There are two minors in this case
        // because its type is `chrdev::Registration<2>`
        chrdev_reg.as_mut().register::<RustFile>()?;
        chrdev_reg.as_mut().register::<RustFile>()?;

        Ok(RustChrdev { _dev: chrdev_reg })
    }
}

impl Drop for RustChrdev {
    fn drop(&mut self) {
        pr_info!("Rust completion module (exit)\n");
    }
}

```

## Outcome shows below
- Build the module:
```bash
make
```

- Load it in QEMU Linux:
```bash
cd /mnt/003_rust_completion
sh load_module.sh
```

- Test it:
```bash
echo "Hello" > /dev/completion
cat /dev/completion
```
