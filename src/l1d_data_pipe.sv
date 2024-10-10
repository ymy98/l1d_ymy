module l1d_data_pipe
    import l1d_package::*;
(
    input  logic                         clk                                         ,
    input  logic                         rst_n                                       ,
    //mshr
    input  logic                         dat_ram_req_vld                             ,
    output logic                         dat_ram_req_rdy                             ,
    input  pack_data_ram_req_pld         dat_ram_req_pld                             ,

    input  logic                         evict_req_vld                               , 
    output logic                         evict_req_rdy                               ,
    input  pack_evict_req_pld            evict_req_pld                               ,
    //rx rsp
    input  logic                         rx_rsp_flitpend                             ,
    input  logic                         rx_rsp_flitv                                ,
    input  pack_rsp_flit                 rx_rsp_flit                                 ,
    output logic                         rx_rsp_lcrdv                                ,
    input  logic                         rx_dat_flitpend                             ,
    input  logic                         rx_dat_flitv                                , 
    input  pack_data_flit                rx_dat_flit                                 ,
    output logic                         rx_dat_lcrdv                                ,
    //mshr
    output logic                         evict_dat_ram_clean_en                      ,
    output logic [L1D_MSHR_ID_WIDTH-1:0] evict_dat_ram_clean_id                      ,
  
    output logic                         evict_done_en                               ,
    output logic [L1D_MSHR_ID_WIDTH-1:0] evict_done_id                               ,
  
    output logic                         linefill_done_en                            ,
    output logic [L1D_MSHR_ID_WIDTH-1:0] linefill_done_id                            ,
    input  pack_mshr_dat_addr            mshr_data_addr[L1D_MSHR_ENTRY_NUM-1:0]      ,
    //upstream
    output logic                         upstream_ack_en                             ,
    output logic [REQ_DATA_WIDTH-1:0]    upstream_ack_dat                            ,
    output sb_payld                      upstream_sb_pld                             
);
//--------------------------------
//----------------internal signals
//--------------------------------
    logic                         linefill_dat_vld     ;
    logic                         linefill_dat_rdy     ;
    pack_linefill_dat_pld         linefill_dat_pld     ;
    logic                         wr_req_dat_vld       ;                   
    logic                         wr_req_dat_rdy       ;          
    pack_wr_dat_pld               wr_req_pld           ;         
    logic                         evict_dat_vld        ;
    logic                         evict_dat_rdy        ;
    pack_evict_dat_pld            evict_dat_pld        ;
    logic                         adp_crdv             ;
    logic                         dat_ram_pipe_vld     ;
    logic                         dat_ram_pipe_rdy     ;
    pack_dat_ram_pld              dat_ram_pipe_pld     ;
    logic                         evict_en             ; 
    logic [L1D_MSHR_ID_WIDTH-1:0] evict_id             ; 
    logic [REQ_ID_WIDHT-1:0]      evict_dat            ;
//linefill_req_decoder
l1d_data_pipe_linefill_dec u_l1d_data_pipe_linefill_dec(
    .clk                   (clk               ),
    .rst_n                 (rst_n             ),
    .rx_rsp_flitpend       (rx_rsp_flitpend   ),
    .rx_rsp_flitv          (rx_rsp_flitv      ),
    .rx_rsp_flit           (rx_rsp_flit       ),
    .rx_rsp_lcrdv          (rx_rsp_lcrdv      ),
    .rx_dat_flitpend       (rx_dat_flitpend   ),
    .rx_dat_flitv          (rx_dat_flitv      ), 
    .rx_dat_flit           (rx_dat_flit       ),
    .rx_dat_lcrdv          (rx_dat_lcrdv      ),
    .linefill_dat_vld      (linefill_dat_vld  ),
    .linefill_dat_rdy      (linefill_dat_rdy  ),
    .linefill_dat_pld      (linefill_dat_pld  ),
    .linefill_done_en      (linefill_done_en  ),
    .linefill_done_id      (linefill_done_id  ),
    .mshr_data_addr        (mshr_data_addr    )  
);

//hit r/w decoder
l1d_data_pipe_wr_dec u_l1d_data_pipe_wr_dec(
    .clk             (clk            ),
    .rst_n           (rst_n          ),
    .dat_ram_req_vld (dat_ram_req_vld),
    .dat_ram_req_rdy (dat_ram_req_rdy),
    .dat_ram_req_pld (dat_ram_req_pld),
    .wr_req_dat_vld  (wr_req_dat_vld ),
    .wr_req_dat_rdy  (wr_req_dat_rdy ),
    .wr_req_pld      (wr_req_pld     )   
);

//evcit decoder
l1d_data_pipe_evict_dec u_l1d_data_pipe_evict_dec(
    .clk                    (clk                   ),
    .rst_n                  (rst_n                 ),
    .evict_req_vld          (evict_req_vld         ), 
    .evict_req_rdy          (evict_req_rdy         ),
    .evict_req_pld          (evict_req_pld         ),
    .evict_dat_ram_clean_en (evict_dat_ram_clean_en),
    .evict_dat_ram_clean_id (evict_dat_ram_clean_id),  
    .evict_dat_vld          (evict_dat_vld         ),
    .evict_dat_rdy          (evict_dat_rdy         ),
    .evict_dat_pld          (evict_dat_pld         ),
    .adp_crdv               (adp_crdv              )     
);

//fixed_priority arbiter
l1d_data_pipe_arbiter  u_l1d_data_pipe_arbiter
(
    .clk                     (clk             ),
    .rst_n                   (rst_n           ),
    .linefill_dat_vld        (linefill_dat_vld),
    .linefill_dat_rdy        (linefill_dat_rdy),
    .linefill_dat_pld        (linefill_dat_pld),
    .wr_req_dat_vld          (wr_req_dat_vld  ),
    .wr_req_dat_rdy          (wr_req_dat_rdy  ),
    .wr_req_pld              (wr_req_pld      ),
    .evict_dat_vld           (evict_dat_vld   ),
    .evict_dat_rdy           (evict_dat_rdy   ),
    .evict_dat_pld           (evict_dat_pld   ),
    .dat_ram_pipe_vld        (dat_ram_pipe_vld),
    .dat_ram_pipe_rdy        (dat_ram_pipe_rdy),
    .dat_ram_pipe_pld        (dat_ram_pipe_pld)
);
//data_ram pipe
l1d_data_ram_pipe u_l1d_data_ram_pipe(
    .dat_ram_pipe_vld        (dat_ram_pipe_vld),
    .dat_ram_pipe_rdy        (dat_ram_pipe_rdy),
    .dat_ram_pipe_pld        (dat_ram_pipe_pld),
    .upstream_ack_en         (upstream_ack_en ),
    .upstream_ack_dat        (upstream_ack_dat),
    .upstream_sb_pld         (upstream_sb_pld ),
    .evict_en                (evict_en        ),
    .evict_id                (evict_id        ),
    .evict_dat               (evict_dat       )
);
//write adapter:with credit buffer in it 

endmodule 