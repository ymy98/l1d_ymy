module l1d_data_pipe_wr_dec
    import l1d_package::*;
(
    input  logic                 clk             ,
    input  logic                 rst_n           ,
    //mshr pld
    input  logic                 dat_ram_req_vld ,
    output logic                 dat_ram_req_rdy ,
    input  pack_data_ram_req_pld dat_ram_req_pld ,
    //arbiter pld
    output logic                 wr_req_dat_vld  ,
    input  logic                 wr_req_dat_rdy  ,
    output pack_wr_dat_pld       wr_req_pld     
);
always_comb begin
    wr_req_pld.pack_addr.index  = dat_ram_req_pld.index            ;
    wr_req_pld.pack_addr.offset = dat_ram_req_pld.offset           ;
    wr_req_pld.pack_addr.way    = dat_ram_req_pld.way              ;
    wr_req_pld.rw_type          = dat_ram_req_pld.rw_type          ;
    wr_req_pld.wr_req_dat       = dat_ram_req_pld.wr_data          ;
    wr_req_pld.wr_req_dat_be    = dat_ram_req_pld.wr_data_byte_en  ;
    wr_req_pld.wr_req_dat_be    = dat_ram_req_pld.wr_sb_pld        ;
end

assign wr_req_dat_vld  = dat_ram_req_vld;
assign dat_ram_req_rdy = wr_req_dat_rdy ;
endmodule 