module l1d_mshr 
    import l1d_package::*;
(
    input  logic                         clk                                         ,
    input  logic                         rst_n                                       ,
    //tag pipe
    output logic                         alloc_vld                                   ,
    input  logic                         alloc_rdy                                   ,
    output logic                         alloc_index                                 ,

    output logic[L1D_INDEX_WIDTH-1:0]    v_hzd_index     [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output logic[L1D_WAY_NUM_WIDTH-1:0]  v_hzd_way       [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output logic[L1D_TAG_WIDTH-1:0]      v_hzd_evict_tag [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output logic[L1D_MSHR_ENTRY_NUM-1:0] v_hzd_index_way_en                          ,
    output logic[L1D_MSHR_ENTRY_NUM-1:0] v_hzd_evict_tag_en                          ,

    input  logic                         mshr_state_update_en                        ,
    input  logic                         mshr_state_update_hz_pass                   ,        
    input  pack_l1d_mshr_state           mshr_state_update_pld                       ,
    //data pipe
    output logic                         dat_ram_req_vld                             ,
    input  logic                         dat_ram_req_rdy                             ,
    output pack_data_ram_req_pld         dat_ram_req_pld                             ,
    
    output logic                         evict_req_vld                               ,
    input  logic                         evict_req_rdy                               ,
    output pack_evict_req_pld            evict_req_pld                               ,

    output pack_mshr_dat_addr            mshr_data_addr[L1D_MSHR_ENTRY_NUM-1:0]      ,

    //chi req 
    output logic                         downstream_req_flitpend                     ,
    output logic                         downstream_req_flitv                        ,                   
    output pack_rsp_flit                 downstream_req_flit                         ,
    input  logic                         downstream_req_lcrdv                        ,                          
    //data pipe done
    input  logic                         evict_dat_ram_clean_en                      ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0] evict_dat_ram_clean_id                      ,
            
    input  logic                         evict_done_en                               ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0] evict_done_id                               ,
            
    input  logic                         linefill_done_en                            ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0] linefill_done_id                        
);

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_linefill_done_en                                  ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_evict_dat_ram_clean_en                            ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_evict_done_en                                     ;
                        
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_dat_ram_req_vld                                   ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_dat_ram_req_rdy                                   ;
    pack_data_ram_req_pld           v_dat_ram_req_pld    [L1D_MSHR_ENTRY_NUM-1:0]       ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_evict_req_vld                                     ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_evict_req_rdy                                     ;
    pack_evict_req_pld              v_evict_req_pld      [L1D_MSHR_ENTRY_NUM-1:0]       ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_downstream_req_vld                                ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_downstream_req_rdy                                ;
    pack_downstream_req_pld         v_downstream_req_pld [L1D_MSHR_ENTRY_NUM-1:0]       ;
                        
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_release_en_index_way                              ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_release_en_evict_tag                              ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_mshr_state_update_en                              ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_alloc_vld                                         ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_alloc_rdy                                         ;

    logic                           ety_data_ram_req_vld                                ;
    pack_data_ram_req_pld           ety_data_ram_req_pld                                ;
    logic                           bps_data_ram_req_vld                                ;
    pack_data_ram_req_pld           bps_data_ram_req_pld                                ;
    
    // MSHR entries

    generate for(genvar i=0;i <= L1D_MSHR_ENTRY_NUM;i=i+1) begin
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
            
            .v_release_en_index_way_in   (v_release_en_index_way         ),
            .v_release_en_evict_tag_in   (v_release_en_evict_tag         ),
            .mshr_state_bypass           (bps_data_ram_req_vld           ),
            .mshr_state_update_en        (v_mshr_state_update_en[i]      ),
            .mshr_state_update_pld       (mshr_state_update_pld          ),

            .dat_ram_req_vld             (v_dat_ram_req_vld[i]           ),
            .dat_ram_req_rdy             (v_dat_ram_req_rdy[i]           ),
            .dat_ram_req_pld             (v_dat_ram_req_pld[i]           ),

            .evict_req_vld               (v_evict_req_vld[i]             ),
            .evict_req_rdy               (v_evict_req_rdy[i]             ),
            .evict_req_pld               (v_evict_req_pld[i]             ),

            .downstream_req_vld          (v_downstream_req_vld[i]        ),
            .downstream_req_rdy          (v_downstream_req_rdy[i]        ),
            .downstream_req_pld          (v_downstream_req_pld[i]        ),

            .evict_dat_ram_clean_en      (v_evict_dat_ram_clean_en[i]    ),
            .evict_done_en               (v_evict_done_en[i]             ),
            .linefill_done_en            (v_linefill_done_en[i]          ),
            .release_index_way_en        (v_release_en_index_way[i]      ),
            .release_evict_tag_en        (v_release_en_evict_tag[i]      ),
            .v_mshr_data_addr            (mshr_data_addr[i]              )
        );
    end endgenerate

    pre_allocator u_pre_allocator (
        .clk        (clk            ),
        .rst_n      (rst_n          ),
        .v_in_vld   (v_alloc_vld    ),
        .v_in_rdy   (v_alloc_rdy    ),
        .out_vld    (alloc_vld      ),
        .out_rdy    (alloc_rdy      ),
        .out_index  (alloc_index    ));

    // decoder
    v_en_decoder #(
        .BIN_WIDTH(L1D_MSHR_ID_WIDTH)) 
    u_active_dec (
        .in_en      (mshr_state_update_en               ),
        .in_index   (mshr_state_update_pld.mshr_id      ),
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

    //arbiter
    vrp_data_ram_arb_rr  u_vrp_data_ram_arb_rr (
        .clk        (clk                                ),
        .rst_n      (rst_n                              ),
        .v_in_vld   (v_dat_ram_req_vld                  ),
        .v_in_rdy   (v_dat_ram_req_rdy                  ),
        .v_in_pld   (v_dat_ram_req_pld                  ),
        .out_vld    (ety_data_ram_req_vld               ),
        .out_rdy    (dat_ram_req_rdy                    ),
        .out_pld    (ety_data_ram_req_pld               ));

    vrp_evict_arb_rr  u_vrp_evict_arb_rr (
        .clk        (clk                                ),
        .rst_n      (rst_n                              ),
        .v_in_vld   (v_evict_req_vld                    ),
        .v_in_rdy   (v_evict_req_rdy                    ),
        .v_in_pld   (v_evict_req_pld                    ),
        .out_vld    (evict_req_vld                      ),
        .out_rdy    (evict_req_rdy                      ),
        .out_pld    (evict_req_pld                      ));

    vrp_downstream_arb_rr  u_vrp_downstream_arb_rr (
        .clk          (clk                                ),
        .rst_n        (rst_n                              ),
        .v_in_vld     (v_downstream_req_vld               ),
        .v_in_rdy     (v_downstream_req_rdy               ),
        .v_in_pld     (v_downstream_req_pld               ),
        .out_flitpend (downstream_req_flitpend            ),   
        .out_flitv    (downstream_req_flitv               ),   
        .out_flit     (downstream_req_flit                ),   
        .out_lcrdv    (downstream_req_lcrdv               )
    );
    
    //bypass
    l1d_mshr_bps u_l1d_mshr_bps
    (
        .tag_pipe_req_pld(mshr_state_update_pld         ),
        .tag_pipe_req_en (mshr_state_update_en          ),
        .tag_pipe_hz_pass(mshr_state_update_hz_pass     ),
        .data_ram_rdy    (dat_ram_req_rdy               ),
        .mshr_bps_vld    (bps_data_ram_req_vld          ),
        .mshr_bps_pld    (bps_data_ram_req_pld          ));

    //fixed_arbiter
    l1d_mshr_data_ram_arb u_l1d_mshr_data_ram_arb (
        .mshr_bps_pld    (bps_data_ram_req_pld          ),
        .mshr_entry_pld  (ety_data_ram_req_pld          ),
        .mshr_bps_vld    (bps_data_ram_req_vld          ),
        .mshr_entry_vld  (ety_data_ram_req_vld          ),
        .data_ram_pld    (dat_ram_req_pld               ),
        .data_ram_vld    (dat_ram_req_vld               ));
endmodule