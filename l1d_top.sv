
module l1d_top 
    import l1d_package::*;
(
    input                           clk                 ,
    input                           rst_n               ,
    // input from upstream
    input                           upstream_req_vld    ,
    output                          upstream_req_rdy    ,
    input  pack_l1d_req             upstream_req_pld    ,

    output                          upstream_ack_en                 ,
    output                          upstream_ack_id                 ,
    output                          upstream_ack_data               ,

    output                          axi_arvalid                     ,
    input                           axi_arready                     ,
    output                          axi_araddr                      ,
    output [L1D_MSHR_ID_WIDTH-1:0]  axi_arid                        ,
    output                          axi_arsize                      ,
    output                          axi_arlen                       ,

    input                           axi_bvalid                      ,
    output                          axi_bready                      ,
    input  [L1D_MSHR_ID_WIDTH-1:0]  axi_bid                         ,
    input  [1:0]                    axi_bresp                       ,

    input                           axi_rvalid      ,
    output                          axi_rready      ,
    input                           axi_rdata       ,
    input                           axi_rid         ,

    output                          axi_awvalid     ,
    input                           axi_awready     ,
    output                          axi_awid        ,
    output                          axi_awburst     ,
    output                          axi_awsize      ,
    output                          axi_awlen       ,

    output                          axi_wvalid      ,
    input                           axi_wready      ,
    output                          axi_wdata       


);

    logic                          alloc_vld                                ;
    logic                          alloc_rdy                                ;
    logic [L1D_MSHR_ID_WIDTH-1:0]  alloc_index                              ;

    logic                          prefetch_vld                             ;
    logic                          prefetch_rdy                             ;
    pack_l1d_req                   prefetch_pld                             ;

    logic [L1D_INDEX_WIDTH-1:0]    v_hzd_index     [L1D_MSHR_ENTRY_NUM-1:0] ;
    logic [L1D_TAG_WIDTH-1:0]      v_hzd_evict_tag [L1D_MSHR_ENTRY_NUM-1:0] ;
    logic [L1D_MSHR_ENTRY_NUM-1:0] v_hzd_en                                 ;


    logic                          tag_pipe_req_vld                         ;
    logic                          tag_pipe_req_rdy                         ;
    pack_l1d_req                   tag_pipe_req_pld                         ;
    logic  [L1D_MSHR_ID_WIDTH-1:0] tag_pipe_req_index                       ;

    logic                          mshr_state_update_en                     ;
    pack_l1d_mshr_state            mshr_state_update_pld                    ;

    logic                          downstream_req_vld                       ;
    logic                          downstream_req_rdy                       ;
    logic                          downstream_req_pld                       ;

    logic                          evict_done_en                            ;
    logic [L1D_MSHR_ID_WIDTH-1:0]  evict_done_id                            ;

    logic                          dat_ram_req_vld                          ;
    logic                          dat_ram_req_rdy                          ;
    logic                          dat_ram_req_pld                          ;

    logic                          evict_dat_ram_clean_en                   ;
    logic                          evcit_dat_ram_clean_id                   ;
    logic                          linefill_done_en                         ;
    logic                          linefill_done_id                         ;


    l1d_req_arbiter u_req_arb (
        .clk                            (clk                ),
        .rst_n                          (rst_n              ),
        // input from upstream
        .upstream_req_vld               (upstream_req_vld   ),
        .upstream_req_rdy               (upstream_req_rdy   ),
        .upstream_req_pld               (upstream_req_pld   ),
        // input from prefetch engine
        .prefetch_vld                   (prefetch_vld       ),
        .prefetch_rdy                   (prefetch_rdy       ),
        .prefetch_pld                   (prefetch_pld       ),
        // output to tag pipeline
        .tag_pipe_req_vld               (tag_pipe_req_vld   ),
        .tag_pipe_req_rdy               (tag_pipe_req_rdy   ),
        .tag_pipe_req_pld               (tag_pipe_req_pld   ),
        .tag_pipe_req_index             (tag_pipe_req_index ),
        // credit from mshr
        .alloc_vld                      (alloc_vld          ),
        .alloc_rdy                      (alloc_rdy          ),
        .alloc_index                    (alloc_index        ));


    l1d_prefetch u_prefetch (
        .prefetch_vld   (prefetch_vld       ),
        .prefetch_rdy   (prefetch_rdy       ),
        .prefetch_pld   (prefetch_pld       )
    );

    l1d_mshr u_mshr(
        .clk                            (clk                    ),
        .rst_n                          (rst_n                  ),
        .alloc_vld                      (alloc_vld              ),
        .alloc_rdy                      (alloc_rdy              ),
        .alloc_index                    (alloc_index            ),
        .v_hzd_index                    (v_hzd_index            ),
        .v_hzd_evict_tag                (v_hzd_evict_tag        ),
        .v_hzd_en                       (v_hzd_en               ),
        .mshr_state_update_en           (mshr_state_update_en   ),
        .mshr_state_update_pld          (mshr_state_update_pld  ),
        .dat_ram_req_vld                (dat_ram_req_vld        ),
        .dat_ram_req_rdy                (dat_ram_req_rdy        ),
        .dat_ram_req_pld                (dat_ram_req_pld        ),
        .downstream_req_vld             (downstream_req_vld     ),
        .downstream_req_rdy             (downstream_req_rdy     ),
        .downstream_req_pld             (downstream_req_pld     ),
        .evict_dat_ram_clean_en         (evict_dat_ram_clean_en ),
        .evcit_dat_ram_clean_id         (evcit_dat_ram_clean_id ),
        .evict_done_en                  (evict_done_en          ),
        .evict_done_id                  (evict_done_id          ),
        .linefill_done_en               (linefill_done_en       ),
        .linefill_done_id               (linefill_done_id       ));

    l1d_tag_pipe u_tag (
        .clk                      (clk                  ),
        .rst_n                    (rst_n                ),
        .tag_pipe_req_vld         (tag_pipe_req_vld     ),
        .tag_pipe_req_rdy         (tag_pipe_req_rdy     ),
        .tag_pipe_req_pld         (tag_pipe_req_pld     ),
        .tag_pipe_req_index       (tag_pipe_req_index   ),
        .v_hzd_index              (v_hzd_index          ),
        .v_hzd_evict_tag          (v_hzd_evict_tag      ),
        .v_hzd_en                 (v_hzd_en             ),
        .mshr_state_update_en     (mshr_state_update_en ),
        .mshr_state_update_pld    (mshr_state_update_pld)
        // sram interface
        );


    l1d_data_pipe u_data(
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .dat_ram_req_vld            ( dat_ram_req_vld           ),
        .dat_ram_req_rdy            ( dat_ram_req_rdy           ),
        .dat_ram_req_pld            ( dat_ram_req_pld           ),
        .evict_dat_ram_clean_en     (evict_dat_ram_clean_en     ),
        .evcit_dat_ram_clean_id     (evcit_dat_ram_clean_id     ),
        .linefill_done_en           (linefill_done_en           ),
        .linefill_done_id           (linefill_done_id           ),  
        .upstream_ack_en            (upstream_ack_en            ),
        .upstream_ack_id            (upstream_ack_id            ),
        .upstream_ack_data          (upstream_ack_data          ),
        .axi_rvalid                 (axi_rvalid                 ),
        .axi_rready                 (axi_rready                 ),
        .axi_rdata                  (axi_rdata                  ),
        .axi_rid                    (axi_rid                    ),
        .axi_awvalid                (axi_awvalid                ),
        .axi_awready                (axi_awready                ),
        .axi_awid                   (axi_awid                   ),
        .axi_awburst                (axi_awburst                ),
        .axi_awsize                 (axi_awsize                 ),
        .axi_awlen                  (axi_awlen                  ),
        .axi_wvalid                 (axi_wvalid                 ),
        .axi_wready                 (axi_wready                 ),
        .axi_wdata                  (axi_wdata                  ));



    l1d_axi_adapter u_axi (
        .downstream_req_vld     (downstream_req_vld ),
        .downstream_req_rdy     (downstream_req_rdy ),
        .downstream_req_pld     (downstream_req_pld ),
        .axi_arvalid            (axi_arvalid        ),
        .axi_arready            (axi_arready        ),
        .axi_araddr             (axi_araddr         ),
        .axi_arid               (axi_arid           ),
        .axi_arsize             (axi_arsize         ),
        .axi_arlen              (axi_arlen          ),
        .evict_done_en          (evict_done_en      ),
        .evict_done_id          (evict_done_id      ),
        .axi_bvalid             (axi_bvalid         ),
        .axi_bready             (axi_bready         ),
        .axi_bid                (axi_bid            ),
        .axi_bresp              (axi_bresp          ));



endmodule