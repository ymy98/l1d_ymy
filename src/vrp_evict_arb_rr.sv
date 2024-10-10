module vrp_evict_arb_rr 
    import l1d_package::*;
(
    input  logic                           clk                              ,
    input  logic                           rst_n                            ,
    input  logic [L1D_MSHR_ENTRY_NUM-1:0]  v_in_vld                         ,
    output logic [L1D_MSHR_ENTRY_NUM-1:0]  v_in_rdy                         ,
    input  pack_data_ram_req_pld           v_in_pld [L1D_MSHR_ID_WIDTH-1:0] ,
    output logic                           out_vld                          ,
    input  logic                           out_rdy                          ,
    output pack_evict_req_pld              out_pld                                          
);

logic [L1D_MSHR_ID_WIDTH-1:0] free_idx;

vrp_arb_rr#(
    .BIN_WIDTH (L1D_MSHR_ID_WIDTH )
)u_vrp_arb_rr(
    .clk       (clk     ),
    .rst_n     (rst_n   ),
    .v_in_vld  (v_in_vld),
    .v_in_rdy  (v_in_rdy),
    .out_vld   (out_vld ),
    .out_rdy   (out_rdy ),
    .out_idx   (free_idx)
);

always_comb begin
    out_pld.rw_type           = v_in_pld[free_idx].rw_type          ;
    out_pld.index             = v_in_pld[free_idx].index            ;
    out_pld.offset            = v_in_pld[free_idx].offset           ;
    out_pld.way               = v_in_pld[free_idx].way              ;
    out_pld.wr_data           = v_in_pld[free_idx].wr_data          ;
    out_pld.wr_data_byte_en   = v_in_pld[free_idx].wr_data_byte_en  ;
    out_pld.wr_sb_pld         = v_in_pld[free_idx].wr_sb_pld        ;
    out_pld.mshr_id           = free_idx                            ;
end

endmodule