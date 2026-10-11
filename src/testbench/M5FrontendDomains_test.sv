`timescale 1ns/1ps
// Finite domain fixtures on real frontend ports. Mouse/UI selection and keypad
// hit testing are bypassed; memories, edit state and CDC event registers are not.
module M5FrontendDomains_test;
    reg CLK100MHZ=0;
    always #5 CLK100MHZ=~CLK100MHZ;
    tri PS2CLK,PS2DATA;
    GlobalRender_top dut(.CLK100MHZ(CLK100MHZ),.SW(16'h0020),.LED(),.SEG(),.AN(),
        .BTNC(1'b0),.BTNU(1'b0),.BTNL(1'b0),.BTNR(1'b0),.BTND(1'b0),.JC(),
        .VGARED(),.VGABLUE(),.VGAGREEN(),.HSYNC(),.VSYNC(),.RsRx(1'b1),.RsTx(),
        .PS2CLK(PS2CLK),.PS2DATA(PS2DATA));
    reg [8:0] command_addr=0, selection_addr=286;
    reg [15:0] command_word=0;
    reg [7:0] key_ascii=0;
    reg [11:0] selection_i=16,selection_j=15;
    reg [15:0] cells[0:287];
    reg [11:0] values[0:287];
    reg [3:0] units[0:287];
    reg [8:0] maps[0:287];
    reg [39:0] entries[0:143];
    integer origins[0:143], partners[0:143];
    integer count=0, layouts=0, keyboard_events=0, selections=0, phases=0, blocked_clocks=0;
    reg keyboard_event_seen_before;

    task automatic require(input bit condition,input string what);
        if(!condition) $fatal(1,"M5_DOMAINS_FAILURE %s",what);
    endtask
    task automatic select_addr(input integer address);
        @(negedge CLK100MHZ); selection_addr=9'(address);selection_i=12'(address%18);selection_j=12'(address/18);
        force dut.selected_cell_i=selection_i;force dut.selected_cell_j=selection_j;
        repeat(12) @(negedge CLK100MHZ);
    endtask
    task automatic write_cell(input integer address,input [15:0] word);
        @(negedge CLK100MHZ); command_addr=9'(address); command_word=word;
        force dut.interaction_bg_cmd_valid=1'b1;
        force dut.interaction_bg_cmd_addr=command_addr;
        force dut.interaction_bg_cmd_wdata=command_word;
        @(posedge CLK100MHZ);
        require(dut.interaction_bg_cmd_valid && dut.interaction_bg_cmd_ready &&
                dut.interaction_bg_cmd_write && dut.interaction_bg_cmd_addr==9'(address) &&
                dut.interaction_bg_cmd_wdata==word && !dut.pending_pair_value_write &&
                !(dut.keyboard_edit_event && dut.edit_value_valid),"exact background write accepted without higher priority writer");
    endtask
    task automatic idle_commands();
        @(negedge CLK100MHZ); force dut.interaction_bg_cmd_valid=1'b0;
    endtask
    task automatic clear_fixture();
        foreach(cells[k]) begin cells[k]=0;values[k]=0;units[k]=0;end
    endtask
    task automatic pair(input integer origin,input integer partner,input integer sprite,input integer rotation);
        require(cells[origin]==0 && cells[partner]==0,"disjoint paired geometry");
        cells[origin]=16'((rotation<<7)|(sprite<<1)|1);
        cells[partner]=16'((rotation<<7)|((sprite+1)<<1)|1);
    endtask
    task automatic expect_fixture();
        count=0;foreach(maps[k])maps[k]=9'h1ff;
        for(integer k=0;k<288;k++) begin
            integer sprite,rot,partner;
            sprite=(cells[k]>>1)&63;rot=(cells[k]>>7)&3;
            if(cells[k][0] && sprite>=5 && sprite<=13 && sprite%2==1)begin
                case(rot)0:partner=k+1;1:partner=k+18;2:partner=k-1;3:partner=k-18;endcase
                require(partner>=0 && partner<288,"literal partner bounds");
                maps[k]=9'(count);maps[partner]=9'(count);origins[count]=k;partners[count]=partner;
                entries[count]={units[k],9'(count),4'(sprite),2'(rot),values[k],4'(k/18),5'(k%18)};
                count++;
            end
        end
    endtask
    task automatic ready_fixture(input string label);
        integer age;
        expect_fixture();age=0;
        while(dut.component_store_busy && age<=1744)begin @(negedge CLK100MHZ);age++;end
        require(!dut.component_store_busy && age<=1744,"bounded first readiness");
        @(posedge CLK100MHZ);
        require(dut.component_store_count==count,$sformatf("literal component count observed=%0d expected=%0d",dut.component_store_count,count));
        for(integer k=0;k<288;k++)begin
            require(dut.component_index_map_ram_inst.mem[k]==maps[k],$sformatf("literal map %0d",k));
            require((dut.value_shadow_data[k]^ (($test$plusargs("m5-inject-keyboard-value") && values[k]!=0)?12'd1:12'd0))==values[k],"keyboard literal value");
            require((dut.value_unit_shadow_data[k]^ (($test$plusargs("m5-inject-keyboard-unit") && units[k]!=0)?4'd1:4'd0))==units[k],"keyboard literal unit");
        end
        for(integer k=0;k<count;k++) require(dut.component_store_ram_inst.mem[k]==entries[k],"literal packed entry");
        layouts++;
        $display("M5_DOMAINS_LAYOUT %s count=%0d",label,count);
    endtask
    task automatic apply_fixture(input string label);
        for(integer k=0;k<288;k++)write_cell(k,0);
        for(integer k=0;k<288;k++)if(cells[k]!=0)write_cell(k,cells[k]);
        idle_commands();ready_fixture(label);
    endtask
    task automatic key(input [7:0] ascii,input bit accepted);
        // Exactly one semantic keypad pulse at the real pixel-side input. The
        // DUT toggles and synchronizes its own event, samples its own RAM/text,
        // performs the edit, then writes the second half through its pending path.
        if(accepted)require(dut.selected_is_editable && dut.value_edit_active_sys,"selected keypad property editable before pulse");
        @(negedge dut.clk_pixel);key_ascii=ascii;keyboard_event_seen_before=dut.keyboard_event_seen;
        force dut.keyboard_key_ascii=key_ascii;
        force dut.keyboard_key_valid=1'b1;
        @(negedge dut.clk_pixel);force dut.keyboard_key_valid=1'b0;
        wait(dut.keyboard_event_seen!=keyboard_event_seen_before);
        keyboard_events++;
        $display("M5_DOMAINS_KEY ascii=%02h selection=%0d enabled=%0d cell=%04h editable=%0d clear=%0d event_ascii=%02h",ascii,dut.selected_cell_addr_sys,dut.has_selection_sys,dut.selected_cell_data_sys,dut.selected_is_editable,dut.clear_canvas_active,dut.keyboard_ascii_sys_ff1);
        repeat(12)@(negedge CLK100MHZ);
        if(accepted)require(!dut.pending_pair_value_write,"paired keyboard write drained");
    endtask
    task automatic edit_literal(input integer index,input string text,input [11:0] bcd,input [3:0] unit_code,input string label);
        integer origin,partner;
        origin=origins[index];partner=partners[index];
        // Alternate origin and partner selection; both must route to the same
        // property's stored text and update both physical halves.
        select_addr(index%2==0?origin:partner);
        key(8'h7f,1);
        for(integer k=0;k<text.len();k++)key(text[k],1);
        values[origin]=bcd;values[partner]=bcd;units[origin]=unit_code;units[partner]=unit_code;
        ready_fixture(label);
        $display("M5_DOMAINS_VALUE %s origin=%0d partner=%0d bcd=%03h unit=%0d",label,origin,partner,bcd,unit_code);
    endtask
    task automatic check_selection(input integer address,input string label,input bit enabled);
        integer idx,origin;
        @(negedge CLK100MHZ);
        if(enabled)force dut.has_selection=1'b1;else force dut.has_selection=1'b0;
        select_addr(address);
        if(enabled)begin
            idx=maps[address];
            require((dut.selected_component_index_map_data^($test$plusargs("m5-inject-domain-selection")?9'd1:9'd0))==9'(idx),"selection literal map read");
            require(dut.selected_component_index_valid_sys==(idx!=511),"selection valid transition");
            require(dut.selected_component_index_sys==9'(idx),"selection literal index");
            if(idx!=511)begin
                origin=origins[idx];
                require(dut.selected_component_unit_sys==units[origin] && dut.selected_component_value_sys==values[origin] &&
                        dut.selected_component_position_sys==9'((origin/18)*32+origin%18) && dut.selected_component_rotation_sys==cells[origin][8:7],"selection literal property");
            end
        end else require(!dut.selected_component_index_valid_sys && dut.selected_component_index_sys==511,"selection disabled transition");
        selections++;
        $display("M5_DOMAINS_SELECTION %s addr=%0d enabled=%0d",label,address,enabled);
    endtask
    task automatic phase_edit(input integer phase,input string label,input [7:0] digit,input [11:0] bcd);
        // Launch a rebuild through an actual no-op sprite write, then a keyboard
        // edit crosses independently while the old pass occupies a named phase.
        select_addr(origins[0]);
        write_cell(287,cells[287]);idle_commands();
        case(phase)
            0:wait(dut.component_index_map_clear_active && dut.component_index_map_clear_addr==100);
            1:wait(dut.component_store_rebuild_active && dut.component_store_scan_addr==100 && !dut.component_index_map_pending_pair_write);
            2:wait(dut.component_index_map_pending_pair_write && dut.component_index_map_pending_pair_addr==partners[0]);
            3:wait(dut.component_store_write_drain && !dut.component_store_rebuild_active && !dut.component_index_map_pending_pair_write && !dut.component_index_map_clear_active && !dut.component_store_dirty);
        endcase
        require(dut.component_store_busy,"keyboard stimulus begins during named phase");
        key(8'h7f,1);key(digit,1);
        values[origins[0]]=bcd;values[partners[0]]=bcd;units[origins[0]]=0;units[partners[0]]=0;
        ready_fixture(label);phases++;
        $display("M5_DOMAINS_PHASE %s phase=%0d",label,phase);
    endtask
    initial begin
        force dut.interaction_bg_cmd_valid=1'b0;force dut.interaction_bg_cmd_write=1'b1;
        force dut.interaction_copy_value=1'b0;force dut.interaction_value_read_en=1'b0;
        force dut.selected_cell_i=selection_i;force dut.selected_cell_j=selection_j;force dut.has_selection=1'b1;
        force dut.value_edit_active=1'b1;force dut.keyboard_key_valid=1'b0;
        wait(dut.init_cycles>=1000 && !dut.component_store_busy);
        clear_fixture();apply_fixture("empty");
        // Every2x2tile contains two components. 72tiles fill all288cells with
        // 144disjoint components; four directions and all five types coexist.
        for(integer row=0;row<16;row+=2)for(integer col=0;col<18;col+=2)begin
            integer base,block,rot,sprite;
            base=row*18+col;block=(row/2)*9+col/2;rot=block%4;sprite=5+2*(block%5);
            case(rot)
                0:begin pair(base,base+1,sprite,rot);pair(base+18,base+19,sprite,rot);end
                1:begin pair(base,base+18,sprite,rot);pair(base+1,base+19,sprite,rot);end
                2:begin pair(base+1,base,sprite,rot);pair(base+19,base+18,sprite,rot);end
                3:begin pair(base+18,base,sprite,rot);pair(base+19,base+1,sprite,rot);end
            endcase
        end
        apply_fixture("capacity-144");require(count==144,"maximum disjoint capacity");
        edit_literal(0,"123M",12'h123,1,"resistor-three-digits-M");
        edit_literal(1,"45k",12'h045,2,"two-digits-k");
        edit_literal(2,"67m",12'h067,3,"two-digits-m");
        edit_literal(3,"89u",12'h089,4,"two-digits-u");
        edit_literal(4,"12n",12'h012,5,"two-digits-n");
        edit_literal(5,"34p",12'h340,6,"resistor-two-digits-p");
        edit_literal(6,"99",12'h990,0,"no-unit");
        // Delete suffix, append a different suffix, literal dot and extra digit
        // while BCD is bounded by component type. Each expected word is literal.
        select_addr(origins[0]);key(8'h08,1);key("p",1);key(".",1);key("4",1);
        values[origins[0]]=12'h123;values[partners[0]]=12'h123;units[origins[0]]=6;units[partners[0]]=6;
        ready_fixture("text-only-extra-digit");
        $display("M5_DOMAINS_VALUE text-only-extra-digit origin=%0d partner=%0d bcd=123 unit=6",origins[0],partners[0]);
        check_selection(origins[0],"origin",1);check_selection(partners[0],"partner",1);
        check_selection(origins[143],"last-origin",1);check_selection(partners[143],"last-partner",1);
        check_selection(0,"disabled",0);check_selection(origins[1],"reenabled",1);
        phase_edit(0,"clear-keyboard", "7",12'h700);
        phase_edit(1,"scan-keyboard", "8",12'h800);
        phase_edit(2,"pair-keyboard", "9",12'h900);
        phase_edit(3,"drain-keyboard", "1",12'h100);
        // Global DEL on a disabled selection invokes real canvas clear. Hold
        // an exact background command while ready is low, withdraw before it
        // could be accepted, and verify that clear/storage publication wins.
        force dut.has_selection=1'b0;select_addr(0);key(8'h7f,0);
        require(dut.clear_canvas_active && !dut.interaction_bg_cmd_ready,"clear creates actual command backpressure");
        @(negedge CLK100MHZ);command_addr=9'd287;command_word=16'h000b;
        force dut.interaction_bg_cmd_addr=command_addr;force dut.interaction_bg_cmd_wdata=command_word;
        force dut.interaction_bg_cmd_valid=1'b1;
        repeat(20)begin @(posedge CLK100MHZ);require(!dut.interaction_bg_cmd_ready,"held background command stalled by clear");blocked_clocks++;end
        idle_commands();clear_fixture();ready_fixture("clear-backpressure");
        check_selection(287,"empty-selected",1);check_selection(287,"empty-disabled",0);
        require(layouts==15 && selections==8 && phases==4 && blocked_clocks==20,"all domain cases exercised");
        $display("M5_FRONTEND_DOMAINS layouts=%0d keyboard_events=%0d selections=%0d phases=%0d blocked_clocks=%0d capacity=144",layouts,keyboard_events,selections,phases,blocked_clocks);
        $display("M5FrontendDomains_test passed");$finish;
    end
    initial begin #2000000;$fatal(1,"M5_DOMAINS_FAILURE watchdog");end
endmodule
