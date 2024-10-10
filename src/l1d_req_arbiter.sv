

module l1d_req_arbiter 
    import l1d_package::*;
(
    input                           clk                 ,
    input                           rst_n               ,

    // input from upstream
    input                           upstream_req_vld    ,
    output                          upstream_req_rdy    ,
    input  pack_l1d_req             upstream_req_pld    ,

    // input from prefetch engine
    input                           prefetch_vld        ,
    output                          prefetch_rdy        ,
    input  pack_l1d_req             prefetch_pld        ,

    // output to tag pipeline
    output                          tag_pipe_req_vld    ,
    input                           tag_pipe_req_rdy    ,
    output pack_l1d_req             tag_pipe_req_pld    ,
    output [L1D_MSHR_ID_WIDTH-1:0]  tag_pipe_req_index  ,

    // credit from mshr
    input                           alloc_vld           ,
    output                          alloc_rdy           ,
    input  [L1D_MSHR_ID_WIDTH-1:0]  alloc_index         
);


    assign tag_pipe_req_vld     = alloc_vld && (upstream_req_vld | prefetch_vld);
    assign tag_pipe_req_pld     = upstream_req_vld ? upstream_req_pld : prefetch_pld ;
    assign tag_pipe_req_index   = alloc_index;

    assign alloc_rdy            = tag_pipe_req_vld && tag_pipe_req_rdy;
    assign upstream_req_rdy     = alloc_vld && upstream_req_vld                     && tag_pipe_req_rdy;
    assign prefetch_rdy         = alloc_vld && prefetch_vld && (~upstream_req_vld)  && tag_pipe_req_rdy;

endmodule