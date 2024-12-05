module l1d_top 
    import l1d_package::*;
(
    input  logic                                            clk                                         ,
    input  logic                                            rst_n                                       ,

    //from upstream          
    input  logic                                            upstream_req_vld                            ,
    output logic                                            upstream_req_rdy                            ,
    input  pack_l1d_tag_req                                 upstream_req_pld                            ,
    input  logic                                            cancel_last_trans                           ,
    input  logic                                            clear_mshr_rd                               ,                             

    //to upstream
    output logic                                            upstream_tag_hit                            ,
    output logic                                            upstream_ack_en                             ,
    output logic [REQ_DATA_WIDTH-1:0]                       upstream_ack_dat                            ,
    output sb_payld                                         upstream_sb_pld                             ,

    //to downstream linefill req
    input  logic                                            downstream_req_rdy                          ,
    output logic                                            downstream_req_vld                          ,
    output pack_l1d_mshr_downstream_req_pld                 downstream_req_pld                          ,
    output logic [L1D_MSHR_ID_WIDTH-1:0]                    downstream_req_id                           ,        
    //from downstream linefill rsp 
    input  logic                                            downstream_rsp_vld                          ,
    output logic                                            downstream_rsp_rdy                          ,
    input  pack_l1d_data_pipe_downstream_rsp                downstream_rsp_pld                          ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]                    downstream_rsp_id                           ,
    //to downstream evict req
    output logic                                            downstream_evict_vld                        ,
    output pack_l1d_data_ram_evict_req                      downstream_evict_pld                        ,  
    input  logic                                            downstream_evict_rdy                        
    );

//===========================================
//=======internal signals
//===========================================
logic                                            mshr_prefetch_vld                           ;
logic                                            mshr_prefetch_rdy                           ;
pack_l1d_tag_req                                 mshr_prefetch_pld                           ;
logic                                            mshr_alloc_vld                              ;
logic                                            mshr_alloc_rdy                              ;
logic [L1D_MSHR_ID_WIDTH-1:0]                    mshr_alloc_id                               ;
logic [L1D_INDEX_WIDTH-1:0]                      v_hzd_index       [L1D_MSHR_ENTRY_NUM-1:0]  ;
logic [L1D_WAY_NUM-1:0]                          v_hzd_way         [L1D_MSHR_ENTRY_NUM-1:0]  ;
logic [L1D_TAG_WIDTH-1:0]                        v_hzd_evict_tag   [L1D_MSHR_ENTRY_NUM-1:0]  ;
logic [L1D_MSHR_ENTRY_NUM-1:0]                   v_hzd_index_way_en                          ;
logic [L1D_MSHR_ENTRY_NUM-1:0]                   v_hzd_evict_tag_en                          ;
logic                                            mshr_state_update_en                        ;
logic [L1D_MSHR_ID_WIDTH-1:0]                    mshr_state_update_id                        ;
logic                                            mshr_state_update_hzd_pass                  ;
logic [L1D_MSHR_ENTRY_NUM-1:0]                   mshr_hzd_index_way_line                     ;
logic [L1D_MSHR_ENTRY_NUM-1:0]                   mshr_hzd_evict_tag_line                     ;
pack_l1d_tag_rsp                                 tag_pipe_rsp_pld                            ;
logic                                            tag_pipe_rsp_vld                            ;
logic                                            tag_pipe_rsp_rdy                            ;

logic                                            rw_req_rdy                                  ;
logic                                            rw_req_vld                                  ;
pack_l1d_mshr_rw_req_pld                         rw_req_pld                                  ;
logic                                            evict_req_rdy                               ;
logic                                            evict_req_vld                               ;
pack_l1d_mshr_evict_req_pld                      evict_req_pld                               ;   
logic [L1D_MSHR_ID_WIDTH-1:0]                    evict_req_id                                ;
logic                                            evict_dat_ram_clean_en                      ;
logic [L1D_MSHR_ID_WIDTH-1:0]                    evict_dat_ram_clean_id                      ;        
logic                                            evict_done_en                               ;
logic [L1D_MSHR_ID_WIDTH-1:0]                    evict_done_id                               ;          
logic                                            linefill_done_en                            ;
logic [L1D_MSHR_ID_WIDTH-1:0]                    linefill_done_id                            ;

