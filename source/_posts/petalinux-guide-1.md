---
title: Petalinux 入门指南：Petalinux的介绍与安装
date: 2020-05-30 10:04:52
categories: TECH
tags: 
  - fpga
  - guide
---

## 1st 序

Xilinx的文档一向以“烂”著称，而Petalinux有关的文档则是集大成者，如果你发现某处出现了magic command，那很可能只是在某文档的小字里面淡淡描述过。  
该文章系列一共有三部分，分别是Petalinux的介绍与安装，你的第一个Petalinux工程，以及Petalinux的网络配置，有关IP核的开发和设备树等涉及硬件的开发这个系列不涉及。如果安装过程中出现某些奇怪的报错内容，还请google一下。  
考虑到Xilinx的服务器全部位于海外，如果你正在看着这篇文章，并试图去跟着完成Petalinux的开发，那么请现在就去开始下载。注意，**下载与你所使用的硬件开发工具(如Vivado)大版本号相同的Petalinux**。  
Petalinux本身并不复杂，许多功能也不magic，只是你不知道，Xilinx也不告诉你，我会试图分析并解释这些功能。考虑到部分内容也只是我的经验之谈，如有错误还请指正。

***

## 2nd Petalinux 101

> 参考：  
> homepage: https://www.xilinx.com/products/design-tools/embedded-software/petalinux-sdk.html  
> ug1144: https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/ug1144-petalinux-tools-reference-guide.pdf

按照较为商业的说法，Petalinux是一个“解决方案”，**而非Linux发行版**，Petalinux为用户提供从定制内核和rootfs，编译内核和rootfs以及打包启动镜像并部署至开发板的全套功能。同时为了提升效率，Petalinux可以与类似Vivado之类的“Xilinx 硬件开发工具”配合使用，比如可以导入**Vivado导出的硬件描述文件和bitstream文件**构建一个PS+PL的项目。  
Petalinux是随着zynq等arm+fpga这类组合芯片的出现而诞生的，解决了在这类arm+fpga芯片上移植linux等等琐事。如果不使用Petalinux，用户需要手动编译kernel和u-boot，然后将编译得到的镜像在Vivado等工具中，与FSBL、bitstream手动打包成启动镜像，然后拷贝至sd卡进行启动，Petalinux则将这所有工作集中到一套sdk中，同时提供独立的qemu虚拟机便于测试应用程序能否在fpga板上正确运行。  

Petalinux本身主要由两大部分组成：
+ 一个配置、编译、开发工具包 (*PetaLinux Tools*)  
+ 一个Xilinx开发的Linux发行版 (*Reference Linux Distribution*)  

接下来我们一一介绍这两个部分。

### PetaLinux Tools (host)

Petalinux Tools是一个大的“软件合集”，包括如Petalinux的cli，应用、驱动的模板，系统镜像打包工具，QEMU模拟器以及GCC工具链等等工具，提供从创建文件夹到在开发板运行系统的一条龙服务。  
开发人员可以使用这些工具来自定义引导加载程序，Linux内核或Linux应用程序。他们可以通过QEMU进行仿真，或网络和JTAG在物理硬件上运行系统内核，添加设备驱动程序，应用程序，库以及启动和测试软件。  
根据其功能，这些工具主要被分为三类，分别是：
+ 自定义板机支持包生成工具：  
可以通过“Xilinx 硬件开发工具”导出的文件自动生成一个定制的Linux Board Support Package，其中包括内核和引导加载程序的配置，以及IP核驱动程序。
+ Linux配置工具：  
用于自定义引导加载程序，Linux内核，文件系统，库和系统参数的工具。与普通kernel的配置工具不同，这些配置工具将“完全知晓Xilinx硬件开发工具，并且可以读取自定义硬件有关的文件”。  
换句话说，这些工具能够配置一些fpga特有的功能，同时可以读取你开发的PL部分（如IP，或者什么其他的Verilog代码），并进行正确的配置（如获取正确的GPIO寄存器地址）。
+ 软件开发工具:  
用于开发驱动程序、应用程序以及函数库。能够创建相应的工程模板，并能够编译、打包和分发软件组件（software components），使开发人员不需要过多关心编译相关的底层问题，并能够轻松的在开发板上安装和使用自己开发的程序。

