// `include "l1d_trans/l1d_mem_trans.sv"
// `include "l1d_trans/l1d_up_trans.sv"
// `include "l1d_cfg.sv"

//=======================================================================================
//--------scoreboard function:
//--------1.monitor read rsp from dut and ref
//--------2.monitor hit and miss latency
//--------3.monitor hit and miss rate
//--------4.evict all data after all seq done and compare data in down_seqr and ref 
//--------5.monitor if the cancel_last_trans and clear_mshr_id signals take effect 
//=======================================================================================
class l1d_scoreboard;
    //===========================
    //--------variables
    //===========================
    l1d_cfg                     l1d_scb_cfg                            ;
    l1d_up_trans                l1d_req_dut_trans                      ;
    l1d_mem_trans               l1d_ack_dut_trans                      ;
    l1d_mem_trans               l1d_ref_trans                          ;
    mailbox                     l1d_req_dut_mbx                        ;
    mailbox                     l1d_ack_dut_mbx                        ;
    mailbox                     l1d_ref_mbx                            ;
    //event for 2/3/4
    
    //assiociated array
    bit [REQ_DATA_WIDTH-1:0]      scb_data_mem[sb_verif_payld][$]      ;
    // bit [VERIF_ADDR_WIDTH-1:0]    scb_addr_mem[sb_verif_payld][$]      ;       
    //===========================
    //--------constructor
    //===========================
    function new(input l1d_cfg l1d_scb_cfg)    ;
        this.l1d_scb_cfg = l1d_scb_cfg         ;
    endfunction

    //===========================
    //--------function & task
    //===========================
    function set_mbx(input mailbox l1d_req_dut_mbx,input mailbox l1d_ack_dut_mbx,input mailbox l1d_ref_mbx);
        this.l1d_req_dut_mbx = l1d_req_dut_mbx ;
        this.l1d_ack_dut_mbx = l1d_ack_dut_mbx ;
        this.l1d_ref_mbx     = l1d_ref_mbx     ;
    endfunction

    task running_dut_to_scb();
        bit [REQ_DATA_WIDTH-1:0]        dut_data    ;
        sb_verif_payld                  dut_sb_pld  ;
        bit [REQ_DATA_WIDTH-1:0]        ref_data    ;
        fork
            forever begin
                    if(l1d_ack_dut_mbx.num()!=0) begin
                        l1d_ack_dut_mbx.peek(l1d_ack_dut_trans)         ;
                        dut_data   =l1d_ack_dut_trans.data              ;
                        dut_sb_pld =l1d_ack_dut_trans.sb_pld            ;
                        ref_data   =scb_data_mem[dut_sb_pld].pop_front  ;
                        assert(ref_data == dut_data) else begin
                            if(l1d_scb_cfg.debug_en) begin
                                $display ("[DEBUG][SCB][%0t] read   DATA from DUT: %b",$time,dut_data)  ;
                                $display ("[DEBUG][SCB][%0t] read   ID   from DUT: %b",$time,dut_sb_pld);
                                $display ("[DEBUG][SCB][%0t] stored DATA in   SCB: %b",$time,ref_data)  ;
                            end
                            $fatal("[DEBUG][SCB][%0t] READ DATA from DUT AND REF comparision failed",$time);
                        end
                    end
            end
        join_none
    endtask

    task running_ref_to_scb();
        bit [REQ_DATA_WIDTH-1:0]        ref_data    ;
        bit [VERIF_ADDR_WIDTH-1:0]      ref_addr    ;
        sb_verif_payld                  ref_sb_pld  ;
        fork
            forever begin
                if(l1d_ref_mbx.num()!=0) begin
                    l1d_ref_mbx.peek(l1d_ref_trans)        ;
                    //read
                    if(l1d_ref_trans.op_is_read) begin
                        ref_data   = l1d_ref_trans.data               ;
                        ref_addr   = l1d_ref_trans.addr               ;
                        ref_sb_pld = l1d_ref_trans.sb_pld             ;
                        scb_data_mem[ref_sb_pld].push_back(ref_data)  ;
                        scb_addr_mem[ref_sb_pld].push_back(ref_addr)  ;
                        l1d_ref_mbx.get(l1d_ref_trans)                ;
                        if(l1d_scb_cfg.debug_en) $display("[DEBUG][SCB][%0t] GET READ RSP from REF,and write to queue",$time) ;
                        l1d_ref_trans.display("REF to SCB");
                    end
                    //write
                    else begin
                        if(l1d_scb_cfg.debug_en) $display("[DEBUG][SCB][%0t] GET WRITE RSP from REF",$time)                   ;
                    end
                end
            end
        join_none
    endtask
    //===========================
    //--------main task
    //===========================
    task run();
        fork
            running_dut_to_scb();
            running_ref_to_scb();
        join
    endtask
endclass:l1d_scoreboard