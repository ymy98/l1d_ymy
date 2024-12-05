import l1d_verif_package::*;
`include "l1d_cfg.sv"
`include "l1d_if.sv"
`include "l1d_trans/l1d_up_trans.sv"
`include "l1d_trans/l1d_mem_trans.sv"
`include "l1d_seq/l1d_down_sequence.sv"
`include "l1d_seq/l1d_up_sequence.sv"
`include "l1d_seqr/l1d_down_sequencer.sv"
`include "l1d_seqr/l1d_up_sequencer.sv"
`include "l1d_drv/l1d_down_driver.sv"
`include "l1d_drv/l1d_up_driver.sv"
`include "l1d_mon/l1d_up_mon.sv"
`include "l1d_ref_mdl/l1d_ref_model.sv"
`include "l1d_scb/l1d_scoreboard.sv"
`include "l1d_agt/l1d_down_agent.sv"
`include "l1d_agt/l1d_up_agent.sv"

class l1d_env;
    //===========================
    //--------variables
    //===========================
    //cfg
    l1d_cfg                         l1d_cfg_env         ;
    //assembly          
    l1d_up_agent                    l1d_up_agt          ;
    l1d_down_agent                  l1d_down_agt        ;
    l1d_ref_model                   l1d_ref_mdl         ;
    l1d_scoreboard                  l1d_scb             ;
    l1d_down_sequence               l1d_down_seq        ;
    //mailbox       
    mailbox                         down_agt_2_ref_mbx  ;
    mailbox                         down_seq_2_agt_mbx  ;
    mailbox                         up_agt_2_scb_req_mbx;
    mailbox                         up_agt_2_scb_ack_mbx;
    mailbox                         up_agt_2_ref_mbx    ;
    mailbox                         ref_2_down_seq_mbx  ;
    mailbox                         ref_2_scb_mbx       ;
    //vif
    virtual L1D_downstream_if       l1d_down_vif        ;
    virtual L1D_upstream_if         l1d_up_vif          ;
    //event
    event                           ref_no_data_exist   ;

    function new(input l1d_cfg l1d_cfg_env);
        this.l1d_cfg_env     = l1d_cfg_env                       ; 
        l1d_up_agt           = new(l1d_cfg_env)                  ;
        l1d_down_agt         = new(l1d_cfg_env)                  ;
        l1d_ref_mdl          = new(l1d_cfg_env,ref_no_data_exist);
        l1d_scb              = new(l1d_cfg_env)                  ;
        l1d_down_seq         = new(l1d_cfg_env,ref_no_data_exist);
        up_agt_2_scb_req_mbx = new()                             ;
        up_agt_2_scb_ack_mbx = new()                             ;
        up_agt_2_ref_mbx     = new()                             ;
        down_agt_2_ref_mbx   = new()                             ;
        down_seq_2_agt_mbx   = new()                             ;
        ref_2_down_seq_mbx   = new()                             ;
        ref_2_scb_mbx        = new()                             ;
    endfunction

    function connect();
        //set virtual interface
        l1d_down_agt.l1d_down_vif = l1d_down_vif                                                    ;
        l1d_up_agt.l1d_up_vif     = l1d_up_vif                                                      ;
        $display("[DEBUG][ENV]pass l1d_up_vif to AGT");
        //set mailbox
        l1d_up_agt.set_mbx(up_agt_2_scb_req_mbx, up_agt_2_scb_ack_mbx, up_agt_2_ref_mbx)            ;
        l1d_down_agt.set_mbx(down_agt_2_ref_mbx, down_seq_2_agt_mbx)                                ;
        l1d_ref_mdl.set_mbx(up_agt_2_ref_mbx, ref_2_scb_mbx, down_agt_2_ref_mbx, ref_2_down_seq_mbx);
        l1d_scb.set_mbx(up_agt_2_scb_req_mbx,up_agt_2_scb_ack_mbx,ref_2_scb_mbx)                    ;
        l1d_down_seq.set_mbx(down_seq_2_agt_mbx, ref_2_down_seq_mbx)                                ;
        //connect 
        l1d_up_agt.connect()                                                                        ;
        l1d_down_agt.connect()                                                                      ;
    endfunction
    
    task run();
        @(posedge this.l1d_up_vif.clk);
        $display("[DEBUG][ENV]%0t detect posedge clk",$time);
        l1d_up_agt.run()    ;
        fork
            l1d_down_seq.run()  ;
            l1d_down_agt.run()  ;
            l1d_up_agt.run()    ;
            l1d_scb.run()       ;
            l1d_ref_mdl.run()   ;
        join_none
    endtask
endclass:l1d_env