### Reference Linux Distribution  

PetaLinux提供一个完整的参考Linux发行版，该发行版已针对Xilinx的FPGA设备进行了集成和测试。  
这个发行版包含以下内容：  
- Boot loader
- 优化过的kernel
- 基本的Linux软件和运行库
- Debug工具
- 对多线程和FPU计算的支持
- 集成式web服务器

当然，你可以使用其他的Linux发行版作为rootfs，比如ubuntu minimal等等，但是一般来说使用Petalinux自带的参考Linux发行版就足够了。

自此，我们完整的介绍了Petalinux，所以Petalinux是什么？工具包+Linux发行版。

***

## 3rd 安装Petalinux

> 参考：  
> ug976: https://www.xilinx.com/support/documentation/sw_manuals/petalinux2013_10/ug976-petalinux-installation.pdf

大体上用户只需要执行安装包即可，但是Petalinux的安装脚本仅仅适配了REHL系发行版，这意味在其他发行版可能存在环境问题，需要我们手动配置环境。  
**注意：请确保安装Petalinux的磁盘有至少50GiB的空闲容量，推荐至少有100GiB的空闲容量**  

### step 1 下载安装包

考虑到Petalinux的“安装包”实际上是一个“脚本”，并且在安装过程中需要进行解压操作，如果压缩部分出现少量错误，极有可能耗费数个小时但无功而返，因此请务必在下载完成后**检查下载文件的hash值是否一致**，若不一致还请重新下载。  
此外，请尽可能保证Petalinux和硬件开发工具的大版本号一致（如"2019.2"中的"2019"），以确保硬件描述文件等等是通用、可接受的。

### step 2 配置运行环境

参见ug976 11页表格，请根据你的发行版安装所需要的软件包。
如果你使用的是Debian/Ubuntu发行版，那么可以尝试以下指令：

``` 
sudo apt install tofrodos iproute gawk make net-tools libncurses5-dev tftpd zlib1g:i386 libssl-dev flex bison libselinux1 gnupg wget diffstat chrpath socat xterm autoconf libtool tar unzip texinfo zlib1g-dev gcc-multilib build-essential screen pax gzip
```
如果报错，请查看报错的软件包是否因为版本**更新而改用其他名称**。

### step 3 安装

执行petalinux-vxxxx.xx-final-installer.run，即你下载的安装包，它会默认安装至当前工作目录，即你执行安装包的目录。
1. 安装过程需要解压缩，安装总耗时取决于磁盘性能，从半小时到数小时不等。  
2. 安装中途需要进行数次手动确认，因此请时不时看一下安装进度。  
3. 如果提示“tftp server”未运行，**请暂时忽视**，这并不会影响Petalinux的安装。
4. 使用systemctl或者init.d启动tftp server即可，可能需要手动创建tftp用于收发文件的目录，根据错误提示手动创建目录即可。  
5. 运行安装包**请勿**使用root权限，如果报出权限错误，请检查该安装包是否未被赋予**可执行权限**。

### step 4 验证安装

安装完成后，**进入安装目录**。  
如果你是bash/zsh用户，请source setting.sh：
```
$ source ./setting.sh
```
如果你还仍然坚持使用c shell，请source setting.csh:
```
$ source ./setting.csh
```

你应该在终端上看见类似如下所示的输出：
```
PetaLinux environment set to ’/opt/petalinux-v2019.1-final’
INFO: Finalising PetaLinux installation
INFO: Checking free disk space
INFO: Checking installed tools
INFO: Checking installed development libraries
INFO: Checking network and other services
```
  
随后，请检查工作目录环境变量是否配置正确：
```
$ echo $PETALINUX
/opt/petalinux-v2019.1-final
```
该环境变量的值应该指向Petalinux的安装目录。
