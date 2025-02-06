module testbench;

    reg clk;               // 100 MHz input clock
    reg rst;               // Reset signal

    wire convstb;
    
    wire hsync;
    wire vsync;
    
    reg busy;
    wire csb;
    wire rdb;
    reg [7:0] db;
    wire [3:0] red;
    wire [3:0] blue;
    wire [3:0] green;




    oscilloscope gc0(clk,rst,convstb,hsync,vsync,busy,csb,rdb,db,red,blue,green);

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // Generate 100 MHz clock (10 ns period)
    end

    //
    initial begin
        db = 9'd400;
        #500;
        db = 9'd150;
        #500;
        db = 9'd400;
        #500;
        db = 9'd150;
        #500;
        db = 9'd400;
        #500;
        db = 9'd150;
        #500;
    end

    // Timings
    initial begin
        busy = 1'b0;
        rst = 1'b1; 
        #20;
        
        //Cycle 1     
        rst = 1'b0; 
        
        #35;
        
        busy = 1'b1;
        
        #4500;
        
        busy = 1'b0;
        
        #470;
        
        //Cycle 2
        
        #30;
        
        busy = 1'b1;
        
        #4500;
        
        busy = 1'b0;
        
        #470;

    end

    
    always @(posedge clk) begin
        $display("clk=%b time=%d convstb=%b",clk,$time,convstb);
    end

endmodule