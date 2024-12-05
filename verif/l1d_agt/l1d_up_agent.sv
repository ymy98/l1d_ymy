// `include "../l1d_drv/l1d_up_driver.sv"
// `include "../l1d_mon/l1d_up_mon.sv"
// `include "../l1d_seq/l1d_up_sequence.sv"
// `include "../l1d_seqr/l1d_up_sequencer.sv"
// `include "../l1d_cfg.sv"
// `include "../l1d_if.sv"

class l1d_up_agent;
    //===========================
    //--------variables
    //===========================
    //assembly
    l1d_up_driver           l1d_up_drv      ;
    l1d_up_mon              l1d_up_mon      ;
    l1d_up_sequencer        l1d_up_seqr     ;
    l1d_cfg                 l1d_cfg_up_agt  ;
    
    //vif
    virtual L1D_upstream_if l1d_up_vif      ;
    //mailbox
    mailbox                 l1d_up_seqr_2drv_mbx     ;
    mailbox                 l1d_up_mon_2scb_req_mbx  ;
    mailbox                 l1d_up_mon_2scb_ack_mbx  ;
    mailbox                 l1d_up_seqr_2ref_mbx     ;

    //===========================
    //--------constructor
    //===========================
    function new(input l1d_cfg l1d_cfg_up_agt)      ;
        this.l1d_cfg_up_agt  = l1d_cfg_up_agt       ;
        l1d_up_drv           = new(l1d_cfg_up_agt)  ;
        l1d_up_mon           = new(l1d_cfg_up_agt)  ;
        l1d_up_seqr          = new(l1d_cfg_up_agt)  ;
        l1d_up_seqr_2drv_mbx = new()                ;
    endfunction

    function set_mbx(input mailbox l1d_up_mon_2scb_req_mbx,input mailbox l1d_up_mon_2scb_ack_mbx,input mailbox l1d_up_seqr_2ref_mbx);
        this.l1d_up_mon_2scb_req_mbx = l1d_up_mon_2scb_req_mbx ;
        this.l1d_up_mon_2scb_ack_mbx = l1d_up_mon_2scb_ack_mbx ;
        this.l1d_up_seqr_2ref_mbx    = l1d_up_seqr_2ref_mbx    ;
    endfunction
    //===========================
    //--------task
    //===========================
    function connect();
        l1d_up_drv.l1d_up_vif = this.l1d_up_vif                                       ;
        l1d_up_mon.l1d_up_vif = this.l1d_up_vif                                       ;
        $display("[DEBUG][UP_AGT]pass l1d_up_vif to DRV" )                            ;
        l1d_up_drv.set_mbx(this.l1d_up_seqr_2drv_mbx)                                 ;
        l1d_up_seqr.set_mbx(this.l1d_up_seqr_2drv_mbx,this.l1d_up_seqr_2ref_mbx)      ;
        l1d_up_mon.set_mbx(this.l1d_up_mon_2scb_req_mbx,this.l1d_up_mon_2scb_ack_mbx) ;
    endfunction

    task run();
        fork 
            l1d_up_seqr.generate_random_seqr()  ;
            l1d_up_drv.start_transmiter()       ;
            l1d_up_mon.run()                    ;
        join_none
    endtask
endclass:l1d_up_agent
