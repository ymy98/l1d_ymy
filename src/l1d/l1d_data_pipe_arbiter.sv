module l1d_data_pipe_arbiter
import l1d_package::*;
(
    //bypass
    input  pack_l1d_tag_rsp                                 tag_pipe_rsp_pld                            ,
    input  logic                                            tag_pipe_rsp_vld                            ,
    output logic                                            tag_pipe_rsp_rdy                            ,
    //downstream
    input  logic                                            downstream_rsp_vld                          ,
    output logic                                            downstream_rsp_rdy                          ,
    input  pack_l1d_data_pipe_downstream_rsp                downstream_rsp_pld                          ,
    //rw
    output logic                                            rw_req_rdy                                  ,
    input  logic                                            rw_req_vld                                  ,
    input  pack_l1d_mshr_rw_req_pld                         rw_req_pld                                  ,
    //evict
    output logic                                            evict_req_rdy                               , 
    input  logic                                            evict_req_vld                               ,
    input  pack_l1d_mshr_evict_req_pld                      evict_req_pld                               ,
    //data_ram
    input  logic                                            data_ram_req_rdy                            ,
    output logic                                            data_ram_req_vld                            ,
    output pack_l1d_data_ram_req                            data_ram_req_pld                            ,
    //output 
    input  logic [L1D_MSHR_ID_WIDTH-1:0]                    downstream_rsp_id                           ,
    output logic [L1D_MSHR_ID_WIDTH-1:0]                    linefill_done_id                            ,
    output logic                                            linefill_done_en                                     
);
//------------------------------------------------------------------
//------fixed arbiter: bypass > rw > linefill > evict
//------------------------------------------------------------------
assign tag_pipe_rsp_rdy   = data_ram_req_rdy                                                                ;
assign rw_req_rdy         = data_ram_req_rdy && !tag_pipe_rsp_vld                                           ;  
assign downstream_rsp_rdy = data_ram_req_rdy && !tag_pipe_rsp_vld && !rw_req_vld                            ;
assign evict_req_rdy      = data_ram_req_rdy && !tag_pipe_rsp_vld && !rw_req_vld  && !downstream_rsp_vld    ;

assign data_ram_req_vld   = tag_pipe_rsp_vld || rw_req_vld || downstream_rsp_vld || evict_req_vld           ;

//------------------------------------------------------------------
//------data_ram_pld
//------------------------------------------------------------------
always_comb begin
        data_ram_req_pld.way         = evict_req_pld.way            ;
        data_ram_req_pld.index       = evict_req_pld.index          ;
        data_ram_req_pld.offset      = evict_req_pld.offset         ;
        data_ram_req_pld.op_is_read  = 1'b1                         ;
        data_ram_req_pld.wr_data     = tag_pipe_rsp_pld.wr_data     ;
        data_ram_req_pld.wr_data_be  = tag_pipe_rsp_pld.wr_data_be  ;

    if(tag_pipe_rsp_vld)        begin
        data_ram_req_pld.way         = tag_pipe_rsp_pld.way        ;
        data_ram_req_pld.index       = tag_pipe_rsp_pld.index      ;
        data_ram_req_pld.offset      = tag_pipe_rsp_pld.offset     ;
        data_ram_req_pld.op_is_read  = tag_pipe_rsp_pld.op_is_read ;
        data_ram_req_pld.wr_data     = tag_pipe_rsp_pld.wr_data    ;
        data_ram_req_pld.wr_data_be  = tag_pipe_rsp_pld.wr_data_be ;
    end
    else if(rw_req_vld)         begin
        data_ram_req_pld.way         = rw_req_pld.way              ;
        data_ram_req_pld.index       = rw_req_pld.index            ;
        data_ram_req_pld.offset      = rw_req_pld.offset           ;
        data_ram_req_pld.op_is_read  = rw_req_pld.op_is_read       ;
        data_ram_req_pld.wr_data     = rw_req_pld.wr_data          ;
        data_ram_req_pld.wr_data_be  = rw_req_pld.wr_data_be       ;
    end
    else if(downstream_rsp_vld) begin
        data_ram_req_pld.way         = downstream_rsp_pld.way      ;
        data_ram_req_pld.index       = downstream_rsp_pld.index    ;
        data_ram_req_pld.offset      = downstream_rsp_pld.offset   ;
        data_ram_req_pld.op_is_read  = 1'b0                        ;
        data_ram_req_pld.wr_data     = downstream_rsp_pld.wr_data  ;
        data_ram_req_pld.wr_data_be  = {REQ_DE_WIDTH{1'b1}}        ;
    end
end
assign linefill_done_en = downstream_rsp_vld && downstream_rsp_rdy && downstream_rsp_pld.wr_last;
assign linefill_done_id = downstream_rsp_id                                                     ;
endmodule