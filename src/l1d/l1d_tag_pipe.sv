module l1d_tag_pipe
import l1d_package::*;
(    
    input  logic                                            clk                                         ,
    input  logic                                            rst_n                                       ,
    //from upstream          
    input  logic                                            upstream_req_vld                            ,
    output logic                                            upstream_req_rdy                            ,
    input  pack_l1d_tag_req                                 upstream_req_pld                            ,
    input  logic                                            cancel_last_trans                           ,
    //to upstream
    output logic                                            upstream_tag_hit                            ,
    //from prefetch engine         
    input  logic                                            mshr_prefetch_vld                           ,
    output logic                                            mshr_prefetch_rdy                           ,
    input  pack_l1d_tag_req                                 mshr_prefetch_pld                           ,
    //alloc credit from mshr         
    input  logic                                            mshr_alloc_vld                              ,
    output logic                                            mshr_alloc_rdy                              ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]                    mshr_alloc_id                               ,
    //hzd from mshr 
    input  logic [L1D_INDEX_WIDTH-1:0]                      v_hzd_index       [L1D_MSHR_ENTRY_NUM-1:0]  ,
    input  logic [L1D_WAY_NUM-1:0]                          v_hzd_way         [L1D_MSHR_ENTRY_NUM-1:0]  ,
    input  logic [L1D_TAG_WIDTH-1:0]                        v_hzd_evict_tag   [L1D_MSHR_ENTRY_NUM-1:0]  ,
    input  logic [L1D_MSHR_ENTRY_NUM-1:0]                   v_hzd_index_way_en                          ,
    input  logic [L1D_MSHR_ENTRY_NUM-1:0]                   v_hzd_evict_tag_en                          ,
    //mshr state update
    output logic                                            mshr_state_update_en                        ,
    output logic [L1D_MSHR_ID_WIDTH-1:0]                    mshr_state_update_id                        ,
    output logic                                            mshr_state_update_hzd_pass                  ,
    output logic [L1D_MSHR_ENTRY_NUM-1:0]                   mshr_hzd_index_way_line                     ,
    output logic [L1D_MSHR_ENTRY_NUM-1:0]                   mshr_hzd_evict_tag_line                     ,
    
    output pack_l1d_tag_rsp                                 tag_pipe_rsp_pld                            ,
    output logic                                            tag_pipe_rsp_vld                            ,
    input  logic                                            tag_pipe_rsp_rdy                                                                                    
);
//--------------------
//-----internal signals
//---------------------
logic                           tag_pipe_req_vld                    ;
logic                           tag_pipe_req_rdy                    ;
pack_l1d_tag_req                tag_pipe_req_pld                    ;
logic                           tag_pipe_hsk                        ;
//pld_buffer                                                                       
logic                           tag_pipe_hsk_buf                    ;
pack_l1d_tag_req                tag_pipe_pld_buf                    ;

//write_buffer                                                      
logic                           wr_ena_buf                          ;
pack_l1d_tag_pipe_rw_pld        wr_pld_buf                          ;

//tag ram signals                                                   
logic                           tag_ram_en                          ;
logic                           tag_ram_wr                          ;
logic [L1D_INDEX_WIDTH-1:0]     tag_ram_addr                        ;
logic [L1D_TAG_RAM_WIDHT-1:0]   tag_ram_din                         ;
logic [L1D_TAG_RAM_WIDHT-1:0]   tag_ram_dout                        ;
                                                                    
logic [L1D_WAY_NUM-1:0]         tag_ram_dty[LAD_TAG_RAM_DEPTH-1:0]  ;
logic [L1D_WAY_NUM-1:0]         tag_ram_vld[LAD_TAG_RAM_DEPTH-1:0]  ;

logic [L1D_INDEX_WIDTH-1:0]     tag_idx                             ;
logic [L1D_INDEX_NUM-1:0]       tag_idx_ohot                        ;
logic [L1D_WAY_WIDTH-1:0]       tag_way                             ;
logic [L1D_WAY_NUM-1:0]         tag_way_ohot                        ;
logic                           tag_vld_upd                         ;
logic                           tag_dty_upd                         ;
logic                           tag_dty_cln                         ;

//hit/miss check signals                                                        
logic                           wr_buf_hit                          ;
logic                           tag_ram_hit                         ;
logic                           wr_buf_idx_hit                      ;
logic                           wr_buf_tag_hit                      ;
logic [L1D_WAY_NUM-1:0]         wr_buf_way_ohot                     ;

