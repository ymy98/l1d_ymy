// `include "../l1d_drv/l1d_down_driver.sv"
// `include "../l1d_seqr/l1d_down_sequencer.sv"
// `include "../l1d_cfg.sv"
// `include "../l1d_if.sv"
class  l1d_down_agent;
    //===========================
    //--------variables
    //===========================
    //assembly
    l1d_down_driver                 l1d_down_drv    ;
    l1d_down_sequencer              l1d_down_seqr   ;
    l1d_cfg                         l1d_cfg_down_agt;
    //vif
    virtual L1D_downstream_if       l1d_down_vif    ;
    //mailbox
    mailbox                         seqr_2_drv_mbx  ;
    mailbox                         drv_2_seqr_mbx  ;
    mailbox                         to_ref_mbx      ;
    mailbox                         from_seq_mbx    ;
    //===========================
    //--------constructor
    //===========================
    function new(input l1d_cfg l1d_cfg_down_agt);
        this.l1d_cfg_down_agt = l1d_cfg_down_agt        ;
        l1d_down_drv          = new(l1d_cfg_down_agt)   ;
        l1d_down_seqr         = new(l1d_cfg_down_agt)   ;
    endfunction

    function set_mbx(input mailbox to_ref_mbx,input mailbox from_seq_mbx);
        this.to_ref_mbx      = to_ref_mbx                                ;
        this.from_seq_mbx    = from_seq_mbx                              ;
    endfunction

    function connect();
        l1d_down_drv.l1d_down_if = l1d_down_vif                                                         ;
        l1d_down_drv.set_mbx(this.drv_2_seqr_mbx,this.seqr_2_drv_mbx)                                   ;
        l1d_down_seqr.set_mbx(this.from_seq_mbx,this.to_ref_mbx,this.drv_2_seqr_mbx,this.seqr_2_drv_mbx);
    endfunction

    task run();
        fork
            l1d_down_drv.run() ;
            l1d_down_seqr.run();
        join_none
    endtask
endclass:l1d_down_agent