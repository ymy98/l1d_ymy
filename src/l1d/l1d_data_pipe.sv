module l1d_data_pipe
import l1d_package::*;
(
    input logic                                             clk                                         ,
    input logic                                             rst_n                                       ,
    //bypass
    input  pack_l1d_tag_rsp                                 tag_pipe_rsp_pld                            ,
    input  logic                                            tag_pipe_rsp_vld                            ,
    output logic                                            tag_pipe_rsp_rdy                            ,
    //downstream linefill rsp
    input  logic                                            downstream_rsp_vld                          ,
    output logic                                            downstream_rsp_rdy                          ,
    input  pack_l1d_data_pipe_downstream_rsp                downstream_rsp_pld                          ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]                    downstream_rsp_id                           ,
    //rw
    output logic                                            rw_req_rdy                                  ,
    input  logic                                            rw_req_vld                                  ,
    input  pack_l1d_mshr_rw_req_pld                         rw_req_pld                                  ,
    //evict
    output logic                                            evict_req_rdy                               , 
    input  logic                                            evict_req_vld                               ,
    input  pack_l1d_mshr_evict_req_pld                      evict_req_pld                               ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]                    evict_req_id                                ,
    //upstream ack
    output logic                                            upstream_ack_en                             ,
    output logic [REQ_DATA_WIDTH-1:0]                       upstream_ack_dat                            ,
    output sb_payld                                         upstream_sb_pld                             ,
    //downstream evict req
    output logic                                            downstream_evict_vld                        ,
    output pack_l1d_data_ram_evict_req                      downstream_evict_pld                        ,    
    //mshr 
    output logic [L1D_MSHR_ID_WIDTH-1:0]                    linefill_done_id                            ,
    output logic                                            linefill_done_en                            ,
    output logic [L1D_MSHR_ID_WIDTH-1:0]                    evict_dat_ram_clean_id                      ,
    output logic                                            evict_dat_ram_clean_en                      ,
    output logic [L1D_MSHR_ID_WIDTH-1:0]                    evict_done_id                               ,
    output logic                                            evict_done_en                                             
);


//==================================================================
//===================internal signals
//==================================================================

//------data_ram_req
pack_l1d_data_ram_req       data_ram_req_pld        ;
logic [DATA_RAM_DEPTH-1:0]  data_ram_addr           ;
logic [REQ_DATA_WIDTH-1:0]  data_ram_din            ;
logic [REQ_DATA_WIDTH-1:0]  data_ram_dout           ;
logic                       data_ram_en             ;
logic                       data_ram_wr             ;
//-----upstream adpater
//==================================================================
//===================arbiter
//==================================================================
//------fixed arbiter: bypass > rw > linefill > evict
assign tag_pipe_rsp_rdy   = 1'b1                                                        ;
assign rw_req_rdy         = !tag_pipe_rsp_vld                                           ;  
assign downstream_rsp_rdy = !tag_pipe_rsp_vld && !rw_req_vld                            ;
assign evict_req_rdy      = !tag_pipe_rsp_vld && !rw_req_vld  && !downstream_rsp_vld    ;

