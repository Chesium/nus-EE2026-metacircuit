`timescale 1ns/1ps
module M5ReplyIntegrity_test;
  localparam real BIT_NS=1.0e9/115200.0;
  reg CLK100MHZ=0;always #5 CLK100MHZ=~CLK100MHZ;
  reg RsRx=1,BTNR=0;tri PS2CLK,PS2DATA;
  GlobalRender_top dut(.CLK100MHZ(CLK100MHZ),.SW(16'h0020),.LED(),.SEG(),.AN(),
    .BTNC(1'b0),.BTNU(1'b0),.BTNL(1'b0),.BTNR(BTNR),.BTND(1'b0),.JC(),
    .VGARED(),.VGAGREEN(),.VGABLUE(),.HSYNC(),.VSYNC(),.RsRx(RsRx),.RsTx(),
    .PS2CLK(PS2CLK),.PS2DATA(PS2DATA));
  reg [15:0] id;reg saved_bank;integer cases=0,lines=0;
  reg corrupt=0;string selected_case;
  function automatic [7:0] checksum(input string s);
    reg [7:0] c;c=0;for(integer k=0;k<s.len();k++)c=c^s[k];return c;
  endfunction
  function automatic [31:0] stored(input integer node);
    reg [31:0] x;
    x=dut.frontend_reply_active_bank?dut.frontend_reply_ram1_inst.mem[node]:dut.frontend_reply_ram0_inst.mem[node];
    return x ^ (corrupt?32'd1:32'd0);
  endfunction
  task automatic require(input bit ok,input string label);
    if(!ok)$fatal(1,"M5_REPLY_FAILURE %s",label);
  endtask
  task automatic byte_send(input reg[7:0] b);
    RsRx=0;#(BIT_NS);for(integer k=0;k<8;k++)begin RsRx=b[k];#(BIT_NS);end
    RsRx=1;#(BIT_NS);
  endtask
  task automatic line_send(input string payload);
    string p,line;p=payload.toupper();line=$sformatf("@%s*%02X",p,checksum(p));line=line.toupper();
    $display("M5_REPLY_RX %s",line);lines++;
    for(integer k=0;k<line.len();k++)byte_send(line[k]);byte_send(13);byte_send(10);
    repeat(16)@(negedge CLK100MHZ);
  endtask
  task automatic begin_packet(input integer nodes);
    line_send($sformatf("VB,%04X,%02X,00",id,nodes));
  endtask
  task automatic node_packet(input integer node,input reg[31:0] bits);
    line_send($sformatf("VN,%04X,%02X,%08X",id,node,bits));
  endtask
  task automatic end_packet(input integer nodes);
    line_send($sformatf("VE,%04X,%02X,00",id,nodes));
  endtask
  task automatic seed_valid(input string label);
    $display("M5_REPLY_CASE %s",label);begin_packet(2);node_packet(0,32'h41200000);node_packet(1,32'h40a00000);end_packet(2);
    require(dut.frontend_reply_valid && dut.frontend_reply_frame==id && dut.frontend_reply_node_count==2 && dut.frontend_reply_status==0,"accepted metadata");
    require(stored(0)==32'h41200000 && stored(1)==32'h40a00000,"accepted value");
    saved_bank=dut.frontend_reply_active_bank;cases++;
  endtask
  task automatic retained(input string label);
    require(dut.frontend_reply_valid && dut.frontend_reply_active_bank==saved_bank && dut.frontend_reply_frame==id && dut.frontend_reply_node_count==2,
      {label," committed malformed metadata"});
    require(stored(0)==32'h41200000 && stored(1)==32'h40a00000,{label," committed malformed values"});
    require(!dut.frontend_reply_stage_active && dut.frontend_reply_status==8'h83,{label," did not cancel stage"});cases++;
  endtask
  initial begin
    #1000000000;$fatal(1,"M5_REPLY_FAILURE watchdog");
  end
  initial begin
    corrupt=$test$plusargs("m5-corrupt-reply-observation");selected_case="all";
    if($value$plusargs("case=%s",selected_case))begin end
    wait(dut.frontend_snapshot_id_valid && !dut.component_store_busy);
    @(negedge CLK100MHZ);id=dut.frontend_snapshot_frame;
    require(id!=0,"actual boot snapshot");
    seed_valid("seed");
    if(selected_case=="all" || selected_case=="duplicate")begin
      $display("M5_REPLY_CASE duplicate");begin_packet(2);node_packet(0,32'h40400000);node_packet(0,32'h40800000);end_packet(2);retained("duplicate");seed_valid("duplicate-recovery");
    end
    if(selected_case=="all" || selected_case=="range")begin
      $display("M5_REPLY_CASE range");begin_packet(2);node_packet(0,32'h40400000);node_packet(2,32'h40800000);end_packet(2);retained("range");seed_valid("range-recovery");
    end
    if(selected_case=="all" || selected_case=="missing")begin
      $display("M5_REPLY_CASE missing");begin_packet(2);node_packet(0,32'h40400000);end_packet(2);retained("missing");seed_valid("missing-recovery");
    end
    if(selected_case=="all" || selected_case=="capacity")begin
      $display("M5_REPLY_CASE reverse-order");begin_packet(2);node_packet(1,32'h40000000);node_packet(0,32'h3f800000);end_packet(2);
      require(dut.frontend_reply_valid && dut.frontend_reply_status==0 && dut.frontend_reply_node_count==2 && stored(0)==32'h3f800000 && stored(1)==32'h40000000,"reverse order legal packet");cases++;
      $display("M5_REPLY_CASE capacity-32");begin_packet(32);for(integer k=31;k>=0;k--)node_packet(k,32'h3f800000+k);end_packet(32);
      require(dut.frontend_reply_valid && dut.frontend_reply_status==0 && dut.frontend_reply_node_count==32,"capacity32 metadata");
      for(integer k=0;k<32;k++)require(stored(k)==32'h3f800000+k,"capacity32 value");cases++;
      for(integer k=1;k<32;k++)begin
        @(negedge CLK100MHZ);BTNR=1;repeat(4)@(negedge CLK100MHZ);BTNR=0;repeat(16)@(negedge CLK100MHZ);
        require(dut.frontend_reply_view_node==k,"capacity32 navigation");
        require(dut.frontend_reply_view_value==32'h3f800000+k,"capacity32 synchronous view");
      end
      @(negedge CLK100MHZ);BTNR=1;repeat(4)@(negedge CLK100MHZ);BTNR=0;repeat(16)@(negedge CLK100MHZ);
      require(dut.frontend_reply_view_node==31,"capacity32 navigation boundary");
      begin_packet(32);for(integer k=31;k>=0;k--)node_packet(k,32'h3f800000+k);end_packet(32);
      require(dut.frontend_reply_view_node==31,"capacity32 selection preserved on commit");cases++;

      $display("M5_REPLY_CASE empty");begin_packet(0);end_packet(0);
      require(dut.frontend_reply_valid && dut.frontend_reply_status==0 && dut.frontend_reply_node_count==0,"empty metadata");cases++;
    end
    require(dut.frontend_snapshot_frame==id,"source remained current");
    $display("M5_REPLY_INTEGRITY_PASS cases=%0d lines=%0d",cases,lines);$finish;
  end
endmodule
