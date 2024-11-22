module l1d_mshr
    import l1d_package::*;
(   
    input  logic                            clk                                         ,
    input  logic                            rst_n                                       ,
    //tag pipe io
    output logic                            mshr_alloc_vld                              ,
    input  logic                            mshr_alloc_rdy                              ,
    output logic [L1D_MSHR_ID_WIDTH-1:0]    mshr_alloc_id                               ,
    output logic [L1D_INDEX_WIDTH-1:0]      v_hzd_index     [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output logic [L1D_WAY_NUM-1:0]          v_hzd_way       [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output logic [L1D_TAG_WIDTH-1:0]        v_hzd_evict_tag [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output logic [L1D_MSHR_ENTRY_NUM-1:0]   v_hzd_index_way_en                          ,
    output logic [L1D_MSHR_ENTRY_NUM-1:0]   v_hzd_evict_tag_en                          ,
    //update mshr signals from tag pipe
    input  logic                            mshr_state_update_en                        ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]    mshr_state_update_id                        ,
    input  pack_l1d_tag_rsp                 mshr_state_update_pld                       ,
    input  logic                            mshr_state_update_hzd_pass                  ,
    input  logic [L1D_MSHR_ENTRY_NUM-1:0]   mshr_hzd_index_way_line                     ,
    input  logic [L1D_MSHR_ENTRY_NUM-1:0]   mshr_hzd_evict_tag_line                     ,

    //data pipe io 
    input  logic                            rw_req_rdy                                  ,
    output logic                            rw_req_vld                                  ,
    output pack_l1d_mshr_rw_req_pld         rw_req_pld                                  ,

    input  logic                            evict_req_rdy                               ,
    output logic                            evict_req_vld                               ,
    output pack_l1d_mshr_evict_req_pld      evict_req_pld                               ,   
    output logic [L1D_MSHR_ID_WIDTH-1:0]    evict_req_id                                ,
    //downstream pipe io
    input  logic                            downstream_req_rdy                          ,
    output logic                            downstream_req_vld                          ,
    output pack_l1d_mshr_downstream_req_pld downstream_req_pld                          ,
    output logic [L1D_MSHR_ID_WIDTH-1:0]    downstream_req_id                           ,      
    input  logic                            downstream_evict_rdy                        ,
    //mshr actions done io
    input  logic                            evict_dat_ram_clean_en                      ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]    evict_dat_ram_clean_id                      ,
               
    input  logic                            evict_done_en                               ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]    evict_done_id                               ,
               
    input  logic                            linefill_done_en                            ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]    linefill_done_id                            ,
    //clean mshr rd: 
    //if lsu request to clean mshr rd, will only clean read option in every entry, evict and line fill will keep running
    input  logic                            clear_mshr_rd                               
);

    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_linefill_done_en                                  ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_evict_dat_ram_clean_en                            ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_evict_done_en                                     ;
                            
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_rd_req_vld                                        ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_rd_req_rdy                                        ;
    
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_evict_req_vld                                     ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_evict_req_rdy                                     ;
    
    pack_l1d_mshr_rw_req_pld            v_rw_req_pld          [L1D_MSHR_ENTRY_NUM-1:0]      ;
    pack_l1d_mshr_evict_req_pld         v_evict_req_pld       [L1D_MSHR_ENTRY_NUM-1:0]      ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_downstream_req_vld                                ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_downstream_req_rdy                                ;
    pack_l1d_mshr_downstream_req_pld    v_downstream_req_pld  [L1D_MSHR_ENTRY_NUM-1:0]      ;
                        
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_release_en_index_way                              ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_release_en_evict_tag                              ;
    
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_mshr_state_update_en                              ;
    
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_alloc_vld                                         ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]      v_alloc_rdy                                         ;

    logic                               evict_req_rdy_mshr;
    logic                               evict_req_vld_mshr;
    pack_l1d_mshr_evict_req_pld         evict_req_pld_mshr;
    
    //--------------------
    //---pre_allocator
    //--------------------
    pre_allocator u_pre_allocator (
        .clk        (clk            ),
        .rst_n      (rst_n          ),
        .v_in_vld   (v_alloc_vld    ),
        .v_in_rdy   (v_alloc_rdy    ),
        .out_vld    (mshr_alloc_vld ),
        .out_rdy    (mshr_alloc_rdy ),
        .out_index  (mshr_alloc_id  ));

    //--------------------
    //---id2entry_decoder
    //--------------------
    v_en_decoder #(
        .BIN_WIDTH(L1D_MSHR_ID_WIDTH)) 
    u_active_dec (
        .in_en      (mshr_state_update_en               ),
        .in_index   (mshr_state_update_id               ),
        .v_out_en   (v_mshr_state_update_en             ));

    v_en_decoder #(
        .BIN_WIDTH(L1D_MSHR_ID_WIDTH)) 
    u_lf_done_dec (
        .in_en      (linefill_done_en                   ),
        .in_index   (linefill_done_id                   ),
        .v_out_en   (v_linefill_done_en                 ));

    v_en_decoder #(
        .BIN_WIDTH(L1D_MSHR_ID_WIDTH)) 
    u_evict_done_dec (
        .in_en      (evict_done_en                      ),
        .in_index   (evict_done_id                      ),
        .v_out_en   (v_evict_done_en                    ));

    v_en_decoder #(
        .BIN_WIDTH(L1D_MSHR_ID_WIDTH)) 
    u_evict_dat_ram_clean_dec (
        .in_en      (evict_dat_ram_clean_en             ),
        .in_index   (evict_dat_ram_clean_id             ),
        .v_out_en   (v_evict_dat_ram_clean_en           ));

    //--------------------
    //---mshr entry
    //--------------------
    generate for(genvar i=0;i < L1D_MSHR_ENTRY_NUM;i=i+1) begin
        l1d_mshr_entry u_entry(
            .clk                         (clk                            ),
            .rst_n                       (rst_n                          ),

            .alloc_vld                   (v_alloc_vld[i]                 ),
            .alloc_rdy                   (v_alloc_rdy[i]                 ),

            .hzd_index                   (v_hzd_index[i]                 ),
            .hzd_way                     (v_hzd_way[i]                   ),
            .hzd_evict_tag               (v_hzd_evict_tag[i]             ),
            .hzd_index_way_en            (v_hzd_index_way_en[i]          ),
            .hzd_evict_tag_en            (v_hzd_evict_tag_en[i]          ),          

            .mshr_state_update_en        (v_mshr_state_update_en[i]      ),
            .mshr_state_bypass           (mshr_state_update_hzd_pass     ),
            .mshr_state_update_pld       (mshr_state_update_pld          ),
            .mshr_state_hzd_index_way    (mshr_hzd_index_way_line        ),
            .mshr_state_hzd_evict_tag    (mshr_hzd_evict_tag_line        ),
  
            .rw_req_vld                  (v_rd_req_vld[i]                ),
            .rw_req_rdy                  (v_rd_req_rdy[i]                ),

            .evict_req_vld               (v_evict_req_vld[i]             ),
            .evict_req_rdy               (v_evict_req_rdy[i]             ),

            .rw_req_pld                  (v_rw_req_pld[i]                ),
            .evict_req_pld               (v_evict_req_pld[i]             ),

            .downstream_req_vld          (v_downstream_req_vld[i]        ),
            .downstream_req_rdy          (v_downstream_req_rdy[i]        ),
            .downstream_req_pld          (v_downstream_req_pld[i]        ),

            .evict_dat_ram_clean_en      (v_evict_dat_ram_clean_en[i]    ),
            .evict_done_en               (v_evict_done_en[i]             ),
            .linefill_done_en            (v_linefill_done_en[i]          ),

            .v_release_en_index_way_in   (v_release_en_index_way         ),
            .v_release_en_evict_tag_in   (v_release_en_evict_tag         ),
            .release_index_way_en        (v_release_en_index_way[i]      ),
            .release_evict_tag_en        (v_release_en_evict_tag[i]      ),
            .clear_mshr_rd               (clear_mshr_rd                  )
        );
    end endgenerate
    
    //--------------------------------------------------
    //---arbiter from entry to data ram and to downstream
    //--------------------------------------------------
    vrp_arb_rr #(
        .pack_pld (pack_l1d_mshr_rw_req_pld),
        .BIN_WIDTH(L1D_MSHR_ID_WIDTH       )
    )u_vrp_rw_apb_rr(
        .clk       (clk         ),
        .rst_n     (rst_n       ),
        .v_in_vld  (v_rd_req_vld),
        .v_in_rdy  (v_rd_req_rdy),
        .v_in_pld  (v_rw_req_pld),
        .out_vld   (rw_req_vld  ),
        .out_rdy   (rw_req_rdy  ),
        .out_pld   (rw_req_pld  ),
        .out_idx   ()        
    );

    vrp_arb_rr #(
        .pack_pld (pack_l1d_mshr_evict_req_pld),
        .BIN_WIDTH(L1D_MSHR_ID_WIDTH          )
    )u_vrp_evict_apb_rr(
        .clk       (clk                 ),
        .rst_n     (rst_n               ),
        .v_in_vld  (v_evict_req_vld     ),
        .v_in_rdy  (v_evict_req_rdy     ),
        .v_in_pld  (v_evict_req_pld     ),
        .out_vld   (evict_req_vld_mshr  ),
        .out_rdy   (evict_req_rdy_mshr  ),
        .out_pld   (evict_req_pld_mshr  ),
        .out_idx   (evict_req_id        )        
    );

    //worst timing path:can add pipe here
    mshr_evict_req_dec u_mshr_evict_req_dec(
    .clk                    (clk                      ),
    .rst_n                  (rst_n                    ),
    .evict_req_vld_mshr     (evict_req_vld_mshr       ),
    .evict_req_vld          (evict_req_vld            ),
    .evict_req_rdy          (evict_req_rdy            ),
    .evict_req_rdy_mshr     (evict_req_rdy_mshr       ),
    .evict_req_pld_mshr     (evict_req_pld_mshr       ),
    .downstream_evict_rdy   (downstream_evict_rdy     ),
    .evict_req_pld          (evict_req_pld            )
    );
    


    vrp_arb_rr #(
        .pack_pld (pack_l1d_mshr_downstream_req_pld),
        .BIN_WIDTH(L1D_MSHR_ID_WIDTH           )
    )u_vrp_downstream_apb_rr(
        .clk       (clk                 ),
        .rst_n     (rst_n               ),
        .v_in_vld  (v_downstream_req_vld),
        .v_in_rdy  (v_downstream_req_rdy),
        .v_in_pld  (v_downstream_req_pld),
        .out_vld   (downstream_req_vld  ),
        .out_rdy   (downstream_req_rdy  ),
        .out_pld   (downstream_req_pld  ),
        .out_idx   (downstream_req_id   )        
    );

endmodule
