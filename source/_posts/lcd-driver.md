---
title: STM32驱动LCD屏幕
date: 2018-03-04 15:43:55
categories: TECH
tags: 
  - stm32
---
本文中使用的LCD驱动芯片为ili9341，下文中简称为驱动芯片。
官方的PDF就不摆上来了，自己去这找找就行了[Google](https://www.google.com/ncr)。

# 配置

- MCU为STM32F103ZE，主频72Mhz，使用Spi与驱动芯片通讯，Spi时钟频率为18Mhz。
- 鉴于驱动芯片可以设定显示窗口（即改写选定部分的显存数据，如将窗口设定为x=20;y=30;宽=50;高=70）,可以使用DMA来提高数据传输效率，尤其是在显示文字的过程中，可以直接将文字对于的点阵转换为一个n*n的图片，再一次性的发送给驱动芯片。
- 但是使用时需要注意检测前一次的DMA发送是否已经完成，否则会出现数据传输不完整的错误。
- 使用PB1，2引脚作为驱动芯片的DC引脚和RST引脚。

# 底层IO函数

- 驱动芯片在写入寄存器时不再明显的区分指令寄存器和显存寄存器，写入指令不在是“索引+对于寄存器的数据”，而改为“指令+[参数/数据]”的格式，简而言之，无论是修改设置还是发送图像数据，其实都是一条指令以及相应的数据。
- 在发送指令时，先应将DC脚拉低，在通过Spi发送两个字节的数据，随后将RS脚拉高即可。
- 发送数据较为简单，在指定寄存器索引后直接在Spi上传出数据即可。
- 同时应注意到，有些指令是没有数据的，如“开始显示画面”，有些指令的数据量则十分巨大，如“写入显存”，这也是“索引+数据”和“指令+[参数/数据]”模式最大的区别，即后者发送的指令本身的功能就不仅仅只是指定寄存器，亦可以修改某些数据。
- 如果需要硬重启需要将RST引脚从高电位拉低，再拉高，同时应当适当加入延时。

---

发送指令

```cxx
void writeCommand(uint8_t cmd){
HAL_GPIO_WritePin(GPIOB,GPIO_PIN_1,GPIO_PIN_RESET);
HAL_SPI_Transmit(&hspi1,&cmd,1,2);
HAL_GPIO_WritePin(GPIOB,GPIO_PIN_1,GPIO_PIN_SET);
}
```

发送数据

```cxx
void spiWrite(uint8_t data){
HAL_SPI_Transmit(&hspi1,&data,1,2);
}
```

重启

```cxx
void lcdRestart(void){
HAL_GPIO_WritePin(GPIOB,GPIO_PIN_2,GPIO_PIN_SET);
HAL_Delay(100);
HAL_GPIO_WritePin(GPIOB,GPIO_PIN_2,GPIO_PIN_RESET);
HAL_Delay(100);
HAL_GPIO_WritePin(GPIOB,GPIO_PIN_2,GPIO_PIN_SET);
HAL_Delay(200);
}
```

# 初始化

初始化过程参见PDF，主要包括电源控制，内存访问控制和屏幕刷新相关设置的初始化（暂时先鸽了），其中伽马矫正部分需LCD屏幕供应者提供相应的参数（或者随便输一点）。

---
初始化

```cxx
writeCommand(0xEF);
spiWrite(0x03);
spiWrite(0x80);
spiWrite(0x02);

writeCommand(0xCF);
spiWrite(0x00);
spiWrite(0XC1);
spiWrite(0X30);

writeCommand(0xED);
spiWrite(0x64);
spiWrite(0x03);
spiWrite(0X12);
spiWrite(0X81);

writeCommand(0xE8);
spiWrite(0x85);
spiWrite(0x00);
spiWrite(0x78);

writeCommand(0xCB);
spiWrite(0x39);
spiWrite(0x2C);
spiWrite(0x00);
spiWrite(0x34);
spiWrite(0x02);

writeCommand(0xF7);
spiWrite(0x20);

writeCommand(0xEA);
spiWrite(0x00);
spiWrite(0x00);

writeCommand(ILI9341_PWCTR1);  //Power control
spiWrite(0x23);  //VRH[5:0]

writeCommand(ILI9341_PWCTR2);  //Power control
spiWrite(0x10);  //SAP[2:0];BT[3:0]

writeCommand(ILI9341_VMCTR1);  //VCM control
spiWrite(0x3e);
spiWrite(0x28);

writeCommand(ILI9341_VMCTR2);  //VCM control2
spiWrite(0x86);

writeCommand(ILI9341_MADCTL);  //Memory Access Control
spiWrite(0x48);

writeCommand(ILI9341_VSCRSADD);  //Vertical scroll
spiWrite(0x00);
spiWrite(0x00);  //Zero

writeCommand(ILI9341_PIXFMT);
spiWrite(0x55);

writeCommand(ILI9341_FRMCTR1);
spiWrite(0x00);
spiWrite(0x18);

writeCommand(ILI9341_DFUNCTR);  //Display Function Control
spiWrite(0x08);
spiWrite(0x82);
spiWrite(0x27);

writeCommand(0xF2);  //3Gamma Function Disable
spiWrite(0x00);

writeCommand(ILI9341_GAMMASET);  //Gamma curve selected
spiWrite(0x01);

writeCommand(ILI9341_GMCTRP1);  //Set Gamma
spiWrite(0x0F);
spiWrite(0x31);
spiWrite(0x2B);
spiWrite(0x0C);
spiWrite(0x0E);
spiWrite(0x08);
spiWrite(0x4E);
spiWrite(0xF1);
spiWrite(0x37);
spiWrite(0x07);
spiWrite(0x10);
spiWrite(0x03);
spiWrite(0x0E);
spiWrite(0x09);
spiWrite(0x00);

writeCommand(ILI9341_GMCTRN1);  //Set Gamma
spiWrite(0x00);
spiWrite(0x0E);
spiWrite(0x14);
spiWrite(0x03);
spiWrite(0x11);
spiWrite(0x07);
spiWrite(0x31);
spiWrite(0xC1);
spiWrite(0x48);
spiWrite(0x08);
spiWrite(0x0F);
spiWrite(0x0C);
spiWrite(0x31);
spiWrite(0x36);
spiWrite(0x0F);

writeCommand(ILI9341_SLPOUT);  //Exit Sleep
HAL_Delay(120);
writeCommand(ILI9341_DISPON);  //Display on
HAL_Delay(120);
```

To be continued.