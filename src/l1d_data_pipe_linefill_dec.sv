module l1d_data_pipe_linefill_dec
    import l1d_package::*;
(
    input  logic                            clk                                     ,
    input  logic                            rst_n                                   ,
    //downstream respond                    
    input  logic                            rx_rsp_flitpend                         ,
    input  logic                            rx_rsp_flitv                            ,
    input  pack_rsp_flit                    rx_rsp_flit                             ,
    output logic                            rx_rsp_lcrdv                            ,
    input  logic                            rx_dat_flitpend                         ,
    input  logic                            rx_dat_flitv                            , 
    input  pack_data_flit                   rx_dat_flit                             ,
    output logic                            rx_dat_lcrdv                            ,
    //data_ram write                    
    output logic                            linefill_dat_vld                        ,
    input  logic                            linefill_dat_rdy                        ,
    output pack_linefill_dat_pld            linefill_dat_pld                        ,
    //mshr pld
    output logic                            linefill_done_en                        ,
    output logic [L1D_MSHR_ID_WIDTH-1:0]    linefill_done_id                        ,
    input  pack_mshr_dat_addr               mash_data_addr  [L1D_MSHR_ENTRY_NUM-1:0]
);

//rsp 
logic                             linefill_rx_rsp_flitpend ;
logic                             linefill_rx_rsp_vld      ;

//donwstream data
logic                             linefill_rx_dat_flitpend ;
logic                             linefill_rx_dat_vld      ;

//data_ram 
logic                             linefill_dat_hs          ;  
logic                             linefill_done            ;
pack_mshr_dat_addr                linefill_base_addr       ;
logic  [L1D_OFFSET_WIDTH-1:0]     linefill_cnt_addr        ;    
logic                             linefill_cnt_hit_max     ;   
logic                             linefill_cnt_done        ;
  

//----------------------
//---Behavior
//---------------------
assign linefill_rx_rsp_vld   = linefill_rx_rsp_flitpend && rx_rsp_flitv     && rx_rsp_lcrdv   ;
assign linefill_rx_dat_vld   = linefill_rx_dat_flitpend && rx_dat_flitv                       ;
assign linefill_dat_hs       = linefill_dat_vld         && linefill_dat_rdy                   ;
assign linefill_cnt_hit_max  = linefill_cnt_addr        == L1D_OFFSET_MAX                     ;
assign linefill_cnt_done     = linefill_cnt_hit_max     && linefill_dat_hs                    ;
//----------------------
//---linefill state 
//---------------------
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                                           linefill_done <= 1'b1;
    else if(linefill_cnt_done)                           linefill_done <= 1'b1;
    else if(linefill_rx_rsp_vld)                         linefill_done <= 1'b0;
end

//----------------------
//---linefill addr counter
//---------------------
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                         linefill_base_addr<= {$bits(pack_dat_addr){1'b0}}        ;
    else  if (linefill_rx_rsp_vld)     linefill_base_addr<= mash_data_addr[rx_rsp_flit.TxnID]   ;        
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                         linefill_cnt_addr <= {L1D_OFFSET_WIDTH{1'b0}}            ;   
    else if(linefill_dat_hs)           linefill_cnt_addr <= linefill_cnt_addr + 1'b1            ;
end

always_comb begin
    linefill_dat_pld.linefill_dat_addr.index  = linefill_base_addr.index   ;
    linefill_dat_pld.linefill_dat_addr.way    = linefill_base_addr.way     ;
    linefill_dat_pld.linefill_dat_addr.offset = linefill_cnt_addr          ;
end

//----------------------
//---chi rx rsp decoder
//---------------------
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)  linefill_rx_rsp_flitpend               <= 1'b0                                ;
    else        linefill_rx_rsp_flitpend               <= rx_rsp_flitpend                     ;
end       
    
assign rx_rsp_lcrdv = !linefill_done;

//----------------------
//---chi rx dat decoder
//---------------------
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)  linefill_rx_dat_flitpend               <= 1'b0                                ;
    else        linefill_rx_dat_flitpend               <= rx_dat_flitpend                     ;
end

assign linefill_dat_lcrdv                    = linefill_dat_rdy      ;
assign linefill_dat_vld                      = linefill_rx_dat_vld   ;
assign linefill_dat_pld.linefill_dat         = rx_dat_flit.Data      ;
//----------------------
//---linefill done 
//---------------------
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                    linefill_done_en <= 1'b0;
    else  if(linefill_cnt_done)   linefill_done_en <= 1'b1;
    else                          linefill_done_en <= 1'b0;
end
assign linefill_done_id     = rx_dat_flit.TxnID           ;
endmodule