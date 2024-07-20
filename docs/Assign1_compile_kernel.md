# Assign 1: Build and Compile Linux Kernel
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