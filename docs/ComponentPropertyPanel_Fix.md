# ComponentPropertyPanel 修复说明

## 已修复的问题

### 1. 未使用的信号声明
**问题：** 以下信号被声明但未使用，导致编译警告/错误
- `wire value_area_click`
- `wire [11:0] pixel_x`
- `wire [11:0] pixel_y`
- `reg [11:0] mouse_rel_x`
- `reg [11:0] mouse_rel_y`
- `reg mouse_in_value_area`
- `reg value_area_clicked`

**修复：** 已删除这些未使用的信号声明

### 2. ComponentStore RAM 写入冲突
**问题：** ComponentPropertyPanel 和 CompStoreInit 同时写入 RAM 会导致冲突

**修复：** 在 GlobalRender_top.v 中使用多路选择器合并两个写接口：
```verilog
.w_en(comp_store_w_en | comp_init_w_en),
.w_addr(comp_store_w_en ? comp_store_w_addr : comp_init_addr),
.d_in(comp_store_w_en ? comp_store_w_data : comp_init_data),
```

### 3. 测试数据初始化
**新增：** 创建了 `CompStoreInit.v` 模块，在系统启动时自动写入测试数据

## 测试数据说明

CompStoreInit 会在上电后自动写入以下测试数据到 ComponentStore RAM：

| 地址 | 元件类型 | 位置 | 参数值 | 说明 |
|------|---------|------|--------|------|
| 0 | Resistor (电阻) | (2,3) | 100 Ohm | 100欧姆电阻 |
| 1 | Voltage Source (电压源) | (5,5) | 5 V | 5伏电压源 |
| 2 | Capacitor (电容) | (8,2) | 10 uF | 10微法电容 |
| 3 | Inductor (电感) | (3,7) | 100 mH | 100毫亨电感 |
| 4 | Current Source (电流源) | (10,10) | 20 mA | 20毫安电流源 |
| 5 | Ground (接地) | (1,1) | - | 接地点 |
| 6 | Wire (线缆) | (0,0) | - | 线缆 |
| 7 | Resistor (电阻) | (6,4) | 1 kOhm | 1千欧电阻 |

## 使用说明

### 测试步骤
1. **上电复位**：按下 BTNC 按钮触发 CompStoreInit 初始化
2. **查看属性**：在 Canvas 上点击任意元件，顶部会显示该元件的属性
3. **编辑参数**：点击参数区域（第二行），然后使用虚拟键盘输入新值
4. **确认修改**：按 Enter 键确认修改，修改会立即写入 RAM

### 键盘操作
- **数字键 (0-9)**：输入数值
- **单位键 (M/k/m/u/n/p)**：选择单位乘数
- **Del/Backspace**：删除最后一位数字
- **Enter**：确认并保存
- **Escape**：取消编辑

### 元件类型编码
```
4'b0000 = Wire (线缆)
4'b0001 = Ground (接地)
4'b0010 = Resistor (电阻)
4'b0011 = Capacitor (电容)
4'b0100 = Inductor (电感)
4'b0101 = Voltage Source (电压源)
4'b0110 = Current Source (电流源)
```

### 40位数据格式
```
[39:36] - type (4位)      : 元件类型
[35:28] - position (8位)  : 位置 (Xpos[3:0] + Ypos[3:0]<<4)
[27:26] - rotation (2位)  : 旋转角度
[25:13] - value (13位)    : 数值 (10位数值 + 3位单位)
[12:9]  - node1 (4位)     : 节点1
[8:5]   - node2 (4位)     : 节点2
```

## 注意事项

1. **初始化时机**：CompStoreInit 会在 BTNC 复位后约 40ms 开始写入数据
2. **写入优先级**：正常运行时，ComponentPropertyPanel 的写入优先于初始化
3. **编辑模式**：点击参数区域会进入编辑模式，参数区域会高亮显示（浅黄色）
4. **数据保留**：修改后的数据保存在 RAM 中，断电后会丢失

## 可能的问题

如果编译时仍有报错，请检查：
1. 所有文件是否已正确添加到 Vivado 项目
2. DynamicTextBox 模块是否存在且端口匹配
3. SimpleRam 模块的端口是否正确
4. 是否有其他模块依赖旧版 ComponentPropertyPanel 接口
