module l1d_data_pipe_arbiter
    import l1d_package::*;
(
    input  logic                       clk                      ,
    input  logic                       rst_n                    ,
    //linefill          
    input  logic                       linefill_dat_vld         ,
    output logic                       linefill_dat_rdy         ,
    input  pack_linefill_dat_pld       linefill_dat_pld         ,
    //wr            
    input  logic                       wr_req_dat_vld           ,
    output logic                       wr_req_dat_rdy           ,
    input  pack_wr_dat_pld             wr_req_pld               ,
    //evict         
    input  logic                       evict_dat_vld            ,
    output logic                       evict_dat_rdy            ,
    output pack_evict_dat_pld          evict_dat_pld            ,
    //data ram pipe      
    output logic                       dat_ram_pipe_vld         ,
    input  logic                       dat_ram_pipe_rdy         ,
    output pack_dat_ram_pld            dat_ram_pipe_pld         
);

logic           linefill_vld_only;
logic           evict_vld_only   ;

assign evict_vld_only      = !wr_req_dat_vld                                            ;
assign linefill_vld_only   =(!wr_req_dat_vld) && (!evict_dat_vld)                       ;
assign wr_req_dat_rdy      =  dat_ram_pipe_rdy                                          ;
assign evict_dat_rdy       =  dat_ram_pipe_rdy && evict_vld_only                        ;
assign linefill_dat_rdy    =  dat_ram_pipe_rdy && linefill_vld_only                     ;
assign dat_ram_pipe_vld    =  linefill_dat_vld ||  wr_req_dat_vld   ||   evict_dat_vld  ;

always_comb begin
    if(linefill_vld_only)  begin
        dat_ram_pipe_pld.dat_ram_addr    =  linefill_dat_pld.linefill_dat_addr          ;
        dat_ram_pipe_pld.rw_type         =  1'b0                                        ;
        dat_ram_pipe_pld.rw_data_byte_en =  {REQ_DATA_EN_WIDTH{1'b1}}                   ;
        dat_ram_pipe_pld.op_is_downstream=  1'b1                                        ;

    end
    else if (evict_vld_only) begin
        dat_ram_pipe_pld.dat_ram_addr   =  evict_dat_pld.evict_dat_addr                 ;
        dat_ram_pipe_pld.rw_type        =  1'b1                                         ;
        dat_ram_pipe_pld.rw_data_byte_en=  {REQ_DATA_EN_WIDTH{1'b1}}                    ;
        dat_ram_pipe_pld.op_is_downstream=  1'b1                                        ;

    end
    else begin
        dat_ram_pipe_pld.dat_ram_addr   =  dat_ram_pipe_pld.dat_ram_addr                ;
        dat_ram_pipe_pld.rw_type        =  dat_ram_pipe_pld.rw_type                     ;
        dat_ram_pipe_pld.rw_data_byte_en=  dat_ram_pipe_pld.wr_data_byte_en             ;
        dat_ram_pipe_pld.op_is_downstream=  1'b0                                        ;
    end
end

assign dat_ram_pipe_pld.rw_data         = dat_ram_pipe_pld.rw_data                      ;
assign dat_ram_pipe_pld.wr_sb_pld       = dat_ram_pipe_pld.wr_sb_pld                    ;
assign dat_ram_pipe_pld.wr_ID           = evict_dat_pld.evict_id                        ;
endmodule 