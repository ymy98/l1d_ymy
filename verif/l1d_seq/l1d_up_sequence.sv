// `include "../l1d_trans/l1d_up_trans.sv"
// `include "../l1d_cfg.sv"
class l1d_up_sequence;
    l1d_up_trans l1d_up[]   ;  
    int          num        ;
    l1d_cfg      l1d_cfg_seq;
    function new(input int num,input l1d_cfg l1d_cfg_in);
            this.l1d_up      = new[num]  ; 
            this.num         = num       ;
            this.l1d_cfg_seq = l1d_cfg_in;
            assert(this.l1d_cfg_seq!=null);
            foreach(this.l1d_up[i]) begin
                this.l1d_up[i] = new();
            end
    endfunction

    function void raw_seq();
        automatic pack_l1d_verif_tag_req write_pld;
        if(num%2!=0) begin
            $display("!!!!!!Sequence build fail in RAW test!!!!!!");
            $stop;
        end
        for(int i=0;i<num;i++) begin
            if(i%2==0) begin
                if(l1d_cfg_seq.debug_en) $display("[DEBUG][UP_SEQ] %0t generate seq[%d]",$time,i);
                apply_randomization(l1d_up[i],1);
                // l1d_up[i].display("in up seq,after randomization ");
                write_pld = l1d_up[i].pld;
            end
            else begin
                if(l1d_cfg_seq.debug_en) $display("[DEBUG][UP_SEQ] %0t generate seq[%d]",$time,i);
                apply_randomization(l1d_up[i],i);
                l1d_up[i].pld.offset     = write_pld.offset;
                l1d_up[i].pld.op_is_read = 1'b1;
                // l1d_up[i].display("in up seq,after randomization ");
            end
        end
    endfunction

    function void apply_randomization(input l1d_up_trans trans, input int i);
        if(this.l1d_cfg_seq.debug_en) begin
            if (trans.randomize()) begin
                if (trans.pld.op_is_read) begin
                    if(l1d_cfg_seq.debug_en) $display("[DEBUG][UP_SEQ] %0t read seq randomization[%d]",$time,i);
                end else begin
                    if(l1d_cfg_seq.debug_en) $display("[DEBUG][UP_SEQ] %0t write seq randomization[%d]",$time,i);
                end
            end 
            else begin
                $display("Randomization of transaction %d failed.", i);
            end
        end
    endfunction
endclass:l1d_up_sequence
