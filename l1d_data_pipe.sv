
module l1d_data_pipe 
    import l1d_package::*;
(
    input       clk       ,
    input       rst_n     ,

    input       dat_ram_req_vld                 ,
    output      dat_ram_req_rdy                 ,
    input       dat_ram_req_pld                 ,

    output      evict_dat_ram_clean_en          ,
    output      evcit_dat_ram_clean_id          ,

    output      linefill_done_en                ,
    output      linefill_done_id                ,  

    output      upstream_ack_en                 ,
    output      upstream_ack_id                 ,
    output      upstream_ack_data               ,

    input       axi_rvalid      ,
    output      axi_rready      ,
    input       axi_rdata       ,
    input       axi_rid         ,

    output      axi_awvalid     ,
    input       axi_awready     ,
    output      axi_awid        ,
    output      axi_awburst     ,
    output      axi_awsize      ,
    output      axi_awlen       ,

    output      axi_wvalid      ,
    input       axi_wready      ,
    output      axi_wdata       

);


    // req decode


    // line fill decode


    // sram req arbiter


    // data ram op && sideband buffer


    // data ram output decode


    // write adapter


endmodule