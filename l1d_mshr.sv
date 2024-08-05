module l1d_mshr 
    import l1d_package::*;
(
    input                           clk                             ,
    input                           rst_n                           ,

    output                          alloc_vld                       ,
    input                           alloc_rdy                       ,
    output                          alloc_index                     ,

    output [L1D_INDEX_WIDTH-1:0]    v_hzd_index     [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output [L1D_TAG_WIDTH-1:0]      v_hzd_evict_tag [L1D_MSHR_ENTRY_NUM-1:0]    ,
    output [L1D_MSHR_ENTRY_NUM-1:0] v_hzd_en                                    ,

    input                           mshr_state_update_en            ,
    input pack_l1d_mshr_state       mshr_state_update_pld           ,

    output                          dat_ram_req_vld                 ,
    input                           dat_ram_req_rdy                 ,
    output                          dat_ram_req_pld                 ,

    output                          downstream_req_vld              ,
    input                           downstream_req_rdy              ,
    output                          downstream_req_pld              ,

    input                           evict_dat_ram_clean_en          ,
    input                           evcit_dat_ram_clean_id          ,

    input                           evict_done_en                   ,
    input                           evict_done_id                   ,

    input                           linefill_done_en                ,
    input                           linefill_done_id            
);

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_linefill_done_en          ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_evict_dat_ram_clean_en    ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_evict_done_en             ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_dat_ram_req_vld           ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_dat_ram_req_rdy           ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_dat_ram_req_pld           ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_downstream_req_vld        ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_downstream_req_rdy        ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_downstream_req_pld        ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_release_en                ;

    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_alloc_vld                 ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  v_alloc_rdy                 ;


    // MSHR entries

    generate for(genvar i=0;i <= L1D_MSHR_ENTRY_NUM;i=i+1) begin
        l1d_mshr_entry u_entry(
            .clk                         (clk                            ),
            .rst_n                       (rst_n                          ),

            .alloc_vld                   (v_alloc_vld[i]                 ),
            .alloc_rdy                   (v_alloc_rdy[i]                 ),

            .hzd_index                   (v_hzd_index[i]                 ),
            .hzd_evict_tag               (v_hzd_evict_tag[i]             ),
            .hzd_en                      (v_hzd_en[i]                    ),

            .v_release_en_in             (v_release_en                   ),
            .mshr_state_update_en        (v_mshr_state_update_en[i]      ),
            .mshr_state_update_pld       (mshr_state_update_pld          ),

            .dat_ram_req_vld             (v_dat_ram_req_vld[i]           ),
            .dat_ram_req_rdy             (v_dat_ram_req_rdy[i]           ),
            .dat_ram_req_pld             (v_dat_ram_req_pld[i]           ),

            .downstream_req_vld          (v_downstream_req_vld[i]        ),
            .downstream_req_rdy          (v_downstream_req_rdy[i]        ),
            .downstream_req_pld          (v_downstream_req_pld[i]        ),

            .evict_dat_ram_clean_en      (v_evict_dat_ram_clean_en[i]    ),
            .evict_done_en               (v_evict_done_en[i]             ),
            .linefill_done_en            (v_linefill_done_en[i]          ),
            .release_en                  (v_release_en[i]                )
        );
    end endgenerate



    pre_allocator #(
        .WIDTH(L1D_MSHR_ENTRY_NUM))
    u_pre_allocator (
        .v_in_vld   (v_alloc_vld    ),
        .v_in_rdy   (v_alloc_rdy    ),
        .out_vld    (alloc_vld      ),
        .out_rdy    (alloc_rdy      ),
        .out_index  (alloc_index    ));

    // Arbiter and decoder
    en_decoder #(
        .WIDTH(L1D_MSHR_ENTRY_NUM)) 
    u_active_dec (
        .in_en      (mshr_state_update_en               ),
        .in_index   (mshr_state_update_pld.mshr_id      ),
        .v_out_en   (v_mshr_state_update_en             ));

    vrp_arb_rr #(
        .WIDTH(L1D_MSHR_ENTRY_NUM)) 
    u_datram_req_arb (
        .v_in_vld   (v_dat_ram_req_vld                  ),
        .v_in_rdy   (v_dat_ram_req_rdy                  ),
        .v_in_pld   (v_dat_ram_req_pld                  ),
        .out_vld    (dat_ram_req_vld                    ),
        .out_rdy    (dat_ram_req_rdy                    ),
        .out_pld    (dat_ram_req_pld                    ));

    vrp_arb_rr #(
        .WIDTH(L1D_MSHR_ENTRY_NUM)) 
    u_downstream_req_arb (
        .v_in_vld   (v_downstream_req_vld               ),
        .v_in_rdy   (v_downstream_req_rdy               ),
        .v_in_pld   (v_downstream_req_pld               ),
        .out_vld    (downstream_req_vld                 ),
        .out_rdy    (downstream_req_rdy                 ),
        .out_pld    (downstream_req_pld                 ));

    en_decoder #(
        .WIDTH(L1D_MSHR_ENTRY_NUM)) 
    u_lf_done_dec (
        .in_en      (linefill_done_en                   ),
        .in_index   (linefill_done_id                   ),
        .v_out_en   (v_linefill_done_en                 ));

    en_decoder #(
        .WIDTH(L1D_MSHR_ENTRY_NUM)) 
    u_evict_done_dec (
        .in_en      (evict_done_en                      ),
        .in_index   (evict_done_id                      ),
        .v_out_en   (v_evict_done_en                    ));

    en_decoder #(
        .WIDTH(L1D_MSHR_ENTRY_NUM)) 
    u_evict_dat_ram_clean_dec (
        .in_en      (evict_dat_ram_clean_en             ),
        .in_index   (evict_dat_ram_clean_id             ),
        .v_out_en   (v_evict_dat_ram_clean_en           ));



endmodule