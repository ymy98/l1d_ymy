import l1d_package::*;

interface L1D_upstream_if(input clk,input rst_n);
    logic                                            upstream_req_vld        ;
    logic                                            upstream_req_rdy        ;
    pack_l1d_tag_req                                 upstream_req_pld        ;
    logic [MASK_ADDR_WIDTH-1:0]                      upstream_req_addr_mask  ;
    logic                                            cancel_last_trans       ;
    logic                                            clear_mshr_rd           ;                            
    logic                                            upstream_tag_hit        ;
    logic                                            upstream_ack_en         ;
    logic [REQ_DATA_WIDTH-1:0]                       upstream_ack_dat        ;
    sb_payld                                         upstream_sb_pld         ;
endinterface

interface L1D_downstream_if(input clk,input rst_n);
    logic                                            downstream_req_rdy      ;
    logic                                            downstream_req_vld      ;
    pack_l1d_mshr_downstream_req_pld                 downstream_req_pld      ;
    logic [L1D_MSHR_ID_WIDTH-1:0]                    downstream_req_id       ;        
    logic                                            downstream_rsp_vld      ;
    logic                                            downstream_rsp_rdy      ;
    pack_l1d_data_pipe_downstream_rsp                downstream_rsp_pld      ;
    logic [L1D_MSHR_ID_WIDTH-1:0]                    downstream_rsp_id       ;
    logic                                            downstream_evict_vld    ;
    pack_l1d_data_ram_evict_req                      downstream_evict_pld    ;  
    logic                                            downstream_evict_rdy    ;
endinterface

