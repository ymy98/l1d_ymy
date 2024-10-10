module l1d_tag_behavior_map
import l1d_package::*;
(
    input  logic                         tag_hit                              ,
    input  logic                         tag_dirty                            ,
    input  logic                         tag_valid                            ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0] hzd_index_way_line                   ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0] hzd_evict_tag_line                   ,
    input  logic [L1D_WAY_NUM-1:0]       hit_way                              ,
    input  pack_l1d_req                  pld_in                               ,
    input  logic [L1D_TAG_WIDTH-1:0]     evict_tag                            ,
    input  logic [WEIGHT_WIDHT-1:0]      index_weight [L1D_INDEX_WIDTH-1:0]   ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0] mshr_id                              ,
    output pack_l1d_weight_pld           weight_update_pld                    ,
    output pack_l1d_mshr_state           mshr_state_update_pld             
);

//weight to way signals
logic [L1D_WAY_NUM-1:0] weight2way;
always_comb begin
    mshr_state_update_pld.index                           = pld_in.index                   ;
    mshr_state_update_pld.new_tag                         = pld_in.tag                     ;
    mshr_state_update_pld.evict_tag                       = evict_tag                      ;
    mshr_state_update_pld.offset                          = pld_in.offset                  ;
    mshr_state_update_pld.need_rw                         = pld_in.op_is_read              ;
    mshr_state_update_pld.wr_data                         = pld_in.wr_data                 ;
    mshr_state_update_pld.wr_data_byte_en                 = pld_in.wr_data_byte_en         ;
    mshr_state_update_pld.wr_sb_pld                       = pld_in.wr_sb_pld               ;
    mshr_state_update_pld.mshr_hzd_index_way_line         = hzd_index_way_line             ;
    mshr_state_update_pld.mshr_hzd_evict_tag_line         = hzd_evict_tag_line             ;
    mshr_state_update_pld.mshr_id                         = mshr_id                        ;
     
    if(tag_hit) begin     
        mshr_state_update_pld.need_evict                      = 1'b0                       ;
        mshr_state_update_pld.need_linefill                   = 1'b0                       ;
        mshr_state_update_pld.way                             = hit_way                    ;
    end
    else begin 
        mshr_state_update_pld.need_evict                      = tag_valid && tag_dirty     ;
        mshr_state_update_pld.need_linefill                   = 1'b1                       ;
        mshr_state_update_pld.way                             = weight2way                 ;
    end         
end

//weight to mshr_state_update_way
cmn_bin2onehot#(
    .BIN_WIDTH(L1D_WAY_NUM_WIDTH),
    .ONEHOT_WIDTH(L1D_WAY_NUM)
 )u_cmn_bin2onehot(
    .bin_in(index_weight[pld_in.index]),
    .onehot_out(weight2way)
 );

//weight 
always_comb begin
    weight_update_pld.index                                  = pld_in.index                                                ;
    weight_update_pld.new_weight                             = index_weight[pld_in.index] + {{(WEIGHT_WIDHT-1){1'b0}},1'b1};
end

endmodule