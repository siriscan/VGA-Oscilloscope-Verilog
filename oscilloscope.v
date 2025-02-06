module oscilloscope(
    input clk,
    input rst,
    output reg convstb,
    output reg hsync,
    output reg vsync,
    
    input busy,
    output reg csb,
    output reg rdb,
    input [7:0] db,
    output [3:0] red,
    output [3:0] blue,
    output [3:0] green
    );
    
    reg [7:0] buffer[479:0]; //(V_ACTIVE_VIDEO: 480 lines)
    reg [7:0] buffer_count = 8'b0;
    
    // 10 ns clock cycle
    parameter CONVSTB_PULSE = 3;
    parameter CONVSTB2BUSY_DELAY = 3;
    parameter  CONVERT_TIME = 450;
    
    parameter CS_START = CONVERT_TIME;
    parameter CS_TIME = 40;
    parameter CS_TOTAL_TIME = CS_TIME + CONVERT_TIME;
    
    parameter WRITE_DELAY = 1;
    
    
    parameter TOTAL_TIME = 500;
    
    reg [12:0] c_counter; //0 to 4999
    
    
    // Lab 4 VGA parameters
    parameter H_SYNC_CYCLES = 96;       // Pulse width
    parameter H_BACK_PORCH = 48;       // Back porch
    parameter H_ACTIVE_VIDEO = 640;    // Active
    parameter H_FRONT_PORCH = 16;      // Front porch
    parameter H_TOTAL_CYCLES = 800;    // 800 Clocks
    
    parameter H_VISIBLE_START = H_BACK_PORCH;
    parameter H_VISIBLE_END = H_BACK_PORCH + H_ACTIVE_VIDEO;



    parameter V_SYNC_CYCLES = 2;       // Pulse width
    parameter V_BACK_PORCH = 29;       // Back porch
    parameter V_ACTIVE_VIDEO = 480;    // Active 
    parameter V_FRONT_PORCH = 10;      // Front porch
    parameter V_TOTAL_LINES = 521;     // 521 Lines

    parameter V_VISIBLE_START = V_BACK_PORCH;
    parameter V_VISIBLE_END = V_BACK_PORCH + V_ACTIVE_VIDEO;


    // Counters (Lab 4)
    reg [9:0] h_counter;  //0 to 799
    reg [9:0] v_counter; // 0 to 520

    // Generate Pixel Clock MHz25 (Lab 4)
    reg [1:0] pixel_clk_div; // 2-bit counter to divide by 4 (for 25 MHz)
    wire pixel_clk = (pixel_clk_div == 2'b11);
    
    
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                c_counter <= 13'd0;
            
            end else begin
                
                // Increment c counter on 100MHz clock
                if (c_counter == TOTAL_TIME - 1)
                    c_counter <= 13'd0;
                else
                    c_counter <= c_counter + 1'b1;
    
            end
        end



    // Generate convstb
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            convstb <= 1'b1;
        end else begin
            if (c_counter < CONVSTB_PULSE) begin
                convstb <= 1'b0; // active low
            end else begin
                convstb <= 1'b1; // inactive            
            end
        end
    end
    
    // Generate CS/RD
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdb <= 1'b1;
            csb <= 1'b1;
        end else begin
            if (c_counter>=CS_START && c_counter < CS_TOTAL_TIME && ~busy) begin
                rdb <= 1'b0;
                csb <= 1'b0; // active low
           end else begin
                rdb <= 1'b1;
                csb <= 1'b1; // inactive            
           end
        end
    end 
   
   // Writing buffer
    always @(posedge clk) begin
        if (~rst) begin
            if ( c_counter>=CS_START+WRITE_DELAY && c_counter < CS_TOTAL_TIME+WRITE_DELAY && ~busy ) begin
                buffer[buffer_count] <= db;
                buffer_count <= buffer_count + 9'b1;
            end
        end
    end
   
   //Lab 4 stuff
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_counter <= 10'd0;
            pixel_clk_div <= 2'd0;
        end else begin
        
            // Pixel clock division
            pixel_clk_div <= pixel_clk_div + 1'b1;
            
            if (pixel_clk) begin
            
                // Increment horizontal counter on pixel clock
                if (h_counter == H_TOTAL_CYCLES - 1)
                    h_counter <= 10'd0;
                else
                    h_counter <= h_counter + 1'b1;
            end
        end
    end

    // Generate hsync
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hsync <= 1'b0;
        end else begin
            if (h_counter < H_SYNC_CYCLES)
                hsync <= 1'b0; // active low
            else
                hsync <= 1'b1; // inactive
                
                
            
                
                
        end
    end

    // vsync pulse
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_counter <= 10'd0;
        end else begin
            if (pixel_clk) begin
            
                // Increment vertical counter on each pixel clock
                if (h_counter == H_TOTAL_CYCLES - 1) begin
                    if (v_counter == V_TOTAL_LINES - 1)
                        v_counter <= 10'd0;
                    else
                        v_counter <= v_counter + 1'b1;
                end
            end
        end
    end

    // Generate vsync
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            vsync <= 1'b0;
            
        end else begin
            if (v_counter < V_SYNC_CYCLES)
                vsync <= 1'b0; // active low
            else
                vsync <= 1'b1; // inactive
                               
                
        end
    end

// Pixel position (x, y) calculation based off of the counters


    // Color generation for the flag
    reg [3:0] r, g, b;

    initial begin
        r = 4'h0;
        g = 4'h0;
        b = 4'h0;
    end 

    wire [9:0] x = h_counter - H_VISIBLE_START;
    wire [9:0] y = v_counter - V_VISIBLE_START;

    always @(*) begin
    
        // Default color is black 
        r = 4'h0; 
        g = 4'h0;
        b = 4'h0;
        
        // Adjust vertical position within visible area
        if (h_counter >= H_VISIBLE_START && h_counter < H_VISIBLE_END && v_counter >= V_VISIBLE_START && v_counter < V_VISIBLE_END) begin

            // Display buffer data as vertical lines 
            if (y == buffer[buffer_count]) begin // White color for the waveform line 
                r = 4'hF; 
                g = 4'hF; 
                b = 4'hF; 
            end
            
        end
    end
    
    assign red = (x < H_ACTIVE_VIDEO && y < V_ACTIVE_VIDEO) ? r : 4'h0;
    assign green = (x < H_ACTIVE_VIDEO && y < V_ACTIVE_VIDEO) ? g : 4'h0;
    assign blue = (x < H_ACTIVE_VIDEO && y < V_ACTIVE_VIDEO) ? b : 4'h0;
endmodule