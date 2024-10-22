module tb_rtl_reuleaux();

    // Testbench signals
    logic clk, rst_n, start;
    logic [2:0] colour;
    logic [7:0] centre_x, diameter;  // Use diameter for Reuleaux triangle
    logic [6:0] centre_y;

    // Outputs
    logic done, vga_plot;
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [2:0] vga_colour;

    // Instantiate the DUT (Design Under Test)
    reuleaux dut (
        .clk(clk),
        .rst_n(rst_n),
        .colour(colour),
        .centre_x(centre_x),
        .centre_y(centre_y),
        .diameter(diameter),  // Changed from radius to diameter
        .start(start),
        .done(done),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .vga_colour(vga_colour),
        .vga_plot(vga_plot)
    );

    // Generate 50MHz clock
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;  // 50MHz clock
    end

    // Apply reset task
    task apply_reset;
        begin
            rst_n = 0;
            #40;  // Keep reset active for 40 time units
            rst_n = 1;
        end
    endtask

    // Task to start drawing a Reuleaux triangle
    task start_reuleaux(input logic [7:0] cx, input logic [6:0] cy, input logic [7:0] dia, input logic [2:0] col);
        begin
            @(posedge clk);
            centre_x = cx;
            centre_y = cy;
            diameter = dia;  // Using diameter
            colour = col;
            start = 1;
            #20 start = 0;  // Deassert start after 1 cycle
        end
    endtask

    // Test procedure to ensure all branches and states are covered
    initial begin
        // Initialize inputs
        rst_n = 1;
        start = 0;
        colour = 3'b000;
        centre_x = 8'b0;
        centre_y = 7'b0;
        diameter = 8'b0;

        // Apply reset
        apply_reset();
            #10;
        apply_reset();
        #30;
        apply_reset();
        #70;
        apply_reset();
        #120;
        apply_reset();
        #140;
        apply_reset();
        #200;
        apply_reset();
        #400;
        apply_reset();
        #800;
        apply_reset();
        #1200;
        apply_reset();
        #1300;
        apply_reset();
        #1500;
        apply_reset();
        #1657;
        apply_reset();
        #2044;
        apply_reset();
        #4201;
        apply_reset();
        #7433;
        apply_reset();


        // Test Case 1: Basic operation after reset
        start_reuleaux(8'd80, 7'd60, 8'd40, 3'b011);  // Green Reuleaux triangle at center (80, 60), diameter 40
        repeat (5000) @(posedge clk);  // Wait for completion

        // Additional test cases with varying parameters
        start_reuleaux(8'd100, 7'd70, 8'd20, 3'b100);  // Red triangle at (100, 70), diameter 20
        repeat (3000) @(posedge clk);  // Wait for completion

        // Edge case with maximum diameter
        start_reuleaux(8'd90, 7'd60, 8'd255, 3'b111);  // Max diameter
        repeat (6000) @(posedge clk);  // Let it run for enough cycles

        // Test Case 4: Minimal triangle (smallest possible diameter)
        start_reuleaux(8'd110, 7'd80, 8'd5, 3'b010);  // Smallest possible triangle to cover minimal diameter
        repeat (1000) @(posedge clk);

        // Test Case 5: Triangle near boundary conditions (off the edge of the VGA display)
        start_reuleaux(8'd150, 7'd115, 8'd30, 3'b001);  // Triangle near the edge of the screen
        repeat (4000) @(posedge clk);  // Ensure it runs for enough cycles

        // Test Case 6: Triangle centered near (0,0) (corner case for center coordinates)
        start_reuleaux(8'd0, 7'd0, 8'd50, 3'b111);  // Test near (0, 0) for center coordinates
        repeat (3000) @(posedge clk);  // Ensure enough cycles to complete the operation

        // Test Case 7: Reset during triangle drawing
        start_reuleaux(8'd90, 7'd50, 8'd30, 3'b001);  // Start drawing a triangle
        repeat (500) @(posedge clk);  // Let it run for a few cycles
        apply_reset();  // Apply reset during operation
        repeat (1000) @(posedge clk);  // Continue after reset to ensure recovery

        // Test Case 8: Systematically cover critical branches
        start_reuleaux(8'd80, 7'd60, 8'd40, 3'b001);  // Triangle with offset_x and offset_y boundary cases
        repeat (5000) @(posedge clk);  // Wait for completion

        // Randomized input testing for broader coverage
        for (int i = 0; i < 100; i++) begin
            // Generate random values for each parameter
            start_reuleaux($urandom % 160, $urandom % 120, $urandom % 60 + 1, $urandom % 8);  // Random parameters
            repeat (2000) @(posedge clk);  // Shorter random tests
        end

        // Additional structured tests to check specific values
        for (int i = 0; i < 8; i++) begin
            for (int j = 1; j <= 4; j++) begin
                start_reuleaux(8'd50, 7'd50, j * 40, i);  // Cover all colours and various diameters
                repeat (4000) @(posedge clk);  // Wait for completion
            end
        end

        // Apply multiple resets to ensure robustness
        for (int k = 0; k < 10; k++) begin
            apply_reset();
            repeat (1000) @(posedge clk);
        end

        $stop;  // End simulation
    end


endmodule: tb_rtl_reuleaux