logic [L1D_WAY_NUM-1:0]         tag_ram_hit_way_vld                 ;
logic                           tag_hit                             ;
logic [L1D_WAY_WIDTH-1:0]       hit_way                             ;
logic [L1D_WAY_NUM-1:0]         hit_way_ohot                        ;
logic [L1D_WAY_NUM-1:0]         tag_ram_hit_way_ohot                ;

//weight                                                                            
logic [L1D_WAY_WIDTH-1:0]       weight_idx                          ;
logic [L1D_WAY_WIDTH-1:0]       evict_way                           ;
logic [L1D_WAY_NUM-1:0]         evict_way_ohot                      ;

//hzd check                                                         
logic [L1D_MSHR_ENTRY_NUM-1:0]  hzd_index_line                      ;
logic [L1D_MSHR_ENTRY_NUM-1:0]  hzd_hit_way_line                    ;
logic [L1D_MSHR_ENTRY_NUM-1:0]  hzd_evict_way_line                  ;
logic [L1D_MSHR_ENTRY_NUM-1:0]  hzd_index_way_line                  ;
logic [L1D_MSHR_ENTRY_NUM-1:0]  hzd_evict_tag_line                  ;

//behavior map
logic                           evict_tag_vld                       ;
logic                           evict_tag_dty                       ;
logic                           tag_req_byps                        ;
logic                           tag_pipe_upd                        ;
//--------------------
//-----req arbiter
//---------------------
assign      tag_pipe_req_vld  = mshr_alloc_vld   && (upstream_req_vld || mshr_prefetch_vld)                      ;
assign      tag_pipe_req_pld  = upstream_req_vld ?  upstream_req_pld : mshr_prefetch_pld                         ;
assign      mshr_alloc_rdy    = tag_pipe_req_vld && tag_pipe_req_rdy                                             ;
assign      upstream_req_rdy  = mshr_alloc_vld   && upstream_req_vld  && tag_pipe_req_rdy                        ;
assign      mshr_prefetch_rdy = mshr_alloc_vld   && mshr_prefetch_vld && (~upstream_req_vld) && tag_pipe_req_rdy ;

//---------------------------------------
//-----tag_pipe buf:enable when handshake
//---------------------------------------
assign tag_pipe_hsk = tag_pipe_req_vld && tag_pipe_req_rdy       ;

always_ff@(posedge clk or negedge rst_n)begin                     
    if(!rst_n)                 tag_pipe_hsk_buf <= 1'b0          ;
    else if(tag_pipe_hsk)      tag_pipe_hsk_buf <= 1'b1          ;
    else                       tag_pipe_hsk_buf <= 1'b0          ;
end                                                                             

always_ff@(posedge clk)begin
    tag_pipe_pld_buf <= tag_pipe_req_pld                         ;
end

//-----------------------------------
//-----write buf:enable when tag miss
//-----------------------------------
always_ff@(posedge clk or negedge rst_n) begin                                  
    if (!rst_n)                                                    wr_ena_buf <= 1'b0;
    else if(tag_pipe_upd && !tag_hit )                             wr_ena_buf <= 1'b1;
    else                                                           wr_ena_buf <= 1'b0;
end

genvar i ;
logic [L1D_WAY_NUM-1:0][L1D_TAG_WIDTH-1:0] evict_tag_array;
generate
    for (i = 0; i < L1D_WAY_NUM; i++) begin : gen_evict_tag
        assign evict_tag_array[i] = tag_ram_dout[i * L1D_TAG_WIDTH + L1D_TAG_WIDTH -1 : i * L1D_TAG_WIDTH];
    end
endgenerate

generate for(i=0;i<L1D_WAY_NUM;i++) begin                                       
    always_ff@(posedge clk) begin                                           
        wr_pld_buf.line_tag[i]    <= evict_way_ohot[i] ? tag_pipe_pld_buf.wr_data : evict_tag_array[i] ;
    end                                                                                                                                 
end                                                                                                                                     
endgenerate

always_ff@(posedge clk) begin                       
    wr_pld_buf.tag   <= tag_pipe_pld_buf.tag        ;
    wr_pld_buf.index <= tag_pipe_pld_buf.index      ;   
    wr_pld_buf.way   <= evict_way                   ;
end       

//--------------------
//------hit/miss check
//--------------------
assign wr_buf_idx_hit   =  tag_pipe_req_pld.index == wr_pld_buf.index                                                           ;
assign wr_buf_tag_hit   =  tag_pipe_req_pld.tag   == wr_pld_buf.tag                                                             ;                       
assign wr_buf_hit       =  wr_buf_idx_hit         && wr_buf_tag_hit    && wr_ena_buf                                            ; 

