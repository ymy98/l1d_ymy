module sp_sram#(
    parameter integer unsigned  DATA_WIDTH = 8,   
    parameter integer unsigned  ADDR_WIDTH = 8    
)(
    input  logic                  clk,      
    input  logic                  rst_n,    
    input  logic                  en,       
    input  logic                  rw,       
    input  logic [ADDR_WIDTH-1:0] addr,     
    input  logic [DATA_WIDTH-1:0] data_in,  
    output logic [DATA_WIDTH-1:0] data_out  
);

    logic [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];
    integer i ;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
                data_out <= {DATA_WIDTH{1'b0}};
            for(i=0;i<(2**ADDR_WIDTH);i++) begin
                mem[i]   <= {DATA_WIDTH{1'b0}};
            end
        end else if (en) begin
            if (rw) begin
                data_out <= mem[addr];
            end else begin
                mem[addr] <= data_in;
            end
        end
    end

endmodule