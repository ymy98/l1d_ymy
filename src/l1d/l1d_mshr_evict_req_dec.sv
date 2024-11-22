module mshr_evict_req_dec
    import l1d_package::*;
(
    input  logic                        clk                    ,
    input  logic                        rst_n                  ,
    input  logic                        evict_req_vld_mshr     ,
    input  logic                        evict_req_rdy          ,
    output logic                        evict_req_vld          ,    
    output logic                        evict_req_rdy_mshr     ,
    input  logic                        downstream_evict_rdy   ,
    input  pack_l1d_mshr_evict_req_pld  evict_req_pld_mshr     ,
    output pack_l1d_mshr_evict_req_pld  evict_req_pld          
    // input  [L1D_OFFSET_WIDTH-1:0]    evict_offset_in        , 
    // output [L1D_OFFSET_WIDTH-1:0]    evict_offset_out       ,
    // output logic                     evict_rd_last          
);
pack_l1d_mshr_evict_req_pld          evict_req_pld_buf      ;
logic [L1D_OFFSET_WIDTH-1:0]         evict_offset_reg       ;
logic [L1D_OFFSET_WIDTH-1:0]         evict_offset_en        ;
logic                                evict_offset_full      ;
logic                                evict_req_hsk          ;

assign evict_offset_full = evict_offset_reg == {L1D_OFFSET_WIDTH{1'b1}}       ;
assign evict_req_hsk     = evict_req_vld_mshr && evict_req_rdy_mshr           ;

always_ff@(posedge clk or negedge rst_n) begin
    if     (rst_n)                    evict_offset_en <= 1'b0                 ;
    else if(evict_req_hsk)            evict_offset_en <= 1'b1                 ;
    else if(evict_offset_full)        evict_offset_en <= 1'b0                 ;
end

always_ff@(posedge clk) begin
    if     (evict_req_hsk)            evict_offset_reg <= evict_req_pld_mshr.offset + {{(L1D_OFFSET_WIDTH-1){1'b0}},1'b1};
    else                              evict_offset_reg <= evict_offset_reg          + {{(L1D_OFFSET_WIDTH-1){1'b0}},1'b1};   
end

always_ff@(posedge clk) begin
    evict_req_pld_buf <= evict_req_pld_mshr;
end

assign evict_req_vld              = (evict_req_vld_mshr || evict_offset_en) && downstream_evict_rdy ;
assign evict_req_rdy_mshr         = evict_req_rdy && !evict_offset_en       && downstream_evict_rdy ;

always_comb begin
    if(evict_offset_en)begin
        evict_req_pld.tag     = evict_req_pld_buf.tag    ;
        evict_req_pld.way     = evict_req_pld_buf.way    ;
        evict_req_pld.index   = evict_req_pld_buf.index  ;
        evict_req_pld.offset  = evict_offset_reg         ;
        evict_req_pld.rd_last = evict_offset_en          ;
    end 
    else begin
        evict_req_pld.tag     = evict_req_pld_buf.tag    ;
        evict_req_pld.way     = evict_req_pld_buf.way    ;
        evict_req_pld.index   = evict_req_pld_buf.index  ;
        evict_req_pld.offset  = evict_req_pld_buf.offset ;
        evict_req_pld.rd_last = evict_req_pld_buf.rd_last;
    end 
end

endmodule