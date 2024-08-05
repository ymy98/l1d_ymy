





module l1d_mshr_entry 
    import l1d_package::*;
(
    input                           clk                     ,
    input                           rst_n                   ,

    output                          alloc_vld               ,
    input                           alloc_rdy               ,

    output [L1D_INDEX_WIDTH-1:0]    hzd_index               ,
    output [L1D_TAG_WIDTH-1:0]      hzd_evict_tag           ,
    output                          hzd_en                  ,

    input  [L1D_MSHR_ENTRY_NUM-1:0] v_release_en_in         ,

    input                           mshr_state_update_en    ,
    input pack_l1d_mshr_state       mshr_state_update_pld   ,

    output                          dat_ram_req_vld                 ,
    input                           dat_ram_req_rdy                 ,
    output                          dat_ram_req_pld                 ,

    output                          downstream_req_vld              ,
    input                           downstream_req_rdy              ,
    output                          downstream_req_pld              ,

    input                           evict_dat_ram_clean_en          ,
    input                           evict_done_en                   ,
    input                           linefill_done_en                ,

    output                          release_en
);

    logic state_rw_done             ;
    logic rw_type                   ; // 0: read   1: write

    logic state_linefill_sent       ;
    logic state_linefill_done       ;

    logic state_evict_sent          ;
    logic state_evict_done          ;
    logic state_evict_dat_ram_clean ;

    logic idle;
    logic active;
    logic hazard_free;

    //========================================================
    // Entry State Management
    //========================================================

    // idle ...

    // active ...



    //========================================================
    // Cache State Management
    //========================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_rw_done <= 1'b1;
        else if(mshr_state_update_en)                                       state_rw_done <= ~mshr_state_update_pld.need_rw;
        //else if(dat_ram_req_vld && dat_ram_req_rdy && ~dat_ram_req_pld.req_type[1]) state_rw_done <= 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_evict_sent <= 1'b1;
        else if(mshr_state_update_en)                                       state_evict_sent <= ~mshr_state_update_pld.need_evict;
        //else if(dat_ram_req_vld && dat_ram_req_rdy && dat_ram_req_type.req_type[1])  state_evict_sent <= 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_evict_done <= 1'b1;
        else if(mshr_state_update_en)                                       state_evict_done <= ~mshr_state_update_pld.need_evict;
        else if(evict_done_en)                                              state_evict_done <= 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_evict_dat_ram_clean <= 1'b1;
        else if(mshr_state_update_en)                                       state_evict_dat_ram_clean <= ~mshr_state_update_pld.need_evict;
        else if(evict_dat_ram_clean_en)                                     state_evict_dat_ram_clean <= 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_linefill_sent <= 1'b1;
        else if(mshr_state_update_en)                                       state_linefill_sent <= ~mshr_state_update_pld.need_linefill;
        else if(downstream_req_vld && downstream_req_rdy)                   state_linefill_sent <= 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_linefill_done <= 1'b1;
        else if(mshr_state_update_en)                                       state_linefill_done <= ~mshr_state_update_pld.need_linefill;
        else if(linefill_done_en)                                           state_linefill_done <= 1'b1;
    end


    //========================================================
    // Request Generation
    //========================================================

    logic evict_vld ;
    logic rw_vld    ;

    assign evict_vld = ~state_evict_sent;
    assign rw_vld    = state_linefill_sent && (~state_rw_done);

    assign dat_ram_req_vld = (evict_vld | rw_vld) && hazard_free;
    //assign dat_ram_req_pld = // something


    assign downstream_req_vld = (~state_linefill_sent) && state_evict_dat_ram_clean && hazard_free; 
    //assign downstream_req_pld = //someting


    //========================================================
    // Hzd Checking
    //========================================================


    //hazard_free = //......

endmodule