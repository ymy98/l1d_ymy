// import l1d_verif_package::*;
// import l1d_package::*;
// `include "../l1d_trans/l1d_mem_trans.sv"
// `include "../l1d_if.sv"
// `include "../l1d_cfg.sv"
class l1d_down_driver;
    //===========================
    //--------variables
    //===========================
    //cfg
    l1d_cfg                         l1d_cfg_drv                           ;
    //trans
    l1d_mem_trans                   to_seqr_trans                         ;
    l1d_mem_trans                   from_seqr_trans                       ;
    //mailbox                                     
    mailbox                         to_seqr_mbx                           ;
    mailbox                         from_seqr_mbx                         ;
    //associated array to map address and id
    #TODO: DELETE drv_mem;FUNTION TO TASK
    pack_l1d_down_drv_pld           drv_mem[bit [VERIF_ADDR_WIDTH-1:0]]   ; 
    // pack_l1d_down_drv_pld           drv_mem[bit [VERIF_ADDR_WIDTH-1:0]][$];
    //virtual interface
    virtual L1D_downstream_if       l1d_down_if                           ;

    //===========================
    //--------constructor
    //===========================
    function new(input l1d_cfg l1d_cfg_drv);
        this.l1d_cfg_drv = l1d_cfg_drv     ;
    endfunction

    function set_mbx(input mailbox to_seqr_mbx,input mailbox from_seqr_mbx);
        this.to_seqr_mbx   = to_seqr_mbx    ;
        this.from_seqr_mbx = from_seqr_mbx  ;
    endfunction

    //===========================
    //--------task
    //===========================
    //receive req from driver,and communicate with seqr,and update map
    task req_from_dut();
        pack_l1d_down_drv_pld         wr_dut_pld                    ;
        bit [VERIF_ADDR_WIDTH-1:0]    wr_addr                       ;
        pack_l1d_down_drv_pld         rd_dut_pld                    ;
        bit [VERIF_ADDR_WIDTH-1:0]    rd_addr                       ;
        fork
            forever begin
                @(posedge l1d_down_if.clk) begin
                    //write
                    if(l1d_down_if.downstream_evict_vld && l1d_down_if.downstream_evict_rdy) begin
                        map_if2pld(l1d_down_if,wr_dut_pld,wr_addr)    ;
                        //TODO:mbx copy                                                                                                      
                        to_seqr_trans.addr       = wr_addr                                                                                                                  ;
                        to_seqr_trans.op_is_read = 1'b0                                                                                                                     ;
                        to_seqr_trans.data       = l1d_down_if.downstream_evict_pld.wr_data                                                                                 ;
                        to_seqr_mbx.put(to_seqr_trans)                                                                                                                      ;
                        if(l1d_cfg_drv.debug_en) $display("[DEBUG][DOWNSTREAM_DRIVER][%0t] Get EVICT pld from DUT and write to SEQR",$time)                                 ;
                        if(l1d_cfg_drv.debug_en) $display("[DEBUG][DOWNSTREAM_DRIVER][%0t] addr is %b,data is %b",$time,wr_addr,l1d_down_if.downstream_evict_pld.wr_data )  ;
                    end
                    //read
                    //TODO:TWO TASK FOR EVICT AND LINEFILL,CACHELINT UNIT
                    if(l1d_down_if.downstream_req_vld && l1d_down_if.downstream_req_rdy) begin
                        map_if2pld(l1d_down_if,rd_dut_pld,rd_addr)                                                                                                          ;
                        to_seqr_trans.addr       = rd_addr                                                                                                                  ;
                        to_seqr_trans.op_is_read = 1'b1                                                                                                                     ;
                        rd_dut_pld               = drv_mem[rd_addr]                                                                                                         ;
                        to_seqr_mbx.put(to_seqr_trans)                                                                                                                      ;
                        if(l1d_cfg_drv.debug_en) $display("[DEBUG][DOWNSTREAM_DRIVER][%0t] Get LINEFILL pld from DUT and read from SEQR",$time)                             ;
                        if(l1d_cfg_drv.debug_en) $display("[DEBUG][DOWNSTREAM_DRIVER][%0t] addr is %b",$time,rd_addr)                                                       ;
                    end
                end
            end
        join_none
    endtask
    
    //generate rsp to driver,through trans from seqr
    task rsp_to_dut();
        pack_l1d_down_drv_pld         rsp_seqr_pld          ;
        bit [VERIF_ADDR_WIDTH-1:0]    rsp_seqr_addr         ;
        int                           num                   ;
        num = 0;
        fork
            forever begin
                if(from_seqr_mbx.num()!=0) begin
                    from_seqr_mbx.peek(from_seqr_trans)           ;
                    rsp_seqr_addr = from_seqr_trans.addr          ;
                    rsp_seqr_pld  = drv_mem[rsp_seqr_addr]        ;
                    //TODO:TRANSACTION CACHE LINE SIZE
                    l1d_down_if.downstream_rsp_vld          <= 1'b1         ;
                    l1d_down_if.downstream_rsp_pld.way      <=  rsp_seqr_pld.way                                                                                     ;
                    l1d_down_if.downstream_rsp_pld.index    <=  rsp_seqr_addr[L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH+MASK_ADDR_WIDTH-1 : L1D_OFFSET_WIDTH+MASK_ADDR_WIDTH] ;
                    l1d_down_if.downstream_rsp_pld.offset   <=  rsp_seqr_addr[L1D_OFFSET_WIDTH+MASK_ADDR_WIDTH-1 : MASK_ADDR_WIDTH]                                  ;
                    l1d_down_if.downstream_rsp_pld.sb_pld   <=  rsp_seqr_pld.sb_pld                                                                                  ;
                    l1d_down_if.downstream_rsp_pld.wr_data  <=  from_seqr_trans.data                                                                                 ;
                    if(num == L1D_OFFSET_WIDTH) begin
                        num=0;
                        l1d_down_if.downstream_rsp_pld.wr_last  <= 1'b1; 
                    end
                    else begin
                        num=num+1;
                        l1d_down_if.downstream_rsp_pld.wr_last  <=  1'b0;
                    end
                    from_seqr_mbx.get(from_seqr_trans)           ;
                    if(l1d_cfg_drv.debug_en) $display("[DEBUG][DOWNSTREAM_DRIVER][%0t] Get read rsp from SEQR",$time);
                    from_seqr_trans.display();
                    @(posedge l1d_down_if.clk);
                end
                else
                begin
                    l1d_down_if.downstream_rsp_vld          <= 1'b0        ;
                    @(posedge l1d_down_if.clk);
                end
            end
        join_none
    endtask

    task map_if2pld(input virtual L1D_downstream_if down_if, output pack_l1d_down_drv_pld pld_out, output bit [VERIF_ADDR_WIDTH-1:0] addr);
        bit [L1D_TAG_WIDTH-1:0]       tag         ;
        bit [L1D_INDEX_WIDTH-1:0]     index       ;
        bit [L1D_OFFSET_WIDTH-1:0]    offset      ;
        bit [MASK_ADDR_WIDTH-1:0]     mask_addr   ;

        pld_out.mshr_id = down_if.downstream_req_id         ;
        pld_out.sb_pld  = down_if.downstream_req_pld.sb_pld ;
        pld_out.way     = down_if.downstream_req_pld.way    ;
        tag             = down_if.downstream_req_pld.tag    ;
        index           = down_if.downstream_req_pld.index  ;
        offset          = down_if.downstream_req_pld.offset ;
        mask_addr       = {MASK_ADDR_WIDTH{1'b0}}           ;
        addr            = {tag,index,offset,mask_addr}      ;
    endtask
    
    task generate_aon_req_rdy();
        l1d_down_if.downstream_req_rdy = 1'b1;
    endtask

    //===========================
    //--------main task
    //===========================
    task run();
        fork
            req_from_dut()          ;
            rsp_to_dut()            ;
            generate_aon_req_rdy()  ;
        join_none
    endtask

endclass:l1d_down_driver