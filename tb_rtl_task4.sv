`timescale 1ns/1ps
module tb_rtl_task4();

// Your testbench goes here. Our toplevel will give up after 1,000,000 ticks.
// Testbench signals
    logic CLOCK_50;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [9:0] LEDR;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    logic [7:0] VGA_R, VGA_G, VGA_B;
    logic VGA_HS, VGA_VS, VGA_CLK;
    logic [7:0] VGA_X;
    logic [6:0] VGA_Y;
    logic [2:0] VGA_COLOUR;
    logic VGA_PLOT;

    // Additional signals for rectangle inputs
    logic start;
    logic [7:0] top_left_x;
    logic [6:0] top_left_y;
    logic [7:0] width;
    logic [6:0] height;
    logic [2:0] colour;

    // Instantiate the DUT (Design Under Test)
    task4 dut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .LEDR(LEDR),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
        .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_CLK(VGA_CLK),
        .VGA_X(VGA_X), .VGA_Y(VGA_Y),
        .VGA_COLOUR(VGA_COLOUR), .VGA_PLOT(VGA_PLOT)
    );

    // Clock generation (50MHz)
    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;  // 50MHz clock (period = 20 time units)
    end

    // Apply reset
    task apply_reset;
        begin
            KEY[3] = 0;  // Assert reset (active low)
            #100;        // Keep reset low for 100 time units
            KEY[3] = 1;  // Deassert reset
        end
    endtask

    // Test procedure
    initial begin
        // Initialize inputs
        KEY = 4'b1111;  // All keys inactive (KEY[3] is reset, active low)
        SW = 10'b0000000000;  // All switches set to zero
        start = 0;  // Start initially low
        colour = 3'b000;  // Default color

        // Apply reset
        apply_reset();

        // Test Case 1: Draw a rectangle at (50, 50) with width 80, height 60 and color 3'b011 (green)
        #20;
        top_left_x = 8'd50;
        top_left_y = 7'd50;
        width = 8'd80;
        height = 7'd60;
        colour = 3'b011;
        start = 1'b1;
        #100;
        start = 1'b0;  // Deassert start
        #5000;  // Wait for the rectangle to complete drawing

        // Test Case 2: Small rectangle at (100, 70) with width 40, height 20
        #100;
        top_left_x = 8'd100;
        top_left_y = 7'd70;
        width = 8'd40;
        height = 7'd20;
        colour = 3'b100;  // Red color
        start = 1'b1;
        #100;
        start = 1'b0;
        #5000;  // Wait for the rectangle to complete

        // Test Case 3: Reset during operation
        #100;
        top_left_x = 8'd60;
        top_left_y = 7'd40;
        width = 8'd50;
        height = 7'd30;
        colour = 3'b001;  // Blue color
        start = 1'b1;
        #200;
        apply_reset();  // Reset during drawing
        #1000;

        // Test Case 4: Randomized rectangles
        #100;
        repeat (5) begin
            top_left_x = $urandom % 160;
            top_left_y = $urandom % 120;
            width = $urandom % 60 + 10;
            height = $urandom % 60 + 10;
            colour = $urandom % 8;  // Random color
            start = 1'b1;
            #100;
            start = 1'b0;
            #5000;
        end

        // End the simulation
        $stop;
    end

endmodule: tb_rtl_task4
