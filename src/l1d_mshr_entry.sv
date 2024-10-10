module l1d_mshr_entry 
    import l1d_package::*;
(
    input  logic                    clk                             ,
    input  logic                    rst_n                           ,
        
    output logic                    alloc_vld                       ,
    input  logic                    alloc_rdy                       ,
        
    output [L1D_INDEX_WIDTH-1:0]    hzd_index                       ,
    output [L1D_WAY_NUM_WIDTH-1:0]  hzd_way                         ,
    output [L1D_TAG_WIDTH-1:0]      hzd_evict_tag                   ,
    output logic                    hzd_index_way_en                ,
    output logic                    hzd_evict_tag_en                ,

    input  [L1D_MSHR_ENTRY_NUM-1:0] v_release_en_index_way_in       ,
    input  [L1D_MSHR_ENTRY_NUM-1:0] v_release_en_evict_tag_in       ,

    input  logic                    mshr_state_bypass               ,
    input  logic                    mshr_state_update_en            ,
    input  pack_l1d_mshr_state      mshr_state_update_pld           ,

    output logic                    dat_ram_req_vld                 ,
    input  logic                    dat_ram_req_rdy                 ,
    output pack_data_ram_req_pld    dat_ram_req_pld                 ,

    output logic                    evict_req_vld                   ,
    input  logic                    evict_req_rdy                   ,
    output pack_evict_req_pld       evict_req_pld                   ,

    output logic                    downstream_req_vld              ,
    input  logic                    downstream_req_rdy              ,
    output pack_downstream_req_pld  downstream_req_pld              ,

    input  logic                    evict_dat_ram_clean_en          ,
    input  logic                    evict_done_en                   ,
    input  logic                    linefill_done_en                ,

    output logic                    release_index_way_en            ,
    output logic                    release_evict_tag_en            ,
    output pack_mshr_dat_addr       v_mshr_data_addr         
);

    logic state_rw_done                                                             ;
    logic state_linefill_sent                                                       ;
    logic state_linefill_done                                                       ;

    logic state_evict_sent                                                          ;
    logic state_evict_done                                                          ;
    logic state_evict_dat_ram_clean                                                 ;

    logic idle                                                                      ;
    logic active                                                                    ;
    logic hzd_index_way_free                                                        ;
    logic hzd_evict_tag_free                                                        ;
                                                                                            
    logic state_all_done                                                            ;

    assign state_all_done = state_rw_done && state_linefill_done && state_evict_done;

    //========================================================
    // Entry State Management
    //========================================================

    //preallocatable    : idle 
    //mshr_update arrive: active

    // idle ... 
    always_ff @( posedge clk or negedge rst_n ) begin 
        if(~rst_n)                                      idle <= 1'b1;
        else if(alloc_rdy)                              idle <= 1'b0;
        else if(state_all_done)                         idle <= 1'b1;
    end
    // no hazrd active
    // active ...
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      active <= 1'b0;
        else if(mshr_state_update_en)                   active <= 1'b1;
        else if(state_all_done)                         active <= 1'b0;
    end 

    //========================================================
    // Cache State Management
    //========================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_rw_done <= 1'b1                                         ;
        else if(mshr_state_update_en)                                       state_rw_done <= mshr_state_bypass                            ;
        else if(dat_ram_req_vld && dat_ram_req_rdy)                         state_rw_done <= 1'b1                                         ;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_evict_sent <= 1'b1                                      ;
        else if(mshr_state_update_en)                                       state_evict_sent <= ~mshr_state_update_pld.need_evict         ;
        else if(evict_req_vld && evict_req_rdy)                             state_evict_sent <= 1'b1                                      ;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_evict_done <= 1'b1                                      ;
        else if(mshr_state_update_en)                                       state_evict_done <= ~mshr_state_update_pld.need_evict         ;
        else if(evict_done_en)                                              state_evict_done <= 1'b1                                      ;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_evict_dat_ram_clean <= 1'b1                             ;
        else if(mshr_state_update_en)                                       state_evict_dat_ram_clean <= ~mshr_state_update_pld.need_evict;
        else if(evict_dat_ram_clean_en)                                     state_evict_dat_ram_clean <= 1'b1                             ;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_linefill_sent <= 1'b1                                   ;
        else if(mshr_state_update_en)                                       state_linefill_sent <= ~mshr_state_update_pld.need_linefill   ;
        else if(downstream_req_vld && downstream_req_rdy)                   state_linefill_sent <= 1'b1                                   ;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_linefill_done <= 1'b1                                   ;
        else if(mshr_state_update_en)                                       state_linefill_done <= ~mshr_state_update_pld.need_linefill   ;
        else if(linefill_done_en)                                           state_linefill_done <= 1'b1                                   ;
    end


    //========================================================
    // Request Generation
    //========================================================
    logic evict_vld     ;
    logic linefill_vld  ;
    logic rw_vld        ;

    assign evict_vld          = ~state_evict_sent                                                             ;
    assign linefill_vld       = (~state_linefill_sent) && state_evict_dat_ram_clean                           ;
    assign rw_vld             = (~state_rw_done)       && state_linefill_sent && state_evict_dat_ram_clean    ;

    assign evict_req_vld      = evict_vld    && hzd_index_way_free                                            ;
    assign dat_ram_req_vld    = rw_vld       && hzd_evict_tag_free && hzd_index_way_free                      ;
    assign downstream_req_vld = (linefill_vld || evict_vld) && hzd_evict_tag_free && hzd_index_way_free       ; 

    assign alloc_vld          = idle         ;
    //========================================================
    // Hzd Checking
    //========================================================

    logic  [L1D_MSHR_ENTRY_NUM-1:0]     hzd_index_way_line;
    logic  [L1D_MSHR_ENTRY_NUM-1:0]     hzd_evict_tag_line;
    genvar i;
    generate for(i=0;i<L1D_MSHR_ENTRY_NUM;i++)begin
        always_ff@(posedge clk or negedge rst_n) begin
            if(~rst_n)                                      hzd_index_way_line[i] <= 1'b0                                            ;
            else if(mshr_state_update_en)                   hzd_index_way_line[i] <= mshr_state_update_pld.mshr_hzd_index_way_line[i];
            else if(v_release_en_index_way_in[i])           hzd_index_way_line[i] <= 1'b0                                            ;
        end
    end
    endgenerate
    assign hzd_index_way_free = |hzd_index_way_line;

    generate for(i=0;i<L1D_MSHR_ENTRY_NUM;i++)begin
        always_ff@(posedge clk or negedge rst_n) begin
            if(~rst_n)                                      hzd_evict_tag_line[i] <= 1'b0                                            ;
            else if(mshr_state_update_en)                   hzd_evict_tag_line[i] <= mshr_state_update_pld.mshr_hzd_evict_tag_line[i];
            else if(v_release_en_evict_tag_in[i])           hzd_evict_tag_line[i] <= 1'b0                                            ;
        end
    end
    endgenerate
    assign hzd_evict_tag_free = |hzd_evict_tag_line;

    assign release_index_way_en = ~active          ;
    assign release_evict_tag_en = state_evict_done ;
    assign hzd_index_way_en     = active           ;
    assign hzd_evict_tag_en     = ~state_evict_done;

    //========================================================
    // mshr entry reg file
    //========================================================
    pack_l1d_mshr_entry_regfile mshr_entry_regfile;
        
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                        begin                                       
            mshr_entry_regfile                  <= {$bits(pack_l1d_mshr_entry_regfile){1'b0}}  ;
        end
        else if(mshr_state_update_en)                     begin         
            mshr_entry_regfile.rw_type          <= mshr_state_update_pld.need_rw               ;
            mshr_entry_regfile.index            <= mshr_state_update_pld.index                 ;
            mshr_entry_regfile.new_tag          <= mshr_state_update_pld.new_tag               ;
            mshr_entry_regfile.evict_tag        <= mshr_state_update_pld.evict_tag             ;
            mshr_entry_regfile.offset           <= mshr_state_update_pld.offset                ;
            mshr_entry_regfile.way              <= mshr_state_update_pld.way                   ;
            mshr_entry_regfile.wr_data          <= mshr_state_update_pld.wr_data               ;
            mshr_entry_regfile.wr_data_byte_en  <= mshr_state_update_pld.wr_data_byte_en       ;
            mshr_entry_regfile.wr_sb_pld        <= mshr_state_update_pld.wr_sb_pld             ;
        end
    end
    assign hzd_index     = mshr_entry_regfile.index    ;
    assign hzd_way       = mshr_entry_regfile.way      ;
    assign hzd_evict_tag = mshr_entry_regfile.evict_tag;

    assign v_mshr_data_addr.index = mshr_entry_regfile.index ;
    assign v_mshr_data_addr.way   = mshr_entry_regfile.way   ;
    //========================================================
    // pld decoder
    //========================================================
    assign dat_ram_req_pld.rw_type             = mshr_entry_regfile.rw_type            ;
    assign dat_ram_req_pld.index               = mshr_entry_regfile.index              ;
    assign dat_ram_req_pld.offset              = mshr_entry_regfile.offset             ;
    assign dat_ram_req_pld.way                 = mshr_entry_regfile.way                ;
    assign dat_ram_req_pld.wr_data             = mshr_entry_regfile.wr_data            ;
    assign dat_ram_req_pld.wr_data_byte_en     = mshr_entry_regfile.wr_data_byte_en    ;
    assign dat_ram_req_pld.wr_sb_pld           = mshr_entry_regfile.wr_sb_pld          ;
    assign dat_ram_req_pld.wr_data_part        = ~(&mshr_entry_regfile.wr_data_byte_en);

    assign evict_req_pld.index                 = mshr_entry_regfile.index              ;
    assign evict_req_pld.offset                = mshr_entry_regfile.offset             ;
    assign evict_req_pld.way                   = mshr_entry_regfile.way                ;
    assign evict_req_pld.wr_sb_pld             = mshr_entry_regfile.wr_sb_pld          ;
      
    assign downstream_req_pld.index            = mshr_entry_regfile.index              ;
    assign downstream_req_pld.way              = mshr_entry_regfile.way                ;
    assign downstream_req_pld.tag              = mshr_entry_regfile.new_tag            ;
    assign downstream_req_pld.offset           = mshr_entry_regfile.offset             ;
    assign downstream_req_pld.evict            = evict_vld                             ;

endmodule