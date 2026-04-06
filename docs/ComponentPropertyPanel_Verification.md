# ComponentPropertyPanel 验证清单

## 编译检查
- [ ] ComponentPropertyPanel.v 无语法错误
- [ ] CompStoreInit.v 无语法错误
- [ ] GlobalRender_top.v 无语法错误
- [ ] 所有模块成功综合

## 功能测试

### 1. 初始化测试
- [ ] 按下 BTNC 后，CompStoreInit 开始工作
- [ ] ComponentStore RAM 成功写入 8 条测试数据
- [ ] comp_init_done 信号变为高电平

### 2. 显示测试
**测试步骤：** 在 Canvas 上点击不同位置的元件

- [ ] **地址0 (2,3)** - 显示 "Resistor" + "Value: 100 Ohm" + "Pos: (2, 3)"
- [ ] **地址1 (5,5)** - 显示 "Voltage Source" + "Value: 5 V" + "Pos: (5, 5)"
- [ ] **地址2 (8,2)** - 显示 "Capacitor" + "Value: 10u F" + "Pos: (8, 2)"
- [ ] **地址3 (3,7)** - 显示 "Inductor" + "Value: 100m H" + "Pos: (3, 7)"
- [ ] **地址4 (10,10)** - 显示 "Current Source" + "Value: 20 A" + "Pos: (10, 10)"
- [ ] **地址5 (1,1)** - 显示 "Ground" + "GND" + "Pos: (1, 1)"
- [ ] **地址6 (0,0)** - 显示 "Wire" + "R: 0 Ohm" + "Pos: (0, 0)"
- [ ] **地址7 (6,4)** - 显示 "Resistor" + "Value: 1k Ohm" + "Pos: (6, 4)"

### 3. 编辑功能测试
**测试步骤：** 点击元件 → 点击参数区域 → 输入新值 → 按 Enter

- [ ] 点击参数区域后，区域变为浅黄色高亮
- [ ] 按数字键，数值正确更新
- [ ] 按单位键，单位正确更新
- [ ] 按 Del 键，最后一位数字被删除
- [ ] 按 Enter 键，数据写回 RAM
- [ ] 重新点击该元件，显示新数值
- [ ] 按 Escape 键，取消编辑，恢复原数值

### 4. 边界情况测试
- [ ] 点击空白区域，显示 "No Selection"
- [ ] 点击空单元格，显示 "Empty Cell"
- [ ] 快速连续点击，不会卡死
- [ ] 编辑模式下点击其他元件，正确切换

## 预期显示格式

### 电阻 (Resistor)
```
第一行: Resistor (放大2倍)
第二行: Value: XXX[单位] Ohm
第三行: Pos: (X, Y)
```

### 电压源 (Voltage Source)
```
第一行: Voltage Source (放大2倍)
第二行: Value: XX[单位] V
第三行: Pos: (X, Y)
```

### 电容 (Capacitor)
```
第一行: Capacitor (放大2倍)
第二行: Value: XX[单位] F
第三行: Pos: (X, Y)
```

### 电感 (Inductor)
```
第一行: Inductor (放大2倍)
第二行: Value: XX[单位] H
第三行: Pos: (X, Y)
```

### 电流源 (Current Source)
```
第一行: Current Source (放大2倍)
第二行: Value: XX[单位] A
第三行: Pos: (X, Y)
```

### 接地 (Ground)
```
第一行: Ground (放大2倍)
第二行: GND
第三行: Pos: (X, Y)
```

### 线缆 (Wire)
```
第一行: Wire (放大2倍)
第二行: R: 0 Ohm
第三行: Pos: (X, Y)
```

## 常见问题排查

### 问题1: 显示全为 "No Selection"
**原因：** ComponentStore RAM 未初始化或读取地址错误
**解决：**
1. 检查 BTNC 是否按下触发初始化
2. 检查 comp_data_valid 信号是否为高
3. 检查 comp_r_addr 计算是否正确

### 问题2: 数值显示错误
**原因：** 数据解析错误或 ASCII 转换错误
**解决：**
1. 检查 40 位数据格式是否正确对齐
2. 检查 value[12:0] 的位分配
3. 检查 unit_to_ascii 函数

### 问题3: 编辑功能不工作
**原因：** KeyboardVGA 信号未正确连接
**解决：**
1. 检查 key_valid, key_ascii, key_is_digit 等信号
2. 检查 editing_mode 是否正确进入
3. 检查 comp_w_en 是否产生写脉冲

### 问题4: 编译报错 "multiple drivers"
**原因：** RAM 写入端口冲突
**解决：**
1. 确认使用多路选择器合并写信号
2. 检查 comp_store_w_en 和 comp_init_w_en 不会同时为高

## 调试技巧

### 使用 LED 显示状态
```verilog
// 在 GlobalRender_top.v 中添加
assign LED[0] = comp_init_done;      // 初始化完成
assign LED[1] = has_selection;       // 有选中元件
assign LED[2] = editing_mode;        // 编辑模式
assign LED[3] = comp_w_en;           // RAM 写入中
```

### 使用 ILA (Integrated Logic Analyzer)
关键信号：
- comp_r_data[39:0] - 读取的元件数据
- comp_type[3:0] - 元件类型
- comp_value[12:0] - 元件数值
- selected_cell_i, selected_cell_j - 选中坐标
- editing_mode - 编辑模式标志
- key_valid, key_ascii - 键盘输入

## 性能指标
- **响应时间：** 点击后 < 100ms 显示属性
- **刷新率：** 与 VGA 同步 (60Hz)
- **RAM 容量：** 256 个元件 (8位地址)
- **数据宽度：** 40 位
