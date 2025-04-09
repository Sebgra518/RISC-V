module RegisterFileRead (
    input clk,
    input reset,
    
    input write_enable,  
    input [4:0] write_address,
    input [31:0] write_data,
    
    input read_enable_1,                     // Read enable for rs1
    input [4:0] read_address_1,          // Read source 1 address
    output reg [31:0] read_data_1,    // Data read from source 1
     
    input read_enable_2,                     // Read enable for rs2
    input [4:0] read_address_2,          // Read source 2 address
    output reg [31:0] read_data_2     // Data read from source 2
);

    reg [31:0] regs[0:31];
    integer i;

    // Synchronous write and reset
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (write_enable && write_address != 0) begin
            regs[write_address] <= write_data;
        end
    end

    // Read logic with enable
    always @(*) begin
        read_data_1 = 32'b0;
        read_data_2 = 32'b0;

        if (read_enable_1)
            read_data_1 = (read_address_2 != 0) ? regs[read_address_1] : 32'b0;
        if (read_enable_2)
            read_data_2 = (read_address_2 != 0) ? regs[read_address_1] : 32'b0;
    end
endmodule
