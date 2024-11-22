module l1d_mshr_entry
    import l1d_package::*;
    (
        input  logic                           clk                        ,
        input  logic                           rst_n                      ,

        output logic                           alloc_vld                  ,
        input  logic                           alloc_rdy                  ,

        output logic [L1D_INDEX_WIDTH-1:0]     hzd_index                  ,
        output logic [L1D_WAY_NUM-1:0]         hzd_way                    ,
        output logic [L1D_TAG_WIDTH-1:0]       hzd_evict_tag              ,
        output logic                           hzd_index_way_en           ,
        output logic                           hzd_evict_tag_en           ,

        input  logic                           mshr_state_update_en       ,
        input  logic                           mshr_state_bypass          ,
        input  pack_l1d_tag_rsp                mshr_state_update_pld      ,
        input  logic [L1D_MSHR_ENTRY_NUM-1:0]  mshr_state_hzd_index_way   ,
        input  logic [L1D_MSHR_ENTRY_NUM-1:0]  mshr_state_hzd_evict_tag   ,

        output logic                           rw_req_vld                 ,
        input  logic                           rw_req_rdy                 ,

        output logic                           evict_req_vld              ,
        input  logic                           evict_req_rdy              ,

        output pack_l1d_mshr_rw_req_pld        rw_req_pld                 ,
        output pack_l1d_mshr_evict_req_pld     evict_req_pld              ,

        output logic                           downstream_req_vld         ,
        input  logic                           downstream_req_rdy         ,
        output pack_l1d_mshr_downstream_req_pld    downstream_req_pld         ,

        input  logic                           evict_dat_ram_clean_en     ,
        input  logic                           evict_done_en              ,
        input  logic                           linefill_done_en           ,

        input  logic [L1D_MSHR_ENTRY_NUM-1:0]  v_release_en_index_way_in  ,
        input  logic [L1D_MSHR_ENTRY_NUM-1:0]  v_release_en_evict_tag_in  ,
        output logic                           release_index_way_en       ,
        output logic                           release_evict_tag_en       ,
        input  logic                           clear_mshr_rd              
    );
//--------------------------
//-------signals : state
//--------------------------
    logic               idle                     ;
    logic               active                   ;
    logic               state_rw_done            ;

    logic               state_linefill_sent      ;
    logic               state_linefill_done      ;

    logic               state_evict_sent         ;
    logic               state_evict_dat_ram_clean;
    logic               state_evict_done         ;
//--------------------------
//-------signals : Behavior
//--------------------------
    logic               hzd_idx_way_free         ;
    logic               hzd_evict_tag_free       ;
    logic               state_all_done           ;
    logic               index_way_en             ;
    logic               evict_tag_en             ;
//--------------------------
//-------signals : regfile
//--------------------------
    pack_l1d_mshr_ety_regfile       mshr_ety_regfile        ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  hzd_index_way_regfile   ;
    logic [L1D_MSHR_ENTRY_NUM-1:0]  hzd_evict_tag_regfile   ;
//========================================================
// Entry State Management
//========================================================
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)                      idle <= 1'b1;
        else if(alloc_rdy && alloc_vld) idle <= 1'b0;
        else if(state_all_done        ) idle <= 1'b1;
    end

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)                      active <= 1'b0;
        else if(mshr_state_update_en)   active <= 1'b1;
        else if(state_all_done      )   active <= 1'b0;         
    end

//========================================================
// Cache State Management
//========================================================
//--------------------------
//-------rs state
//--------------------------
logic wr_hsk               ;
logic clear_rd             ;
logic mshr_state_bypass_buf;

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)              mshr_state_bypass_buf <= 1'b0             ;
    else                    mshr_state_bypass_buf <= mshr_state_bypass;
end

assign wr_hsk    = rw_req_vld   && rw_req_rdy                  ;
assign clear_rd  = clear_mshr_rd && mshr_ety_regfile.op_is_read;

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                           state_rw_done <= 1'b1;
    else if(mshr_state_update_en )                       state_rw_done <= 1'b0;
    else if(wr_hsk || clear_rd || mshr_state_bypass_buf) state_rw_done <= 1'b1;   
end
//--------------------------
//-------evict state
//--------------------------
logic pld_is_evict;
assign pld_is_evict = mshr_state_update_en && mshr_state_update_pld.need_evict;

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                      state_evict_sent <= 1'b1;
    else if(pld_is_evict)                           state_evict_sent <= 1'b0;
    else if(evict_req_vld && evict_req_rdy)         state_evict_sent <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                      state_evict_dat_ram_clean <= 1'b1;
    else if(pld_is_evict)                           state_evict_dat_ram_clean <= 1'b0;
    else if(evict_dat_ram_clean_en)                 state_evict_dat_ram_clean <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                      state_evict_done <= 1'b1;
    else if(pld_is_evict)                           state_evict_done <= 1'b0;
    else if(evict_done_en)                          state_evict_done <= 1'b1;
