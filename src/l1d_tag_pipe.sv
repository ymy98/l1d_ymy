module l1d_tag_pipe 
    import l1d_package::*;
(
    input  logic                                            clk                                         ,
    input  logic                                            rst_n                                       ,

    input  logic                                            tag_pipe_req_vld                            ,
    output logic                                            tag_pipe_req_rdy                            ,
    input  pack_l1d_req                                     tag_pipe_req_pld                            ,
    input  logic [L1D_MSHR_ID_WIDTH-1:0]                    tag_pipe_req_index                          ,

    input  logic [L1D_INDEX_WIDTH-1:0]                      v_hzd_index       [L1D_MSHR_ENTRY_NUM-1:0]  ,
    input  logic [L1D_WAY_NUM_WIDTH-1:0]                    v_hzd_way         [L1D_MSHR_ENTRY_NUM-1:0]  ,
    input  logic [L1D_TAG_WIDTH-1:0]                        v_hzd_evict_tag   [L1D_MSHR_ENTRY_NUM-1:0]  ,
    input  logic [L1D_MSHR_ENTRY_NUM-1:0]                   v_hzd_index_way_en                          ,
    input  logic [L1D_MSHR_ENTRY_NUM-1:0]                   v_hzd_evict_tag_en                          ,

    output logic                                            mshr_state_update_en                        ,
    output pack_l1d_mshr_state                              mshr_state_update_pld                       ,
    output logic                                            mshr_state_update_hzd_pass                  
);
//-----------
//signals
//-----------

//pld signals
    pack_l1d_req                         on_pipe_pld                    ;
    pack_l1d_req                         wr_buf                         ;
    logic        [L1D_WAY_NUM-1:0]       wr_way_buf                     ;
    logic                                wr_ena_buf                     ;
    pack_l1d_req                         pld_buf                        ;
    logic        [L1D_MSHR_ID_WIDTH-1:0] mshr_id_buf                    ;
    logic                                pld_ena_buf                    ;
    logic                                pld_is_write                   ;
    logic                                req_handshake                  ;

//tag ram
    logic [L1D_TAG_RAM_DEPTH-1:0]        tag_valid     [L1D_WAY_NUM-1:0];
    logic [L1D_TAG_RAM_DEPTH-1:0]        tag_dirty     [L1D_WAY_NUM-1:0];
    logic [L1D_INDEX_WIDTH-1:0]          tag_ram_addr  [L1D_WAY_NUM-1:0];
    logic [L1D_TAG_WIDTH-1:0]            tag_ram_din   [L1D_WAY_NUM-1:0];
    logic [L1D_TAG_WIDTH-1:0]            tag_ram_dout  [L1D_WAY_NUM-1:0];
    logic [L1D_WAY_NUM-1:0]              tag_ram_ena                    ;
    logic [L1D_WAY_NUM-1:0]              tag_ram_wr                     ;
    logic [L1D_WAY_NUM-1:0]              tag_ram_rd                     ;


//weight buffer
    logic [WEIGHT_WIDHT-1:0]       index_weight [L1D_INDEX_WIDTH-1:0]   ;

//behavior map check input
    logic                          hzd_pass                             ;
    logic                          tag_hit                              ;
    logic                          bmap_tag_dirty                       ;
    logic                          bmap_tag_valid                       ;
    logic  [L1D_WAY_NUM-1:0]       hit_way                              ;
    logic  [L1D_TAG_WIDTH-1:0]     evict_tag                            ;
    logic  [L1D_MSHR_ID_WIDTH-1:0] hzd_index_way_line                   ;
    logic  [L1D_MSHR_ID_WIDTH-1:0] hzd_evict_tag_line                   ;

//behavior map check output
    logic                          update                               ;
    pack_l1d_weight_pld            weight_update_pld                    ;
    
