module l1d_tag_pipe 
    import l1d_package::*;
(
    input                           clk                                         ,
    input                           rst_n                                       ,

    input                           tag_pipe_req_vld                            ,
    output                          tag_pipe_req_rdy                            ,
    input  pack_l1d_req             tag_pipe_req_pld                            ,
    input  [L1D_MSHR_ID_WIDTH-1:0]  tag_pipe_req_index                          ,

    output [L1D_INDEX_WIDTH-1:0]    v_hzd_index     [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output [L1D_TAG_WIDTH-1:0]      v_hzd_evict_tag [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output [L1D_MSHR_ENTRY_NUM-1:0] v_hzd_en                                    ,

    output                          mshr_state_update_en                        ,
    output pack_l1d_mshr_state      mshr_state_update_pld       

    // sram interface
);


    // tag check 


    // hazard check


    // behavior map



endmodule