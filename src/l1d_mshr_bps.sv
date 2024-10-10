module l1d_mshr_bps
import l1d_package::*;
(
    input  pack_l1d_mshr_state   tag_pipe_req_pld  ,
    input  logic                 tag_pipe_req_en   ,
    input  logic                 tag_pipe_hz_pass  ,
    input  logic                 data_ram_rdy      ,
    output logic                 mshr_bps_vld      ,
    output pack_data_ram_req_pld mshr_bps_pld      
);
//---
//---signals 
//---
logic  tag_pipe_data_ram_only                       ;
logic  tag_pipe_bypass_en                           ;
assign tag_pipe_data_ram_only = !tag_pipe_req_pld.need_evict  && !tag_pipe_req_pld.need_linefill                                     ;
assign tag_pipe_bypass_en     = tag_pipe_hz_pass              &&  tag_pipe_data_ram_only       &&  data_ram_rdy                      ;
assign mshr_bps_vld           = tag_pipe_req_en               &&  tag_pipe_bypass_en                                                 ;

assign mshr_bps_pld.rw_type           = tag_pipe_req_pld.need_rw            ;
assign mshr_bps_pld.index             = tag_pipe_req_pld.index              ;
assign mshr_bps_pld.offset            = tag_pipe_req_pld.offset             ;
assign mshr_bps_pld.way               = tag_pipe_req_pld.way                ;
assign mshr_bps_pld.wr_data           = tag_pipe_req_pld.wr_data            ;
assign mshr_bps_pld.wr_data_byte_en   = tag_pipe_req_pld.wr_data_byte_en    ;
assign mshr_bps_pld.wr_sb_pld         = tag_pipe_req_pld.wr_sb_pld          ;
endmodule 