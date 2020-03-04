---
title: Arch Linux Installation
date: 2019-07-06 18:09:31
categories: TECH
tags: 
  - linux
  - pc
  - archlinux
  - guide
---
>ddl是检验生产力的唯一标准

本次的安装是在VBox虚拟机环境下进行，物理机可能会有所出入，一切还请以Arch Linux官方wiki为准。

***

## 安装准备

### 安装介质
  1. 到 https://www.archlinux.org/download/ 页面下载最新的iso镜像文件；
  2. 使用dd（linux下）或者rufus（Windows下）制造安装介质。

### 磁盘准备
至少10GB的空闲空间，如果想日常使用，则建议至少50GB，否则连大的开发环境都不便于配置。

### BIOS设置
在BIOS中将启动项设置我们制作的安装u盘，对于虚拟机安装而言，则为将启动项设为加载了镜像文件的虚拟光驱。

***

## 安装过程

### 进入 Live CD 系统
  1. 做好安装准备后，启动便会看到如下界面：
  ![select](/images/Snipaste_2019-07-06_11-14-09.bmp)
  2. 选择第一项进入 Live CD 系统，屏幕显示如下内容：
  ![loading](/images/Snipaste_2019-07-06_11-14-36.bmp)
  加载完成后，将进入一有命令提示符的界面：
  ![done](/images/Snipaste_2019-07-06_11-14-51.bmp)
  这时便成功启动了 Live CD 系统，接下来将 Arch Linux 安装到硬盘上

### 联网
Arch的安装需要通过互联网来下载组件，故在开始正式的安装前我们要先联网。
+ 如果为有线网，并且路由器开启DHCP服务的话，则执行：
  ```
  dhcpcd
  ```
+ 如果为无线网。则执行：
  ```
  wifi-menu
  ```
  这是一个命令行下的wifi管理工具，有字符形式的图形界面。
+ 使用类似以下的命令来检测网络是否连接：
  ```
  ping www.baidu.com
  ```
+ 对于部分机器，可能存在无线网卡驱动兼容性问题，但是有线网一般是可以使用的，可以插网线装好系统后再慢慢解决驱动问题。

### 更新系统时间
执行以下命令以启用ntp服务来自动同步系统时间：
```
timedatectl set-ntp true
```

### 分区与格式化
首先检测现有的分区表，执行以下命令：
```
fdisk -l
```
可得到如下输出：
![fdisk](/images/Snipaste_2019-07-06_11-15-51.bmp)
可以看到在这块硬盘上没有分区表的存在。

考虑到虚拟机采用BIOS/MBR的引导方式，故我们使用MBR分区表以便于操作。
  1. 输入命令：
    ```
    cfdisk /dev/sdx （将sdx替换之前看到的磁盘）
    ```
  2. 选择“dos”分区方式
    ![dospar](/images/Snipaste_2019-07-06_11-18-03.bmp)
    这样我们便在磁盘上创建了一个MBR分区表，当然所有的修改在确认写入前都是没有改动实际的磁盘数据的。
    随后便会看到以下界面：
    ![cfdisk](/images/Snipaste_2019-07-06_11-18-47.bmp)
    可以再次看到，这块磁盘上没有分区存在。
  3. 使用上下左右键来移动下面的光标，选择“NEW”来新建一个分区。
    我们新建一个占据全部空间的“Linux File System”类型的主分区，注意是主分区，即primal partition，对于MBR分区表，只有主分区是可以作为启动引导分区的。随后再次移动光标，选择下方的“Bootable”，将该分区设置为可引导分区。最终效果如图：
    ![cfdisk](/images/Snipaste_2019-07-06_11-19-38.bmp)
  4. 确认无误后，移动光标选择“Write”，将我们所有的改动写入到实际的磁盘上，一旦执行了这步之后就回不了头了，所以需要多次确认后再执行，我们这次是一个空硬盘，所以怎么折腾都是可以的。最终退出该程序，分区结果如下图所示：
    ![parares](/images/Snipaste_2019-07-06_11-20-03.bmp)
  5. 输入以下命令来格式化刚刚创建的分区:
    ```
    mkfs.ext4 /dev/sdxY (将sdxY替换为刚刚创建的分区)
    ```
### 挂载分区
执行以下命令来挂载将刚刚创建的分区挂载：
```
mount /dev/sdxY /mnt (将sdxY替换为刚刚创建的分区)
```
### 安装基本软件包
接下来要开始字面意义上的安装过程了，将要把Archlinux安装到磁盘上，注意，这个过程需要保持互联网的接入。
执行以下命令开始安装：
```
pacstrap /mnt base base-devel
```
命令提示行出现以下画面，等待安装结束、命令提示符重新出现即可进行下一步。
![insa](/images/Snipaste_2019-07-06_11-22-11.bmp)

### 生成fstab
安装过程中我们是手动挂载了根目录，但是不可能每次开机都进行一次挂载操作，因此我们需要生成自动挂载分区的fstab文件。
执行以下命令：
```
genfstab -L /mnt >> /mnt/etc/fstab
```
使用cat命令将该文件输出到屏幕，如下图所示：
![fstab](/images/Snipaste_2019-07-06_11-40-36.bmp)
可以看到 /dev/sda1被挂载到根目录。