cmn_bin2onehot #(
   .BIN_WIDTH    (L1D_WAY_WIDTH    ),
   .ONEHOT_WIDTH (L1D_WAY_NUM      )
)u_hit_way_bin2onehot(
   .bin_in       (wr_pld_buf.way   ),
   .onehot_out   (wr_buf_way_ohot  )
);

assign tag_ram_hit_way_vld = tag_ram_vld[tag_pipe_req_pld.index];

generate for(i=0;i<L1D_WAY_NUM;i++) begin
    assign tag_ram_hit_way_ohot[i] =  (evict_tag_array[i] == tag_pipe_req_pld.tag) && tag_ram_hit_way_vld[i]  ;
end
endgenerate

assign tag_ram_hit  = |tag_ram_hit_way_ohot                                         ;
assign tag_hit      = tag_ram_hit || wr_buf_hit                                     ;
assign hit_way_ohot = wr_buf_hit ? wr_buf_way_ohot : tag_ram_hit_way_ohot           ;

cmn_onehot2bin #(
    .ONEHOT_WIDTH(L1D_WAY_NUM)
)u_hit_way_ohot2bin(
    .onehot_in   (hit_way_ohot ),
    .bin_out     (hit_way      )
);

assign tag_way          =  tag_hit   ? hit_way         : evict_way                   ;  
assign tag_way_ohot     =  tag_hit   ? hit_way_ohot    : evict_way_ohot              ;
assign upstream_tag_hit =  tag_hit                                                   ;
//--------------------
//------weight update
//--------------------
always_ff@(posedge clk)begin
    weight_idx <= weight_idx + {{(L1D_WAY_WIDTH-1){1'b0}},1'b1} ;
end

assign evict_way      = weight_idx   ; 

cmn_bin2onehot #(
   .BIN_WIDTH    (L1D_WAY_WIDTH  ),
   .ONEHOT_WIDTH (L1D_WAY_NUM    )
)u_evict_way_bin2onehot(
   .bin_in       (evict_way        ),
   .onehot_out   (evict_way_ohot   )
);

//-------------------------------
//-----tag ram：valid dity tag
//-------------------------------
//----------tag_vld:
assign tag_vld_upd =  tag_pipe_upd && !tag_hit ;
genvar j ;
generate for (i=0;i<LAD_TAG_RAM_DEPTH;i++) begin
    for (j=0;j<L1D_WAY_NUM;j++) begin
        always_ff@(posedge clk or negedge rst_n) begin
            if(!rst_n)                                                              tag_ram_vld[i][j] <= 1'b0          ;
            else if((tag_idx_ohot[i]) && evict_way_ohot[j] && tag_vld_upd)          tag_ram_vld[i][j] <= 1'b1          ;     
        end
    end
end
endgenerate

//---------tag_idx:
assign tag_idx              = tag_pipe_pld_buf.index                                    ;
assign tag_dty_upd          = tag_pipe_upd && !tag_pipe_pld_buf.op_is_read              ;
//when evicted, and new tag id not read,tag is clean  
assign tag_dty_cln          = tag_pipe_upd && tag_pipe_pld_buf.op_is_read  && !tag_hit  ;

generate for (i=0;i<LAD_TAG_RAM_DEPTH;i++) begin
   for (j=0;j<L1D_WAY_NUM;j++) begin
       always_ff@(posedge clk or negedge rst_n) begin
           if(!rst_n)                                                          tag_ram_dty[i][j]  <= 1'b0         ;
           else if(tag_dty_upd && tag_idx_ohot[i] && tag_way_ohot[j])          tag_ram_dty[i][j]  <= 1'b1         ;
           else if(tag_dty_cln && tag_idx_ohot[i] && evict_way_ohot[j])        tag_ram_dty[i][j]  <= 1'b0         ;      
       end
   end
end
endgenerate

assign tag_ram_en    = wr_ena_buf || tag_pipe_hsk                               ;
assign tag_ram_wr    = wr_ena_buf                                               ;
assign tag_ram_addr  = wr_ena_buf ? wr_pld_buf.index : tag_pipe_req_pld.index   ;
assign tag_ram_din   = wr_pld_buf.line_tag                                      ; 

sp_sram#(
    .DATA_WIDTH(L1D_TAG_RAM_WIDHT), 
    .ADDR_WIDTH(L1D_INDEX_WIDTH  )
)u_sp_sram(
    .clk        (clk         ),      
    .rst_n      (rst_n       ),    
    .en         (tag_ram_en  ),       
    .rw         (tag_ram_wr  ),       
    .addr       (tag_ram_addr),     
    .data_in    (tag_ram_din ),  
    .data_out   (tag_ram_dout)   
);


