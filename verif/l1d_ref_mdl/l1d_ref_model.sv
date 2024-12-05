// `include "l1d_cfg.sv"
// `include "l1d_trans/l1d_mem_trans.sv"
//addr=>32
//data=>256
//wr_be_enable=>32
class l1d_ref_model ;
    //-----cfg
    l1d_cfg                     l1d_cfg_ref_model                  ;
    
    //-----ref_mem
    bit [REQ_DATA_WIDTH-1:0]    ref_mem[bit [VERIF_ADDR_WIDTH-1:0]];
    bit [VERIF_ADDR_WIDTH-1:0]  ref_mem_addr                       ;
    bit [REQ_DATA_WIDTH-1:0]    ref_mem_data                       ;

    //-----trans
    l1d_mem_trans               ref_mem_up_trans                   ;
    l1d_mem_trans               ref_mem_down_trans                 ;
    l1d_mem_trans               ref_mem_scb_trans                  ;
    
    //-----mailbox
    mailbox                     ref_up_mbx                         ;
    mailbox                     ref_scb_mbx                        ;
    mailbox                     ref_from_down_mbx                  ;
    mailbox                     ref_to_down_mbx                    ;
    
    //-----event
    event                       ref_no_data_exist                  ;

    function new(input l1d_cfg l1d_cfg_ref_model,input event ref_no_data_exist);
        this.l1d_cfg_ref_model = l1d_cfg_ref_model;
        this.ref_no_data_exist = ref_no_data_exist;
    endfunction

    function set_mbx(input mailbox ref_up_mbx,mailbox ref_scb_mbx,input mailbox ref_from_down_mbx,input mailbox ref_to_down_mbx);
        this.ref_scb_mbx       = ref_scb_mbx      ;
        this.ref_up_mbx        = ref_up_mbx       ;
        this.ref_from_down_mbx = ref_from_down_mbx;
        this.ref_to_down_mbx   = ref_to_down_mbx  ;
    endfunction

    task read_ref_mem(input bit [VERIF_ADDR_WIDTH-1:0] addr,output bit [REQ_DATA_WIDTH-1:0] data );
        if(ref_mem.exists(addr)) begin 
            if(l1d_cfg_ref_model.debug_en) $display("[DEBUG][REF_MODEL][%0t] data in ref mem",$time)                                                ;
            data   = ref_mem[addr];
        end
        else begin
            if(l1d_cfg_ref_model.debug_en) $display("[DEBUG][REF_MODEL][%0t] no data in ref mem,notify downstream sequence to generate",$time)      ;
            write_to_down(addr);       
            -> ref_no_data_exist  ;
            if(l1d_cfg_ref_model.debug_en) $display("[DEBUG][REF_MODEL][%0t] trigger downstream seq",$time)   ; 
            wait(ref_mem.exists(addr));
            data   = ref_mem[addr]    ;    
        end
    endtask

    function void write_ref_mem(input bit [VERIF_ADDR_WIDTH-1:0] addr,input bit [REQ_DATA_WIDTH-1:0] data);
        ref_mem[addr] = data;
    endfunction

    task write_to_down(input bit [VERIF_ADDR_WIDTH-1:0] addr_in );
        bit[VERIF_ADDR_WIDTH-1:0] addr_mask         ;
        addr_mask = {addr_in[VERIF_ADDR_WIDTH-1:MASK_ADDR_WIDTH],{MASK_ADDR_WIDTH{1'b0}}};
        this.ref_to_down_mbx.put(addr_mask)         ;
    endtask

    task keep_polling_up_mailbox();
        string msg = "ref upstream";
        if(!ref_up_mbx.num()) begin
            ref_up_mbx.get(ref_mem_up_trans);
            if(l1d_cfg_ref_model.debug_en) begin
                $display("[DEBUG][REF_MODEL][%0t] get %s trans",$time,msg);
                ref_mem_up_trans.display(msg);
            end
            ref_mem_scb_trans.op_is_read = ref_mem_up_trans.op_is_read;
            ref_mem_scb_trans.addr       = ref_mem_up_trans.addr      ;
            ref_mem_scb_trans.sb_pld     = ref_mem_up_trans.sb_pld    ;
            if(ref_mem_up_trans.op_is_read) begin
                read_ref_mem(ref_mem_up_trans.addr,ref_mem_scb_trans.data);
                $display("[DEBUG][REF_MODEL][%0t][READ] finish %s trans",$time,msg);
            end
            else begin
                write_ref_mem(ref_mem_up_trans.addr,ref_mem_up_trans.data);
                ref_to_down_mbx.put(ref_mem_up_trans.addr)                ;
                ref_mem_scb_trans.data     = ref_mem_up_trans.data        ;
                $display("[DEBUG][REF_MODEL][%0t][WRITE] finish %s trans",$time,msg);
            end
            ref_scb_mbx.put(ref_mem_scb_trans);
        end
    endtask

    task keep_polling_down_mailbox();
        string msg = "ref downstream";
        if(!ref_from_down_mbx.num()) begin
            ref_from_down_mbx.get(ref_mem_down_trans);
            if(l1d_cfg_ref_model.debug_en) begin
                $display("[DEBUG][REF_MODEL][%0t] get %s trans",$time,msg);
                ref_mem_down_trans.display(msg);
            end
            if(ref_mem_down_trans.op_is_read) begin
                $display("[DEBUG][REF_MODEL][%0t] FAIL:down string read to reference model is forbidden now",$time,msg);
            end
            else begin
                $display("[DEBUG][REF_MODEL][%0t] get $s trans",$time,msg);
                write_ref_mem(ref_mem_down_trans.addr,ref_mem_down_trans.data);
            end
        end
    endtask

    task run();
    fork
        forever begin
            fork 
                keep_polling_up_mailbox();
                keep_polling_down_mailbox();
            join
        end
    join_none
    endtask
endclass:l1d_ref_model