end
//--------------------------
//-------linefill state
//--------------------------
logic pld_is_linefill;

assign pld_is_linefill = mshr_state_update_en && mshr_state_update_pld.need_linefill;

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                        state_linefill_sent <= 1'b1;
    else if(pld_is_linefill)                          state_linefill_sent <= 1'b0;
    else if(downstream_req_vld && downstream_req_rdy) state_linefill_sent <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)                                        state_linefill_done <= 1'b1;
    else if(pld_is_linefill)                          state_linefill_done <= 1'b0;
    else if(linefill_done_en)                         state_linefill_done <= 1'b1;
end

//========================================================
// mshr entry reg file
//========================================================
    always_ff@(posedge clk) begin
        if(mshr_state_update_en) mshr_ety_regfile      <= mshr_state_update_pld[$bits(pack_l1d_mshr_ety_regfile)-1:0];
    end

    genvar i;
    generate for(i=0;i<L1D_MSHR_ENTRY_NUM;i++) begin
        always_ff@(posedge clk) begin
            if(mshr_state_update_en)                hzd_index_way_regfile[i] <= mshr_state_hzd_index_way[i];
            else if(v_release_en_index_way_in[i])   hzd_index_way_regfile[i] <= 1'b0                       ;                              
        end
    end
    endgenerate
    
    generate for(i=0;i<L1D_MSHR_ENTRY_NUM;i++) begin
        always_ff@(posedge clk) begin
            if(mshr_state_update_en)                hzd_evict_tag_regfile[i] <= mshr_state_hzd_evict_tag[i];
            else if(v_release_en_index_way_in[i])   hzd_evict_tag_regfile[i] <= 1'b0                       ;                              
        end
    end
    endgenerate
    
    always_comb begin
        hzd_index        = mshr_ety_regfile.index     ;
        hzd_way          = mshr_ety_regfile.way       ;
        hzd_evict_tag    = mshr_ety_regfile.evict_tag ;
        hzd_index_way_en = index_way_en               ;
        hzd_evict_tag_en = evict_tag_en               ; 
    end

    always_comb begin
        rw_req_pld.way            = mshr_ety_regfile.way       ;
        rw_req_pld.index          = mshr_ety_regfile.index     ;
        rw_req_pld.offset         = mshr_ety_regfile.offset    ;
        rw_req_pld.op_is_read     = mshr_ety_regfile.op_is_read;
        rw_req_pld.wr_data        = mshr_ety_regfile.wr_data   ;
        rw_req_pld.wr_data_be     = mshr_ety_regfile.wr_data_be;
        rw_req_pld.sb_pld         = mshr_ety_regfile.sb_pld    ;
    end
    always_comb begin
        evict_req_pld.tag         = mshr_ety_regfile.evict_tag ;
        evict_req_pld.way         = mshr_ety_regfile.way       ;
        evict_req_pld.index       = mshr_ety_regfile.index     ;
        evict_req_pld.offset      = mshr_ety_regfile.offset    ;
        evict_req_pld.rd_last     = 1'b0                       ;
    end
    
    always_comb begin
        downstream_req_pld.tag    = mshr_ety_regfile.tag       ;
        downstream_req_pld.way    = mshr_ety_regfile.way       ;
        downstream_req_pld.index  = mshr_ety_regfile.index     ;
        downstream_req_pld.offset = mshr_ety_regfile.offset    ;
        downstream_req_pld.sb_pld = mshr_ety_regfile.sb_pld    ;
    end

//========================================================
// behavior
//========================================================
    assign state_all_done      = state_evict_done && state_rw_done && state_linefill_done;
    assign hzd_idx_way_free    = ~|(hzd_index_way_regfile)                               ;
    assign hzd_evict_tag_free  = ~|(hzd_evict_tag_regfile)                               ;
    
    assign index_way_en        = active                                                  ;
    assign evict_tag_en        = !state_evict_done                                       ;
    assign release_index_way_en= index_way_en                                            ;
    assign release_evict_tag_en= evict_tag_en                                            ;

    logic  evict_vld         ;
    logic  linefill_vld      ;
    logic  rw_vld            ;

    assign evict_vld           = !state_evict_sent                                                   ;
    assign linefill_vld        = state_evict_dat_ram_clean && !state_linefill_sent                   ;
    assign rw_vld              = state_evict_dat_ram_clean &&  state_linefill_sent  && !state_rw_done; 
    
    assign alloc_vld           = !idle                                                                         ;
    assign evict_req_vld       = evict_vld    && hzd_idx_way_free                                              ;
    assign downstream_req_vld  = linefill_vld && hzd_evict_tag_free                                            ; 
    assign rw_req_vld          = rw_vld       && hzd_idx_way_free   && !mshr_state_bypass_buf && !clear_rd     ;
                  
endmodule