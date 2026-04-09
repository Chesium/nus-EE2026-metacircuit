`timescale 1ns / 1ps

module Design2_CurrentToolLabel_test;
    import ToolbarPkg::*;

    reg        clk_pixel = 1'b0;
    reg        video_on = 1'b1;
    reg [11:0] hcount = 12'd0;
    reg [11:0] vcount = 12'd0;
    reg [3:0]  selected_mode = MODE_SELECT;

    wire rendered;
    wire [11:0] rgb;

    always #20 clk_pixel = ~clk_pixel;

    CurrentToolLabel dut (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .selected_mode(selected_mode),
        .rendered(rendered),
        .rgb(rgb)
    );

    task automatic sample_pixel(input [11:0] sx, input [11:0] sy);
        begin
            hcount = sx;
            vcount = sy;
            @(posedge clk_pixel);
            #1;
        end
    endtask

    initial begin
        selected_mode = MODE_SELECT;
        sample_pixel(12'd538, 12'd10);
        if (!rendered || (rgb != 12'hFFF)) begin
            $fatal(1, "CurrentToolLabel did not render SELECT text");
        end

        selected_mode = MODE_RES;
        sample_pixel(12'd538, 12'd10);
        if (!rendered || (rgb != 12'hFFF)) begin
            $fatal(1, "CurrentToolLabel did not render RESISTOR text");
        end

        selected_mode = MODE_DELETE;
        sample_pixel(12'd632, 12'd10);
        if (rendered) begin
            $fatal(1, "CurrentToolLabel rendered outside its intended bounds");
        end

        $display("Design2_CurrentToolLabel_test passed");
        $finish;
    end
endmodule
