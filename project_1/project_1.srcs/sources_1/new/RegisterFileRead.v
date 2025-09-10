module RegisterFileRead (
    input         clk,

    // write port
    input         write_enable,
    input  [4:0]  write_address,
    input  [31:0] write_data,

    // read port 1
    input         read_enable_1,
    input  [4:0]  read_address_1,
    output reg [31:0] read_data_1,

    // read port 2
    input         read_enable_2,
    input  [4:0]  read_address_2,
    output reg [31:0] read_data_2
);

    reg [31:0] regs [0:31];
    integer i;

    // (Optional for FPGA/sim) power-up init
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Synchronous write (ignore writes to x0)
    always @(posedge clk) begin
        if (write_enable && (write_address != 5'd0))
            regs[write_address] <= write_data;
    end

    // Combinational read with enables + simple bypass (“write-first”)
    always @* begin
        // defaults
        read_data_1 = 32'b0;
        read_data_2 = 32'b0;

        if (read_enable_1) begin
            if (read_address_1 == 5'd0) begin
                read_data_1 = 32'b0;
            end else if (write_enable &&
                         (write_address == read_address_1) &&
                         (write_address != 5'd0)) begin
                // same-cycle RAW -> see newly written data
                read_data_1 = write_data;
            end else begin
                read_data_1 = regs[read_address_1];
            end
        end

        if (read_enable_2) begin
            if (read_address_2 == 5'd0) begin
                read_data_2 = 32'b0;
            end else if (write_enable &&
                         (write_address == read_address_2) &&
                         (write_address != 5'd0)) begin
                read_data_2 = write_data;
            end else begin
                read_data_2 = regs[read_address_2];
            end
        end
    end

endmodule
