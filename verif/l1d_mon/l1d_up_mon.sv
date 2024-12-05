// `include "../l1d_trans/l1d_up_trans.sv"
// `include "../l1d_trans/l1d_mem_trans.sv"
// `include "../l1d_if.sv"

class l1d_up_mon;
    virtual L1D_upstream_if     l1d_up_vif                 ;
    l1d_up_trans                l1d_req_dut_trans           ;
    l1d_mem_trans               l1d_ack_dut_trans          ;
    mailbox                     l1d_up_req_dut_mbx         ;
    mailbox                     l1d_up_ack_dut_mbx         ;
    l1d_cfg                     l1d_cfg_mon                ;
    
    function new(input l1d_cfg l1d_cfg_mon)   ;
        this.l1d_cfg_mon = l1d_cfg_mon        ;
    endfunction

    function set_mbx(input mailbox l1d_up_req_dut_mbx,input mailbox l1d_up_ack_dut_mbx);
        this.l1d_up_req_dut_mbx= l1d_up_req_dut_mbx;
        this.l1d_up_ack_dut_mbx= l1d_up_ack_dut_mbx;
    endfunction

    task run();
        fork
            forever begin
                @(posedge l1d_up_vif.clk);
                fork    
                if(l1d_up_vif.upstream_req_vld && l1d_up_vif.upstream_req_rdy) begin
                    if(l1d_cfg_mon.debug_en) $display("[DEBUG][UPSTREAM_MON][%0t] get upstream REQ pld",$time);
                    get_rep_trans(l1d_up_vif,l1d_req_dut_trans);
                    l1d_req_dut_trans.display("upstream request ");
                    l1d_up_req_dut_mbx.put(l1d_req_dut_trans);
                    if(l1d_cfg_mon.debug_en) $display("[DEBUG][UPSTREAM_MON][%0t] put upstream REQ pld to SCB",$time);
                end
                if(l1d_up_vif.upstream_ack_en) begin
                    if(l1d_cfg_mon.debug_en) $display("[DEBUG][UPSTREAM_MON][%0t] get upstream ACK pld",$time);
                    get_ack_trans(l1d_up_vif,l1d_ack_dut_trans);
                    l1d_ack_dut_trans.display("upstream ack ");
                    l1d_up_ack_dut_mbx.put(l1d_ack_dut_trans);
                    if(l1d_cfg_mon.debug_en) $display("[DEBUG][UPSTREAM_MON][%0t] put upstream ACK pld to SCB",$time);

                end
                join
            end
        join_none
        // 
    endtask
    
    function get_rep_trans(input virtual L1D_upstream_if l1d_up_vif,output l1d_up_trans l1d_up_trans_out);
        l1d_up_trans_out.pld                = l1d_up_vif.upstream_req_pld   ;
        l1d_up_trans_out.cancel_last_trans  = l1d_up_vif.cancel_last_trans  ;
        l1d_up_trans_out.clear_mshr_rd      = l1d_up_vif.clear_mshr_rd      ;
    endfunction


    function get_ack_trans(input virtual L1D_upstream_if l1d_up_vif,output l1d_mem_trans l1d_mem_trans_out);
        bit [MASK_ADDR_WIDTH-1:0]     mask_addr   ;
        bit [L1D_TAG_WIDTH-1:0]       tag         ;
        bit [L1D_INDEX_WIDTH-1:0]     index       ;
        bit [L1D_OFFSET_WIDTH-1:0]    offset      ;

        mask_addr                           = {MASK_ADDR_WIDTH{1'b0}}           ;
        tag                                 = l1d_up_vif.upstream_req_pld.tag   ;
        index                               = l1d_up_vif.upstream_req_pld.index ;
        offset                              = l1d_up_vif.upstream_req_pld.offset;
        
        // l1d_mem_trans_out.addr              = {tag,index,offset,mask_addr}      ;
        l1d_mem_trans_out.data              = l1d_up_vif.upstream_ack_dat       ;
        l1d_mem_trans_out.addr              = {tag,index,offset,mask_addr}      ;
        l1d_mem_trans_out.op_is_read        = 1'b1                              ;
        l1d_mem_trans_out.sb_pld            = l1d_up_vif.upstream_sb_pld        ;
    endfunction

endclass:l1d_up_mon