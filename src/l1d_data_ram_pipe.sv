module l1d_data_ram_pipe
import l1d_package::*;
(
    //arbiter
    input  logic                         dat_ram_pipe_vld            ,
    output logic                         dat_ram_pipe_rdy            ,
    input  pack_dat_ram_pld              dat_ram_pipe_pld            ,
    //upstream 
    output logic                         upstream_ack_en             ,
    output logic [REQ_DATA_WIDTH-1:0]    upstream_ack_dat            ,
    output sb_payld                      upstream_sb_pld             ,

    //write adapter 
    output logic                         evict_en                    ,
    output logic [L1D_MSHR_ID_WIDTH-1:0] evict_id                    ,
    output logic [REQ_ID_WIDHT-1:0]      evict_dat
);
//sram 
logic                         rw_en            ;
logic                         rw_type          ;
logic [DATA_RAM_DEPTH-1:0]    rw_dat_addr      ;
logic [DATA_RAM_WIDTH-1:0]    rd_dat           ;
logic [DATA_RAM_WIDTH-1:0]    wr_dat           ;
logic [DATA_RAM_WIDTH-1:0]    wr_dat_merge     ;


//buf for wr
logic [DATA_RAM_WIDTH-1:0]    wr_dat_buf      ;
logic [DATA_RAM_DEPTH-1:0]    wr_dat_addr_buf ; 
logic                         wr_dat_buf_vld  ;
logic [L1D_MSHR_ID_WIDTH-1:0] wr_ID_buf       ;
logic [REQ_DATA_EN_WIDTH-1:0] wr_be_buf       ;
sb_payld                      wr_sb_buf       ;

//behavior 
logic                         dat_ram_hs      ;
logic                         wr_part_byte    ;

//buf for upstream
logic                         upstream_vld    ;

//------------------------
//---------behavior
//------------------------
assign dat_ram_hs       = dat_ram_pipe_vld && dat_ram_pipe_rdy                                                                   ;
assign wr_part_byte     = !(&dat_ram_pipe_pld.wr_data_byte_en) && !dat_ram_pipe_pld.rw_type && !dat_ram_pipe_pld.op_is_downstream;
assign dat_ram_pipe_rdy = !wr_dat_buf_vld                                                                                        ;
//------------------------
//---------addr decoder
//------------------------

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                      wr_dat_buf_vld <= 1'b0;
    else if(dat_ram_hs && wr_part_byte )            wr_dat_buf_vld <= 1'b1;
    else if(wr_dat_buf_vld)                         wr_dat_buf_vld <= 1'b0;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)  begin
        wr_dat_buf      <= {REQ_DATA_WIDTH{1'b0}}           ;
        wr_dat_addr_buf <= {DATA_RAM_DEPTH{1'b0}}           ;
        wr_sb_buf       <= {$bits(sb_payld){1'b0}}          ;
        wr_be_buf       <= {REQ_DATA_EN_WIDTH{1'b0}}        ;
        wr_ID_buf       <= {L1D_MSHR_ID_WIDTH{1'b0}}        ;
    end
    // else if(dat_ram_hs) begin
    else begin
        wr_dat_buf      <= dat_ram_pipe_pld.rw_data        ;
        wr_dat_addr_buf <= dat_ram_pipe_pld.dat_ram_addr   ;
        wr_sb_buf       <= dat_ram_pipe_pld.wr_sb_pld      ;
        wr_be_buf       <= dat_ram_pipe_pld.wr_data_byte_en;
        wr_ID_buf       <= dat_ram_pipe_pld.wr_ID          ;
    end
end
assign rw_dat_addr = wr_dat_buf_vld ? wr_dat_addr_buf : dat_ram_pipe_pld.dat_ram_addr ;

//------------------------
//---------sp data ram
//------------------------
genvar i;
generate for(i=0;i<REQ_DATA_EN_WIDTH;i++) begin
    assign wr_dat_merge[i*8:+8] = wr_be_buf[i] ? wr_dat_buf[i*8:+8]:rd_dat[i*8:+8];
end
endgenerate
assign wr_dat  = wr_dat_buf_vld ? wr_dat_merge : dat_ram_pipe_pld.rw_data          ;
assign rw_en   = dat_ram_hs     || wr_dat_buf_vld                                  ;
assign rw_type = wr_dat_buf_vld ? 1'b0         : dat_ram_pipe_pld.rw_type          ;

sp_sram#(
    .DATA_WIDTH(DATA_RAM_WIDTH),   
    .ADDR_WIDTH(DATA_RAM_DEPTH)    
)u_data_ram(
    .clk        (clk        ),      
    .rst_n      (rst_n      ),    
    .en         (rw_en      ),       
    .rw         (rw_type    ),       
    .addr       (rw_dat_addr),     
    .data_in    (wr_dat     ),  
    .data_out   (rd_dat     ) 
);

//------------------------
//---------upstream
//------------------------
always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                                upstream_ack_en <= 1'b0;
    else if(dat_ram_hs && !dat_ram_pipe_pld.op_is_downstream) upstream_ack_en <= 1'b1;
    else                                                      upstream_ack_en <= 1'b0;
end

assign upstream_sb_pld  = wr_sb_buf               ;
assign upstream_ack_dat = rd_dat                  ;
//---------------------------------
//---------downstream write adpater
//---------------------------------
always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                                                           evict_en <= 1'b0;
    else if(dat_ram_hs && dat_ram_pipe_pld.op_is_downstream && dat_ram_pipe_pld.rw_type) evict_en <= 1'b1;
    else                                                                                 evict_en <= 1'b0;
end
assign evict_id  = wr_ID_buf;
assign evict_dat = rd_dat   ;
endmodule