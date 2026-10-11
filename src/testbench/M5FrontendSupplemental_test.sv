`timescale 1ns/1ps
// Additional finite M5-4 fixtures. Original frozen UART bench stays unchanged.
// UART uses actual serial pins/baud; map fixtures drive accepted background
// command traffic, bypassing mouse/controller/guard stimulus (never RAM/shadows).
module M5FrontendSupplemental_test;
    localparam real BIT_NS=1.0e9/115200.0;
    reg CLK100MHZ=0;
    always #5 CLK100MHZ=~CLK100MHZ;
    reg [15:0] SW=16'h0020;
    reg RsRx=1;
    wire RsTx;
    tri PS2CLK,PS2DATA;
    GlobalRender_top dut(.CLK100MHZ(CLK100MHZ),.SW(SW),.LED(),.SEG(),.AN(),
        .BTNC(1'b0),.BTNU(1'b0),.BTNL(1'b0),.BTNR(1'b0),.BTND(1'b0),.JC(),
        .VGARED(),.VGABLUE(),.VGAGREEN(),.HSYNC(),.VSYNC(),.RsRx(RsRx),.RsTx(RsTx),
        .PS2CLK(PS2CLK),.PS2DATA(PS2DATA));
    reg fixture_valid=0;
    reg [8:0] fixture_addr=0;
    reg [15:0] fixture_word=0;
    integer layout_checks=0, abort_cases=0, restart_cases=0, fid, stale_fid, i;
    reg saved_bank;
    reg [8:0] fixture_map[0:287];
    reg [39:0] fixture_entries[0:143];
    integer fixture_count=0;
    reg [15:0] fixture_cells[0:287];

    task automatic require(input bit condition,input string what);
        if (!condition) $fatal(1,"M5_FRONTEND_SUPPLEMENTAL_FAILURE %s",what);
    endtask
    task automatic send_byte(input [7:0] b);
        RsRx=0; #(BIT_NS);
        for(integer k=0;k<8;k++) begin RsRx=b[k]; #(BIT_NS); end
        RsRx=1; #(BIT_NS);
    endtask
    task automatic send_raw(input string line);
        $display("M5_SUPPLEMENTAL_RX %s",line);
        for(integer k=0;k<line.len();k++) send_byte(line[k]);
        send_byte(13); send_byte(10); repeat(10) @(posedge CLK100MHZ);
    endtask
    task automatic send_line(input string payload);
        reg [7:0] checksum;
        string upper,line;
        upper=payload.toupper(); checksum=0;
        for(integer k=0;k<upper.len();k++) checksum^=upper[k];
        line=$sformatf("@%s*%02X",upper,checksum); send_raw(line.toupper());
    endtask
    task automatic begin_stage();
        send_line($sformatf("VB,%04X,02,00",fid));
        send_line($sformatf("VN,%04X,00,DEADBEEF",fid));
        require(dut.frontend_reply_stage_active,"partial reply staged");
    endtask
    task automatic preserved(input [7:0] status,input bit valid);
        require(!dut.frontend_reply_stage_active,"stage cancelled");
        require(dut.frontend_reply_active_bank==saved_bank,"aborted stage cannot commit bank");
        require(dut.frontend_reply_valid==valid && dut.frontend_reply_status==status,
                "aborted stage preserves specified metadata");
        require((saved_bank ? dut.frontend_reply_ram1_inst.mem[0] : dut.frontend_reply_ram0_inst.mem[0])==32'h41200000,
                "aborted partial data does not overwrite published voltage");
        abort_cases++;
        $display("M5_SUPPLEMENTAL_ABORT_CASE %0d status=%02h valid=%0d",abort_cases,status,valid);
    endtask
    task automatic write_cell(input integer addr,input [15:0] word);
        @(negedge CLK100MHZ); fixture_addr=9'(addr); fixture_word=word; fixture_valid=1;
        // Reissue force on each transaction for Verilator 5.020, whose force
        // expression reevaluation differs from 5.046 for hierarchical wires.
        force dut.interaction_bg_cmd_valid=1'b1;
        force dut.interaction_bg_cmd_addr=fixture_addr;
        force dut.interaction_bg_cmd_wdata=fixture_word;
        @(posedge CLK100MHZ);
        require(dut.interaction_bg_cmd_ready && dut.interaction_bg_cmd_valid &&
                dut.interaction_bg_cmd_write && dut.interaction_bg_cmd_addr==9'(addr) &&
                dut.interaction_bg_cmd_wdata==word,"fixture write accepted with exact command");
    endtask
    task automatic clear_fixture();
        foreach(fixture_cells[k]) fixture_cells[k]=0;
    endtask
    // Independent constants define fixtures; no DUT helper or shadows drive expectations.
    task automatic pair(input integer anchor,input integer partner,input integer sprite,input integer rotation);
        require(fixture_cells[anchor]==0 && fixture_cells[partner]==0,"fixture pairs disjoint");
        fixture_cells[anchor]=16'((rotation<<7)|(sprite<<1)|1);
        fixture_cells[partner]=16'((rotation<<7)|((sprite+1)<<1)|1);
    endtask
    task automatic expect_fixture();
        fixture_count=0;
        foreach(fixture_map[k]) fixture_map[k]=9'h1ff;
        for(integer k=0;k<288;k++) begin
            integer sprite,rot,partner;
            sprite=(fixture_cells[k]>>1)&63; rot=(fixture_cells[k]>>7)&3;
            if(fixture_cells[k][0] && sprite>=5 && sprite<=13 && sprite%2==1) begin
                case(rot) 0:partner=k+1;1:partner=k+18;2:partner=k-1;3:partner=k-18;endcase
                fixture_map[k]=9'(fixture_count); fixture_map[partner]=9'(fixture_count);
                fixture_entries[fixture_count]={4'd0,9'(fixture_count),4'(sprite),2'(rot),12'd0,4'(k/18),5'(k%18)};
                fixture_count++;
            end
        end
    endtask
    task automatic check_fixture(input string label);
        wait(!dut.component_store_busy);
        // Same pre-NBA acceptance edge as production consumers; no drain wait.
        @(posedge CLK100MHZ);
        $display("M5_SUPPLEMENTAL_SELECTED_READY %s addr=286 ram=%0d read=%0d expected=%0d",label,
                 dut.component_index_map_ram_inst.mem[286],dut.selected_component_index_map_data,fixture_map[286]);
        require(dut.component_store_count==fixture_count,"fixture component count");
        for(integer k=0;k<288;k++)
            require(dut.component_index_map_ram_inst.mem[k]==fixture_map[k],$sformatf("fixture index map %0d observed=%0d expected=%0d busy=%0d w_en=%0d w_addr=%0d",k,dut.component_index_map_ram_inst.mem[k],fixture_map[k],dut.component_store_busy,dut.component_index_map_w_en,dut.component_index_map_w_addr));
        for(integer k=0;k<fixture_count;k++)
            require(dut.component_store_ram_inst.mem[k]==fixture_entries[k],$sformatf("fixture component entry %0d",k));
        layout_checks++;
        $display("M5_SUPPLEMENTAL_LAYOUT %s count=%0d",label,fixture_count);
    endtask

    task automatic apply_fixture(input string label);
        expect_fixture();
        // Clear first, then publish fixture. Two halves can share a burst; busy
        // stays asserted until rebuild. All values deliberately remain zero.
        for(integer k=0;k<288;k++) write_cell(k,0);
        for(integer k=0;k<288;k++) if(fixture_cells[k]!=0) write_cell(k,fixture_cells[k]);
        @(negedge CLK100MHZ); fixture_valid=0;
        force dut.interaction_bg_cmd_valid=1'b0;
        check_fixture(label);
    endtask
    task automatic restart_case(input integer phase,input string label,input integer sprite);
        integer age;
        // A real accepted wire edit launches a rebuild of the current layout.
        // Then change an already-scanned origin and its partner; the old map
        // cannot satisfy the literal final entry without a dirty restart.
        fixture_cells[100]=fixture_cells[100]^16'h0001; write_cell(100,fixture_cells[100]);
        @(negedge CLK100MHZ); force dut.interaction_bg_cmd_valid=1'b0;
        case(phase)
            0: wait(dut.component_index_map_clear_active && dut.component_index_map_clear_addr==100);
            1: wait(dut.component_store_rebuild_active && dut.component_store_scan_addr==140 && !dut.component_index_map_pending_pair_write);
            2: wait(dut.component_index_map_pending_pair_write && dut.component_index_map_pending_pair_addr==1);
            3: wait(dut.component_store_rebuild_active && dut.component_store_scan_addr==287 && !dut.component_index_map_pending_pair_write);
            4: wait(dut.component_store_write_drain && !dut.component_index_map_clear_active &&
                    !dut.component_store_rebuild_active && !dut.component_index_map_pending_pair_write && !dut.component_store_dirty);
        endcase
        require(dut.component_store_busy,"restart edit occurs before advertised ready");
        // Exact accepted command words, not DUT-derived values.
        fixture_cells[0]=16'((sprite<<1)|1); fixture_cells[1]=16'(((sprite+1)<<1)|1);
        write_cell(0,fixture_cells[0]); write_cell(1,fixture_cells[1]);
        @(negedge CLK100MHZ); force dut.interaction_bg_cmd_valid=1'b0;
        expect_fixture(); age=0;
        while(dut.component_store_busy && age<=1744) begin @(negedge CLK100MHZ); age++; end
        require(!dut.component_store_busy && age<=1744,"restart fixture bounded first-ready");
        check_fixture(label); restart_cases++;
        $display("M5_SUPPLEMENTAL_RESTART_CASE %s phase=%0d count=%0d cycles=%0d",label,phase,fixture_count,age);
    endtask

    initial begin
        force dut.interaction_bg_cmd_valid=1'b0;
        force dut.interaction_bg_cmd_write=1'b1;
        force dut.interaction_bg_cmd_addr=fixture_addr;
        force dut.interaction_bg_cmd_wdata=fixture_word;
        force dut.interaction_copy_value=1'b0;
        // Fixed read address distinguishes retired map storage from its one
        // cycle synchronous read. This bypasses UI selection crossing only.
        force dut.selected_cell_addr_sys=9'd286;
        force dut.has_selection_sys=1'b1;
        if($test$plusargs("m5-restart-only")) begin
            wait(dut.init_cycles>=1000 && !dut.component_store_busy);
            clear_fixture(); apply_fixture("restart-empty");
            clear_fixture(); pair(0,1,5,0); pair(287,286,9,2); apply_fixture("restart-baseline");
            restart_case(0,"during-clear",7);
            restart_case(1,"during-scan",5);
            restart_case(2,"pending-pair",7);
            restart_case(3,"final-scan",5);
            restart_case(4,"registered-drain",7);
            require(restart_cases==5,"all dirty restart phases exercised");
            $display("M5_FRONTEND_RESTART_FIXTURE cases=%0d layouts=%0d",restart_cases,layout_checks);
            $display("M5FrontendRestart_test passed"); $finish;
        end
        if($test$plusargs("m5-boundary-only")) begin
            wait(dut.init_cycles>=1000 && !dut.component_store_busy);
            clear_fixture(); pair(287,286,9,2); apply_fixture("minimal-last-cell-origin");
            $display("M5FrontendSupplemental_boundary passed"); $finish;
        end
        wait(dut.frontend_snapshot_id_valid); fid=dut.frontend_snapshot_frame; stale_fid=(fid+1)&65535;
        send_line($sformatf("VB,%04X,01,00",fid));
        send_line($sformatf("VN,%04X,00,41200000",fid));
        send_line($sformatf("VE,%04X,01,00",fid));
        require(dut.frontend_reply_valid,"initial reply committed"); saved_bank=dut.frontend_reply_active_bank;
        begin_stage(); send_raw("@VB,0000,01,00*00"); preserved(8'h83,1);
        begin_stage(); send_line($sformatf("ER,%04X,01,0000",stale_fid)); preserved(8'h83,1);
        begin_stage(); send_line($sformatf("VB,%04X,02,00",stale_fid)); preserved(8'h83,1);
        begin_stage(); send_line($sformatf("VE,%04X,02,00",fid)); preserved(8'h83,1);
        begin_stage(); send_line($sformatf("VB,%04X,01,00",fid));
        require(dut.frontend_reply_stage_active,"current begin replaces staged reply");
        send_line($sformatf("VN,%04X,00,41200000",fid)); send_line($sformatf("VE,%04X,01,00",fid));
        require(dut.frontend_reply_valid && dut.frontend_reply_status==0,"replacement reply committed");
        saved_bank=dut.frontend_reply_active_bank;
        begin_stage(); send_line($sformatf("ER,%04X,05,0000",fid)); preserved(8'h05,0);
        // No UART packets follow canvas mutations, so old valid frame assumptions
        // cannot accidentally qualify replies after the content identifier moves.
        clear_fixture(); apply_fixture("empty");
        clear_fixture();
        pair(0,1,5,0); pair(17,35,7,1); pair(286,285,9,2); pair(270,252,11,3);
        pair(150,151,13,0); fixture_cells[100]=16'h001f; fixture_cells[101]=16'h0001;
        apply_fixture("all-types-four-directions-corners");
        clear_fixture(); pair(286,287,5,0); apply_fixture("last-cell-horizontal-partner");
        clear_fixture(); pair(269,287,7,1); apply_fixture("last-cell-vertical-partner");
        clear_fixture(); apply_fixture("deleted-last-cell-component");
        $display("M5_FRONTEND_SUPPLEMENTAL_CHECKPOINT layouts=%0d abort_cases=%0d",layout_checks,abort_cases);
        clear_fixture(); pair(287,286,9,2); apply_fixture("last-cell-origin");
        require(layout_checks==6 && abort_cases==5,"all declared cases exercised");
        $display("M5_FRONTEND_SUPPLEMENTAL layouts=%0d abort_cases=%0d",layout_checks,abort_cases);
        $display("M5FrontendSupplemental_test passed"); $finish;
    end
    initial begin #500000000; $fatal(1,"M5_FRONTEND_SUPPLEMENTAL_FAILURE watchdog"); end
endmodule