//--------------------
//------hzd check
//--------------------
//hit way should check ?? should evict way be checked?
//---hit index way 
//---same hit index way,WAW RAW WAR should be in order
//---evict index way
//---evict should wait until the former actions are done
//---evict tag 
//---linefill should wait untill the same tag eviction done  
generate for (i=0;i<L1D_MSHR_ENTRY_NUM;i++) begin
    assign hzd_index_line[i]     = v_hzd_index_way_en[i] &&  (tag_pipe_req_pld.index == v_hzd_index[i]) ; 
end
endgenerate 

generate for (i=0;i<L1D_MSHR_ENTRY_NUM;i++) begin
    assign hzd_hit_way_line[i]   = hit_way   ==  v_hzd_way[i]                                           ; 
end
endgenerate 

generate for (i=0;i<L1D_MSHR_ENTRY_NUM;i++) begin
    assign hzd_evict_way_line[i] = evict_way ==  v_hzd_way[i]                                           ; 
end
endgenerate

generate for (i=0;i<L1D_MSHR_ENTRY_NUM;i++) begin
    assign hzd_index_way_line[i] = hzd_index_line[i] && ((tag_hit && hzd_hit_way_line[i]) || hzd_evict_way_line[i])                     ;
end
endgenerate

// generate for (i=0;i<L1D_MSHR_ENTRY_NUM;i++) begin
//     assign hzd_index_way_line[i] = v_hzd_index_way_en[j] && (tag_pipe_req_pld.index == v_hzd_index[j] ) && (tag_way == v_hzd_way[j]) ;
// end
// endgenerate

generate for(i=0;i<L1D_MSHR_ENTRY_NUM;i++) begin
    assign hzd_evict_tag_line[i] = v_hzd_evict_tag_en[i] && (tag_pipe_req_pld.tag == v_hzd_evict_tag[i])                                ;
end
endgenerate

assign mshr_state_update_en       = tag_pipe_upd                             ;
     
assign mshr_state_update_hzd_pass = tag_req_byps && tag_pipe_rsp_rdy         ; 

always_ff@(posedge clk) begin
    mshr_state_update_id          <= mshr_alloc_id       ;
end

assign mshr_hzd_index_way_line      = hzd_index_way_line  ;
assign mshr_hzd_evict_tag_line      = hzd_evict_tag_line  ;

//--------------------
//------Behavior Map
//--------------------
assign tag_pipe_req_rdy                                    = !wr_ena_buf              ;
assign tag_pipe_rsp_pld [$bits(pack_l1d_tag_req)-1:0]      = tag_pipe_pld_buf         ;

assign evict_tag_vld = tag_ram_vld[tag_pipe_req_pld.index][evict_way]                 ;
assign evict_tag_dty = tag_ram_dty[tag_pipe_req_pld.index][evict_way]                 ;

always_comb begin
    //need evict   :!tag_hit && tag_vld && tag_dty
    //need linefill:!tag_hit
    tag_pipe_rsp_pld.need_evict    = !tag_hit && evict_tag_vld && evict_tag_dty       ;
    tag_pipe_rsp_pld.need_linefill = !tag_hit                                         ;
    for(int k=0;k<L1D_WAY_NUM;k++) begin
        if(tag_way_ohot[k] == 1'b1)
            tag_pipe_rsp_pld.evict_tag =  evict_tag_array[k] ;
    end
    tag_pipe_rsp_pld.way           = tag_way                                          ;
end
assign tag_pipe_upd                = !cancel_last_trans && tag_pipe_hsk_buf                                                  ;
assign tag_req_byps                =  tag_hit && (~|(hzd_hit_way_line & hzd_index_line))  && tag_pipe_upd                    ;
assign tag_pipe_rsp_vld            =  tag_req_byps                                                                           ;
//--------------------
//------module instantiation
//--------------------
cmn_bin2onehot #(
   .BIN_WIDTH    (L1D_INDEX_WIDTH  ),
   .ONEHOT_WIDTH (LAD_TAG_RAM_DEPTH)
)u_tag_dty_idx_bin2onehot(
   .bin_in       (tag_idx          ),
   .onehot_out   (tag_idx_ohot     )
);

endmodule