//-----------
//pld_buf and arbiter
//-----------
    //handshake
    assign req_handshake = tag_pipe_req_vld && tag_pipe_req_rdy  ;

    //arbiter
    always_comb begin
        if(wr_ena_buf)    on_pipe_pld = wr_buf                   ;
        else              on_pipe_pld = tag_pipe_req_pld         ; 
    end

    //pld buffer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            pld_buf     <= {$bits(pack_l1d_req){1'b0}}           ;
            pld_ena_buf <= 1'b0                                  ;
        end
        else if(req_handshake || wr_ena_buf) begin
            pld_buf     <= on_pipe_pld                           ;
            pld_ena_buf <= 1'b1                                  ;
        end
        else begin
            pld_buf     <= pld_buf                               ;
            pld_ena_buf <= 1'b0                                  ;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         pld_is_write <= 1'b0                         ;
        else if(wr_ena_buf) pld_is_write <= 1'b1                         ;
        else                pld_is_write <= 1'b0                         ; 
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         mshr_id_buf <= {L1D_MSHR_ID_WIDTH{1'b0}}     ;
        else                mshr_id_buf <= tag_pipe_req_index            ;
    end

    //wr buffer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_buf      <= {$bits(pack_l1d_req){1'b0}}      ;
            wr_way_buf  <= {L1D_WAY_NUM{1'b0}}              ;
        end
        else begin
            if(!tag_hit && pld_ena_buf )  begin
                wr_buf     <= tag_pipe_req_pld              ;
                wr_way_buf <= hit_way                       ;
            end
        end
    end

    always_ff@(posedge clk or negedge rst_n) begin
        if (!rst_n)                                       wr_ena_buf   <= 1'b0            ;
        else if(pld_ena_buf && !tag_hit && !pld_is_write) wr_ena_buf   <= 1'b1            ;
        else                                              wr_ena_buf   <= 1'b0            ;
    end
//-----------
//tag ram
//-----------
    //tag ram: valid dirty tag
    //valid reg file 
    //update after read tag sram or sync with write sram
    logic                    tag_first_req ;
    logic [WEIGHT_WIDHT-1:0] pld_evict_way ;

    assign tag_first_req  = pld_ena_buf && (!pld_is_write);
    
    assign pld_evict_way  = index_weight[pld_buf.index];

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)                                              tag_valid                                   <= {(L1D_WAY_NUM*L1D_TAG_RAM_DEPTH){1'b0}};
        else if (!pld_is_write && pld_ena_buf && !tag_hit)      tag_valid[pld_evict_way ][pld_buf.index]    <= 1'b0                                   ;
        else if(wr_ena_buf)                                     tag_valid[wr_way_buf][wr_buf.index]         <= 1'b1                                   ;
    end

    //dirty reg file
    //update after read tag sram
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)                                              tag_dirty                                   <= {(L1D_WAY_NUM*L1D_TAG_RAM_DEPTH){1'b0}};
        else if(tag_first_req) begin
            if(tag_hit && !pld_buf.op_is_read)                  tag_dirty[hit_way][pld_buf.index]           <=1'b1                                    ;
            else if(!tag_hit )                                  tag_dirty[pld_evict_way ][pld_buf.index]    <= ~pld_buf.op_is_read                    ;
        end
    end

    //tag sram io
    genvar k;
    generate for(k=0;k<L1D_WAY_NUM;k++) begin
        always_comb begin
            tag_ram_addr[k] = pld_buf.index                 ;
            tag_ram_din[k]  = pld_buf.tag                   ;
            tag_ram_rd[k]   = req_handshake                 ;
            tag_ram_wr[k]   = wr_ena_buf && wr_way_buf[k]   ;
            tag_ram_ena[k]  = tag_ram_rd[k] || tag_ram_wr[k];
        end
        sp_sram#(
            .DATA_WIDTH(L1D_TAG_WIDTH),
            .ADDR_WIDTH(L1D_INDEX_WIDTH)
        )u_tag_ram(
            .clk        (clk)               ,      
            .rst_n      (rst_n)             ,    
            .en         (tag_ram_ena[k])    ,       
            .rw         (tag_ram_wr[k])     ,       
            .addr       (tag_ram_addr[k])   ,     
            .data_in    (tag_ram_din[k])    ,  
            .data_out   (tag_ram_dout[k])  
        );
    end
    endgenerate



//----------------
//weight buffer
//----------------
    always_ff @(posedge clk or negedge rst_n)begin
        if(!rst_n)                    index_weight                                 <= {(WEIGHT_WIDHT*L1D_INDEX_WIDTH){1'b0}}     ;
        else if(update)               index_weight[weight_update_pld.index]        <= weight_update_pld.new_weight               ;
    end

//----------------
//Hit/Miss check
//----------------
    logic [L1D_WAY_NUM-1:0] tag_ram_hit;
    logic                   wr_buf_hit ;
    
    generate for(k=0;k<L1D_WAY_NUM;k++) begin
        assign tag_ram_hit[k] = (tag_ram_dout[k] == pld_buf.tag) && tag_valid[k];
        assign hit_way[k]     = tag_ram_hit[k]                                  ;
    end
    endgenerate

    assign wr_buf_hit = wr_buf.tag == pld_buf.tag;

    assign tag_hit    = ((|tag_ram_hit) || wr_buf_hit);

    
//----------------
//evict tag check
//----------------
    logic [L1D_MSHR_ENTRY_NUM-1:0] mshr_id_1hot;

    cmn_bin2onehot#(
       .BIN_WIDTH   (L1D_MSHR_ID_WIDTH ),
       .ONEHOT_WIDTH(L1D_MSHR_ENTRY_NUM)
    )u_cmn_bin2onehot(
       .bin_in      (mshr_id_buf       ),
       .onehot_out  (mshr_id_1hot      )
    );

    //index-way hz
    genvar j;
    generate for(j=0;j<L1D_MSHR_ENTRY_NUM;j++) begin
        assign hzd_index_way_line[j] = (~mshr_id_1hot[j]) && v_hzd_index_way_en[j] && (pld_buf.index == v_hzd_index[j] ) && (mshr_state_update_pld.way == v_hzd_way[j]) ;
    end
    endgenerate
    //evict-tag hz
    generate for(j=0;j<L1D_MSHR_ENTRY_NUM;j++) begin
        assign hzd_evict_tag_line[j] = (~mshr_id_1hot[j]) && v_hzd_evict_tag_en[j] && (pld_buf.tag == v_hzd_evict_tag[j])                                               ;
    end
    endgenerate

//----------------
//Behavior Map check
//----------------
assign bmap_tag_dirty = tag_hit ? tag_dirty[hit_way][pld_buf.index] : tag_dirty[pld_evict_way][pld_buf.index]    ;
assign bmap_tag_valid = tag_hit ? tag_valid[hit_way][pld_buf.index] : tag_valid[pld_evict_way][pld_buf.index]    ;  
assign hzd_pass       = (~(|hzd_evict_tag_line)) && (~(|hzd_index_way_line))                                     ;
assign update         = pld_ena_buf && (~pld_is_write)                                                           ;
assign evict_tag      = tag_ram_dout[pld_evict_way ]                                                             ;

l1d_tag_behavior_map u_l1d_tag_behavior_map(
    .tag_hit                              (tag_hit              ),
    .tag_dirty                            (bmap_tag_dirty       ),
    .tag_valid                            (bmap_tag_valid       ),
    .hzd_index_way_line                   (hzd_index_way_line   ),
    .hzd_evict_tag_line                   (hzd_evict_tag_line   ),
    .hit_way                              (hit_way              ),
    .pld_in                               (pld_buf              ),
    .evict_tag                            (evict_tag            ),
    .index_weight                         (index_weight         ),
    .mshr_id                              (mshr_id_buf          ), 
    .weight_update_pld                    (weight_update_pld    ),
    .mshr_state_update_pld                (mshr_state_update_pld)
);

assign mshr_state_update_hzd_pass           = hzd_pass                     ;
assign mshr_state_update_en                 = update                       ;
assign tag_pipe_req_rdy                     = ~wr_ena_buf                  ;

endmodule