//------data_ram_pld
always_comb begin
        data_ram_req_pld.way         = evict_req_pld.way           ;
        data_ram_req_pld.index       = evict_req_pld.index         ;
        data_ram_req_pld.offset      = evict_req_pld.offset        ;
        data_ram_req_pld.op_is_read  = 1'b1                        ;
        data_ram_req_pld.wr_data     = tag_pipe_rsp_pld.wr_data    ;
        data_ram_req_pld.wr_data_be  = tag_pipe_rsp_pld.wr_data_be ;
    if(tag_pipe_rsp_vld)        begin
        data_ram_req_pld.way         = tag_pipe_rsp_pld.way        ;
        data_ram_req_pld.index       = tag_pipe_rsp_pld.index      ;
        data_ram_req_pld.offset      = tag_pipe_rsp_pld.offset     ;
        data_ram_req_pld.op_is_read  = tag_pipe_rsp_pld.op_is_read ;
        data_ram_req_pld.wr_data     = tag_pipe_rsp_pld.wr_data    ;
        data_ram_req_pld.wr_data_be  = tag_pipe_rsp_pld.wr_data_be ;
    end
    else if(rw_req_vld)         begin
        data_ram_req_pld.way         = rw_req_pld.way              ;
        data_ram_req_pld.index       = rw_req_pld.index            ;
        data_ram_req_pld.offset      = rw_req_pld.offset           ;
        data_ram_req_pld.op_is_read  = rw_req_pld.op_is_read       ;
        data_ram_req_pld.wr_data     = rw_req_pld.wr_data          ;
        data_ram_req_pld.wr_data_be  = rw_req_pld.wr_data_be       ;
    end
    else if(downstream_rsp_vld) begin
        data_ram_req_pld.way         = downstream_rsp_pld.way      ;
        data_ram_req_pld.index       = downstream_rsp_pld.index    ;
        data_ram_req_pld.offset      = downstream_rsp_pld.offset   ;
        data_ram_req_pld.op_is_read  = 1'b0                        ;
        data_ram_req_pld.wr_data     = downstream_rsp_pld.wr_data  ;
        data_ram_req_pld.wr_data_be  = {REQ_DE_WIDTH{1'b1}}        ;
    end
end

assign linefill_done_en = downstream_rsp_vld && downstream_rsp_rdy && downstream_rsp_pld.wr_last;
assign linefill_done_id = downstream_rsp_id                                                     ;

//==================================================================
//===================data ram pld
//==================================================================
//-----data ram
assign data_ram_req_rdy = 1'b1;
assign data_ram_wr      = !data_ram_req_pld.op_is_read                                          ;
assign data_ram_en      = tag_pipe_rsp_vld || rw_req_vld || downstream_rsp_vld || evict_req_vld ;
assign data_ram_din     = data_ram_req_pld.wr_data                                              ;
assign data_ram_addr    = {data_ram_req_pld.way,data_ram_req_pld.index,data_ram_req_pld.offset} ;

sp_sram#(
    .DATA_WIDTH(REQ_DATA_WIDTH), 
    .ADDR_WIDTH(DATA_RAM_DEPTH  )
)u_sp_sram(
    .clk        (clk          ),      
    .rst_n      (rst_n        ),    
    .en         (data_ram_en  ),       
    .rw         (data_ram_wr  ),       
    .addr       (data_ram_addr),     
    .data_in    (data_ram_din ),  
    .data_out   (data_ram_dout)   
);
//==================================================================
//===================upstream adapter
//==================================================================
always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n)                                  upstream_ack_en <= 1'b0;
    else if (tag_pipe_rsp_vld || rw_req_vld)    upstream_ack_en <= 1'b1;
    else                                        upstream_ack_en <= 1'b0;
end

assign upstream_ack_dat = data_ram_dout;

always_ff @(clk) begin
    if (rw_req_vld) upstream_sb_pld  <= tag_pipe_rsp_pld.sb_pld ;
    else            upstream_sb_pld  <= rw_req_pld.sb_pld       ;   
end

assign evict_data_ram_id = evict_req_id                                           ;
assign evict_data_ram_en = evict_req_pld.rd_last && evict_req_rdy && evict_req_vld; 

always_ff @(clk) begin
    evict_done_id <= evict_req_id      ;
    evict_done_en <= evict_data_ram_en ;
end

//==================================================================
//===================downstream adapter
//==================================================================
always_ff@(posedge clk or negedge rst_n) begin
    if      (!rst_n)                                                      downstream_evict_vld <= 1'b0;
    else if (downstream_rsp_rdy && (downstream_rsp_vld || evict_req_vld)) downstream_evict_vld <= 1'b1;
end

always_ff@(posedge clk) begin
    downstream_evict_pld.tag      <= evict_req_pld.tag    ;
    downstream_evict_pld.index    <= evict_req_pld.index  ;
    downstream_evict_pld.offset   <= evict_req_pld.offset ;
    downstream_evict_pld.rd_last  <= evict_req_pld.rd_last;
    downstream_evict_pld.evict_id<= evict_req_id          ;
end

assign downstream_evict_pld.wr_data = data_ram_dout;

endmodule