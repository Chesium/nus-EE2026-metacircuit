所有module都是start-busy-done形式，也就是：

module calc

input clk;

input start;
output busy;
output done;

input [...] parameters;

output [...] results;

上述形式。

user将start置为1时（仅一cycle），开始对parameters进行处理，如获取某个RAM的值，如

always set read_en to start

always set read_address to parameters

always set result to read_data

always set busy to 0

always (posedge clk)
 done <= start;


----

assume we use 6 bit to store node index

NAME                  PARAMETERS          RESULT WIDTH
fetchCell             i(5)  j(4)              16
fetchComponentType    idx(9)                  4   (16 types)
fetchAnchorPositionX  idx(9)                  5
fetchAnchorPositionY  idx(9)                  4
fetchRotation         idx(9)                  2   (4 rotations)
fetchValue            idx(9)      
storeNode0            idx(9) node_i(6)       (NO OUTPUT) -> link to dashboard
storeNode1            idx(9) node_i(6)       (NO OUTPUT) -> link to dashboard
fetchNode0            idx(9)                  6
fetchNode1            idx(9)                  6
storeVoltage          idx(9) value(32)       (NO OUTPUT) -> Result Display (*)
setColor              i(5) j(4) c1(4) c2(4)  (NO OUTPUT)
                                前景   背景