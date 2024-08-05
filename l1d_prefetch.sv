
module l1d_prefetch 
    import l1d_package::*;
(
    output                          prefetch_vld        ,
    input                           prefetch_rdy        ,
    output pack_l1d_req             prefetch_pld        
);

    assign prefetch_vld = 0;
    assign prefetch_pld = 0;

endmodule