### chroot
到这一步，我们需要把操作权交给我们刚刚安装到磁盘上的操作系统，执行这步后，所以的操作都是在新装的系统进行的。
执行以下命令：
```
arch-chroot /mnt
```

### 设置时区
依次执行以下命令：
```
ln -sf /usr/share/zoneinfo/Asis/Shanghai /etc/localtime
hwclocl --systohc
```
如下图所示：
![zone](/images/Snipaste_2019-07-06_11-42-13.bmp)

### 安装必要的软件包
通过 pacman 安装vim，等接下来需要使用的软件包。
执行以下命令：
```
pacman -S vim
```

### 设置语言数据
  1. 首先使用vim打开 /etc/locale.gen 文件，并将zh_CN.UTF-8 UTF-8、zh_HK.UTF-8 UTF-8、zh_TW.UTF-8 UTF-8、en_US.UTF-8 UTF-8四行前的注释符号去除，然后保存退出。如下图所示：
    ![locale](/images/Snipaste_2019-07-06_11-46-00.bmp)
    然后执行：
    ```
    locale-gen
    ```
  2. 配置语言首选项
    使用vim打开/etc/locale.conf文件
    在文件第一行输入：
    ```
    LANG=en_US.UTF-8
    ```
    然后保存退出。

### 设置主机名
  1. 使用vim打开/etc/hostname文件，在第一行输入你想要的主机名，保存并退出。
  2. 使用vim打开/etc/hosts文件，在文件末尾添加如下三行：
  ```
  127.0.0.1 localhost
  ::1 localhost
  127.0.1.1 yourhostname (替换为你之前设定的主机名)
  ```
  保存并退出。

### 安装intel-ucode
对于intel CPU，使用pacman安装：
```
pacman -S intel-ucode
```

### 安装bootloader
  我们使用grub作为bootloader：
  1. 安装grub包：
    ```
    pacman -S grub
    ```
  2. 部署grub到引导扇区：
    ```
    grub-install --target=i386-pc /dev/sdx （将sdx替换之前看到的磁盘）
    ```
  3. 生成grub配置文件：
    ```
    grub-mkconfig -o /boot/grub/grub.cfg
    ```
![bootlo](/images/Snipaste_2019-07-06_12-23-07.bmp)
至此Bootloader的安装便结束了，建议安装后检查grub.cfg文件的生成是否正确，至于如何读懂该文件，可以参照Archlinux官方wiki。

### 修改root密码
执行以下命令：
```
passwd
```
依照提示设置密码，注意密码输入无回显。

### 重启
接下来到了最为激动人心的环节，之前的所有努力与付出都将在此时得到检验，成败再次一举。
执行如下命令：
```
exit
reboot
```
如果是物理机，则在关机后拔出u盘，如果是虚拟机，则将虚拟光驱弹出即可。
如果一切顺利，你将看到如下画面，并可以使用root用户进行登陆：
![finish1](/images/Snipaste_2019-07-06_12-25-59.bmp)

### 配置虚拟内存
我们采用文件形式的交换空间，便于我们的管理。
先分配一块空间(512M大小为例)：
```
fallocate -l 512M /swapfile
```
然后更改该空间的权限:
```
chmod 600 /swapfile
```
设置为交换文件：
```
mkswap /swapfile
```
启用交换文件：
```
swapon /swapfile
```
![swapset](/images/Snipaste_2019-07-06_12-28-02.bmp)
最后还需要修改fstab文件来实现自动启用交换文件，如下图所示进行修改：
![swapfstab](/images/Snipaste_2019-07-06_12-29-09.bmp)

### 新建用户
我们的日常操作不可能以root用户的身份进行，这样是极不安全的。因此我们新建一个权限较低的用户日常使用。
```
useradd -m -G wheel username
```
我们新建了一个名为username的用户，并将它加入了wheel组，同时也为它在/home目录下新建了同名的家目录。

### 配置sudo
首先使用pacman安装sudo软件包：
```
pacman -S sudo
```
当然，在使用pacman之前，你需要先连接网络，具体操作与 Live CD 系统的操作一致。
然后使用visudo编辑sudo的配置文件：
将
```
# %wheel ALL=(ALL) ALL
```
前的注释去除，退出保存即可。
![visudo](/images/Snipaste_2019-07-06_12-53-30.bmp)
配置好sudo以后，我们再次重启电脑，并且以新建的用户登陆系统，并且记得需要重新进行联网操作。

### 安装图形化界面
我使用了xfce作为本次安装的桌面管理器，其他桌面的安装大同小异。
直接使用pacman安装图形界面和桌面的软件包：
```
sudo pacman -S xorg xfce sddm
```
同时我们需要安装桌面使用的网络连接管理软件networkmanager:
``` 
sudo pacman -S networkmanager
```
随后安装完毕后，我们需要启用我们刚刚安装的sddm桌面管理器，以方便我们在开机后进行登陆并选择使用的桌面。
使用systemctl来管理系统服务：
```
sudo systemctl enable sddm
```
同时我们需要提前配置网络，将自带的netctl换为networkmanager：
```
sudo systemctl disable netctl
sudo systemctl enable NetworkManger
```
然后重启，如果一切顺利，你将成功看到桌面管理器界面，输入用户名和密码后便可以进入桌面环境。
![desktop](/images/Snipaste_2019-07-06_12-55-00.bmp)

## 最后
>依照惯例：
![res](/images/Snipaste_2019-07-06_13-02-07.bmp)