//===========================================
//=======l1d_tag_pipe
//===========================================
l1d_tag_pipe u_l1d_tag_pipe
(    
    .clk                          (clk                       ),
    .rst_n                        (rst_n                     ),
    .upstream_req_vld             (upstream_req_vld          ),
    .upstream_req_rdy             (upstream_req_rdy          ),
    .upstream_req_pld             (upstream_req_pld          ),
    .cancel_last_trans            (cancel_last_trans         ),
    .upstream_tag_hit             (upstream_tag_hit          ),
    .mshr_prefetch_vld            (mshr_prefetch_vld         ),
    .mshr_prefetch_rdy            (mshr_prefetch_rdy         ),
    .mshr_prefetch_pld            (mshr_prefetch_pld         ),
    .mshr_alloc_vld               (mshr_alloc_vld            ),
    .mshr_alloc_rdy               (mshr_alloc_rdy            ),
    .mshr_alloc_id                (mshr_alloc_id             ),
    .v_hzd_index                  (v_hzd_index               ),
    .v_hzd_way                    (v_hzd_way                 ),
    .v_hzd_evict_tag              (v_hzd_evict_tag           ),
    .v_hzd_index_way_en           (v_hzd_index_way_en        ),
    .v_hzd_evict_tag_en           (v_hzd_evict_tag_en        ),
    .mshr_state_update_en         (mshr_state_update_en      ),
    .mshr_state_update_id         (mshr_state_update_id      ),
    .mshr_state_update_hzd_pass   (mshr_state_update_hzd_pass),
    .mshr_hzd_index_way_line      (mshr_hzd_index_way_line   ),
    .mshr_hzd_evict_tag_line      (mshr_hzd_evict_tag_line   ),
    .tag_pipe_rsp_pld             (tag_pipe_rsp_pld          ),
    .tag_pipe_rsp_vld             (tag_pipe_rsp_vld          ),
    .tag_pipe_rsp_rdy             (tag_pipe_rsp_rdy          )                                                         
);
//===========================================
//=======l1d_mshr
//===========================================
l1d_mshr u_l1d_mshr(   
    .clk                         (clk                         ),
    .rst_n                       (rst_n                       ),
    .mshr_alloc_vld              (mshr_alloc_vld              ),
    .mshr_alloc_rdy              (mshr_alloc_rdy              ),
    .mshr_alloc_id               (mshr_alloc_id               ),
    .v_hzd_index                 (v_hzd_index                 ),
    .v_hzd_way                   (v_hzd_way                   ),
    .v_hzd_evict_tag             (v_hzd_evict_tag             ),
    .v_hzd_index_way_en          (v_hzd_index_way_en          ),
    .v_hzd_evict_tag_en          (v_hzd_evict_tag_en          ),
    .mshr_state_update_en        (mshr_state_update_en        ),
    .mshr_state_update_id        (mshr_state_update_id        ),
    .mshr_state_update_pld       (tag_pipe_rsp_pld            ),
    .mshr_state_update_hzd_pass  (mshr_state_update_hzd_pass  ),
    .mshr_hzd_index_way_line     (mshr_hzd_index_way_line     ),
    .mshr_hzd_evict_tag_line     (mshr_hzd_evict_tag_line     ),
    .rw_req_rdy                  (rw_req_rdy                  ),
    .rw_req_vld                  (rw_req_vld                  ),
    .rw_req_pld                  (rw_req_pld                  ),
    .evict_req_rdy               (evict_req_rdy               ),
    .evict_req_vld               (evict_req_vld               ),
    .evict_req_pld               (evict_req_pld               ),   
    .evict_req_id                (evict_req_id                ),
    .downstream_req_rdy          (downstream_req_rdy          ),
    .downstream_req_vld          (downstream_req_vld          ),
    .downstream_req_pld          (downstream_req_pld          ),
    .downstream_req_id           (downstream_req_id           ),   
    .downstream_evict_rdy        (downstream_evict_rdy        ),
    .evict_dat_ram_clean_en      (evict_dat_ram_clean_en      ),
    .evict_dat_ram_clean_id      (evict_dat_ram_clean_id      ),
    .evict_done_en               (evict_done_en               ),
    .evict_done_id               (evict_done_id               ),
    .linefill_done_en            (linefill_done_en            ),
    .linefill_done_id            (linefill_done_id            ),
    .clear_mshr_rd               (clear_mshr_rd               )
);
//===========================================
//=======l1d_data_pipe
//===========================================
l1d_data_pipe u_l1d_data_pipe
(
   .clk                           (clk                     ),
   .rst_n                         (rst_n                   ),
   .tag_pipe_rsp_pld              (tag_pipe_rsp_pld        ),
   .tag_pipe_rsp_vld              (tag_pipe_rsp_vld        ),
   .tag_pipe_rsp_rdy              (tag_pipe_rsp_rdy        ),
   .downstream_rsp_vld            (downstream_rsp_vld      ),
   .downstream_rsp_rdy            (downstream_rsp_rdy      ),
   .downstream_rsp_pld            (downstream_rsp_pld      ),
   .downstream_rsp_id             (downstream_rsp_id       ),
   .rw_req_rdy                    (rw_req_rdy              ),
   .rw_req_vld                    (rw_req_vld              ),
   .rw_req_pld                    (rw_req_pld              ),
   .evict_req_rdy                 (evict_req_rdy           ), 
   .evict_req_vld                 (evict_req_vld           ),
   .evict_req_pld                 (evict_req_pld           ),
   .evict_req_id                  (evict_req_id            ),
   .upstream_ack_en               (upstream_ack_en         ),
   .upstream_ack_dat              (upstream_ack_dat        ),
   .upstream_sb_pld               (upstream_sb_pld         ),
   .downstream_evict_vld          (downstream_evict_vld    ),
   .downstream_evict_pld          (downstream_evict_pld    ),    
   .linefill_done_id              (linefill_done_id        ),
   .linefill_done_en              (linefill_done_en        ),
   .evict_dat_ram_clean_id        (evict_dat_ram_clean_id  ),
   .evict_dat_ram_clean_en        (evict_dat_ram_clean_en  ),
   .evict_done_id                 (evict_done_id           ),
   .evict_done_en                 (evict_done_en           )                            
);
//pre_fetched engine
assign mshr_prefetch_vld = 1'b0                           ;
assign mshr_prefetch_pld = {$bits(pack_l1d_tag_req){1'b0}};
endmodule 