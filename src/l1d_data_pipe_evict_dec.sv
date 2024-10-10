module l1d_data_pipe_evict_dec
import l1d_package::*;
(
    input  logic                         clk                          ,
    input  logic                         rst_n                        ,
    //mshr pld                     
    input  logic                         evict_req_vld                , 
    output logic                         evict_req_rdy                ,
    input  pack_evict_req_pld            evict_req_pld                ,

    output logic                         evict_dat_ram_clean_en       ,
    output logic [L1D_MSHR_ID_WIDTH-1:0] evict_dat_ram_clean_id       ,    
    
    //arbiter pld
    output logic                         evict_dat_vld                ,
    input  logic                         evict_dat_rdy                ,
    output pack_evict_dat_pld            evict_dat_pld                ,
    
    //write adapter credit
    input  logic                         adp_crdv                                      
    );

logic [L1D_OFFSET_WIDTH-1:0]             evcit_offset_cnt             ;
pack_evict_dat_pld                       last_evict_buf               ;
logic                                    last_evict_vld               ;
logic                                    evict_pld_done               ;                               
logic                                    evict_req_hs                 ;
logic                                    evict_dat_hs                 ;

//---------------------------
//-----behavior map
//---------------------------
assign evict_req_hs   = evict_req_vld                        && evict_req_rdy          ;
assign evict_dat_hs   = evict_dat_vld                        && evict_dat_rdy          ;
assign evict_pld_done = (evcit_offset_cnt == L1D_OFFSET_MAX) && evict_dat_hs           ;

assign evict_dat_vld  = (last_evict_vld || evict_req_hs)  && (!adp_crdv)    ;
assign evict_req_rdy  = !last_evict_vld                                     ;


//----------------------------
//-----evcit data ram addr cnt
//----------------------------
always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)            evcit_offset_cnt <= {L1D_OFFSET_WIDTH{1'b0}}  ;
    else if(evict_dat_hs) evict_offset_cnt <= evict_offset_cnt + 1'b1   ;
end

//----------------------------
//-----evcit data ram output
//----------------------------
always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                   
            last_evcit_buf <= {$bits(pack_evict_dat_pld){1'b0}};
    else if(evict_req_hs) begin
            last_evict_buf.index    <= evict_req_pld.index      ;
            last_evict_buf.way      <= evict_req_pld.way        ;
            last_evict_buf.offset   <= evict_req_pld.offset     ;
            last_evict_buf.evict_id <= evict_req_pld.mshr_id    ;
    end      
end

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                      last_evict_vld <= 1'b0      ;
    else if (evict_req_hs)          last_evict_vld <= 1'b1      ;
    else if (evict_pld_done)        last_evict_vld <= 1'b0      ;
end    

always_comb begin
    evict_dat_pld.evict_dat_addr.index  = last_evict_vld ?  last_evict_buf.index   : evict_req_pld.index     ;
    evict_dat_pld.evict_dat_addr.way    = last_evict_vld ?  last_evict_buf.way     : evict_req_pld.way       ;
    evict_dat_pld.evict_dat_addr.offset = last_evict_vld ?  evict_offset_cnt       : evict_offset_cnt        ;
    evict_dat_pld.evict_id              = last_evict_vld ?  last_evict_buf.mshr_id : evict_req_pld.mshr_id   ;
end

endmodule 