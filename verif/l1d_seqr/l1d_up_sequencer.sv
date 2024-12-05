// `include "../l1d_seq/l1d_up_sequence.sv"
class l1d_up_sequencer;
    l1d_cfg         l1d_cfg_seqr      ;   
    l1d_up_sequence l1d_up_seq_raw    ;
    mailbox         l1d_up_drv_mbx    ;
    mailbox         l1d_up_ref_mbx    ;
    //new
    function new(input l1d_cfg l1d_cfg_in)               ;
        this.l1d_cfg_seqr          = l1d_cfg_in          ;
        this.l1d_up_seq_raw        = new(2,l1d_cfg_in)   ;
        this.l1d_up_drv_mbx        = new()               ;
        this.l1d_up_ref_mbx        = new()               ;
    endfunction
    
    function set_mbx(input mailbox l1d_up_drv_mbx,input mailbox l1d_up_ref_mbx);
        this.l1d_up_drv_mbx  = l1d_up_drv_mbx            ;
        this.l1d_up_ref_mbx  = l1d_up_ref_mbx            ;
    endfunction

    //task:put different seq into mailbox
    task generate_random_seqr();
        l1d_up_trans        l1d_up_trans1 ;
        if(l1d_cfg_seqr.debug_en) $display("[DEBUG][UP_SEQUENCER] generate random_seqr");
        l1d_up_seq_raw.raw_seq();
        foreach(l1d_up_seq_raw.l1d_up[i]) begin
            l1d_up_drv_mbx.put(l1d_up_seq_raw.l1d_up[i]) ;
            l1d_up_ref_mbx.put(l1d_up_seq_raw.l1d_up[i]) ;
            if(l1d_cfg_seqr.debug_en) begin
                $display("[DEBUG][UP_SEQUENCER][%0t] send SEQ to DRIVER and REF",$time) ;
                // l1d_up_seq_raw.l1d_up[i].display()                                      ;
            end
        end
    endtask;

endclass:l1d_up_sequencer;