// `include "../l1d_trans/l1d_up_trans.sv"
// `include "../l1d_if.sv"
// `include "../l1d_cfg.sv"

class l1d_up_driver;
    l1d_up_trans            l1d_up_trans_drv       ;
    mailbox                 l1d_up_seq_mbx         ;
    virtual L1D_upstream_if l1d_up_vif             ;
    l1d_cfg                 l1d_cfg_drv            ;

    function new(input l1d_cfg l1d_cfg_in);
        this.l1d_up_trans_drv   = new()            ;    
        this.l1d_cfg_drv        = l1d_cfg_in       ;
    endfunction

    function set_mbx(input mailbox l1d_up_seq_mbx) ;
        this.l1d_up_seq_mbx = l1d_up_seq_mbx       ;
        
    endfunction

    task start_transmiter();
        int i=0;
        fork
            forever begin
                if(!l1d_up_seq_mbx.num()) begin
                    if(l1d_cfg_drv.debug_en) $display("[DEBUG][UPSTREAM_DRIVER][%0t] Start to listen req mailbox",$time);
                    if(l1d_cfg_drv.debug_en) $display("[DEBUG][UPSTREAM_DRIVER][%0t] Start to transmit pld",$time)      ;
                    l1d_up_seq_mbx.peek(l1d_up_trans_drv);
                    l1d_up_vif.upstream_req_vld          <= 1'b1                              ;
                    l1d_up_vif.upstream_req_pld          <= l1d_up_trans_drv.pld              ;
                    l1d_up_vif.cancel_last_trans         <= l1d_up_trans_drv.cancel_last_trans;
                    l1d_up_vif.clear_mshr_rd             <= l1d_up_trans_drv.clear_mshr_rd    ;
                    l1d_up_vif.upstream_req_addr_mask    <= l1d_up_trans_drv.pld.mask_addr    ;
                    do @(posedge l1d_up_vif.clk); while(!(l1d_up_vif.upstream_req_vld && l1d_up_vif.upstream_req_rdy));
                    l1d_up_seq_mbx.get(l1d_up_trans_drv);
                    if(l1d_cfg_drv.debug_en) begin
                        $display("[DEBUG][UPSTREAM_DRIVER][%0t] Start to transmit pld[%d]",$time,i)  ;
                        // l1d_up_trans_drv.display("[DEBUG][UPSTREAM_DRIVER]")                   ;
                    end
                    i=i+1;
                end
                else begin
                    @(posedge l1d_up_vif.clk);
                    if(l1d_cfg_drv.debug_en) $display("[DEBUG][UPSTREAM_DRIVER][%0t] get no trans from seqr mbx",$time);
                end
            end
        join_none
    endtask
endclass:l1d_up_driver
