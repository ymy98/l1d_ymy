// import l1d_verif_package::*;
// `include "../l1d_trans/l1d_mem_trans.sv"
// `include "../l1d_cfg.sv"
class l1d_down_sequence;
    //cfg
    l1d_cfg                     l1d_cfg_seq                               ;
    //trans
    l1d_mem_trans               l1d_rand_trans_bundle[L1D_OFFSET_NUM]     ;
    //-----event
    event                       ref_no_data_exist                         ;
    bit [VERIF_ADDR_WIDTH-1:0]  ref_addr_in                               ;
    //-----mailbox to sequencer       
    mailbox                     seq_to_seqr_mbx                           ;
    mailbox                     ref_to_down_mbx                           ;

    function new(input l1d_cfg l1d_cfg_in,input event ref_no_data_exist)  ;
        this.l1d_cfg_seq        = l1d_cfg_in         ;
        this.ref_no_data_exist  = ref_no_data_exist  ;
    endfunction

    function set_mbx(input mailbox seq_to_seqr_mbx,input mailbox ref_to_down_mbx);
        this.seq_to_seqr_mbx = seq_to_seqr_mbx;
        this.ref_to_down_mbx = ref_to_down_mbx;
    endfunction
    
    function ref_event_trigger(input [VERIF_ADDR_WIDTH-1:0] addr_in);
        bit [L1D_OFFSET_WIDTH-1:0]                  offset          ;
        bit [L1D_OFFSET_WIDTH+MASK_ADDR_WIDTH-1:0]  addr_offset     ;
        l1d_mem_trans                               l1d_rand_trans  ;

        offset = {L1D_OFFSET_WIDTH{1'b0}}     ;

        for(int i=0;i<L1D_OFFSET_NUM;i++) begin
            addr_offset = offset<< MASK_ADDR_WIDTH;
            l1d_rand_trans.randomize with {
                op_is_read == 1'b0; 
                addr       == {addr_in[VERIF_ADDR_WIDTH-1:L1D_OFFSET_WIDTH+MASK_ADDR_WIDTH], addr_offset};
            };        
            this.l1d_rand_trans_bundle[i] = l1d_rand_trans;
            addr_offset = addr_offset+ 1'b1;
        end

    endfunction

    task write_to_seqr();
        for(int i=0;i<L1D_OFFSET_NUM;i++) begin
            this.ref_to_down_mbx.put(this.l1d_rand_trans_bundle[i]);
        end
    endtask

    task run();
    fork
        forever begin
            @(ref_no_data_exist) begin
                ref_to_down_mbx.get(ref_addr_in);
                if(ref_event_trigger(ref_addr_in)) begin
                    if(l1d_cfg_seq.debug_en)  $display("[DEBUG][DOWN_SEQUENCE][%0t] begin to generate data of %b",$time,ref_addr_in);
                    write_to_seqr();
                end
                else begin
                    if(l1d_cfg_seq.debug_en)  $display("[DEBUG][DOWN_SEQUENCE][%0t] fail to generate data of %b",$time,ref_addr_in);
                end
            end
        end
    join_none
    endtask

endclass