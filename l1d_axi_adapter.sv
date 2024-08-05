
module l1d_axi_adapter 
    import l1d_package::*;
(

    input                           downstream_req_vld              ,
    output                          downstream_req_rdy              ,
    input                           downstream_req_pld              ,

    output                          axi_arvalid                     ,
    input                           axi_arready                     ,
    output                          axi_araddr                      ,
    output [L1D_MSHR_ID_WIDTH-1:0]  axi_arid                        ,
    output                          axi_arsize                      ,
    output                          axi_arlen                       ,


    output                          evict_done_en                   ,
    output [L1D_MSHR_ID_WIDTH-1:0]  evict_done_id                   ,

    input                           axi_bvalid                      ,
    output                          axi_bready                      ,
    input  [L1D_MSHR_ID_WIDTH-1:0]  axi_bid                         ,
    input  [1:0]                    axi_bresp          
);

    // ar channel mapping


    // b channel mapping
    assign evict_done_en = axi_bvalid   ;
    assign evict_done_id = axi_bid      ;

    assign axi_bready = 1'b1;

    // some other error handler.

endmodule