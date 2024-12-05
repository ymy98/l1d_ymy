// import l1d_verif_package::*;
// `include "../l1d_seq/l1d_down_sequence.sv"
class l1d_down_sequencer;
    //cfg 
    l1d_cfg                     l1d_cfg_seqr                            ;
                    
    //mailbox                       
    mailbox                     from_seq_mbx                            ;
    mailbox                     to_ref_mbx                              ;
    mailbox                     from_drv_mbx                            ;
    mailbox                     to_drv_mbx                              ;
   
    //trans                 
    l1d_mem_trans               to_ref_trans                            ;
    l1d_mem_trans               to_drv_trans                            ;
    l1d_mem_trans               from_drv_rd_trans                       ;
    l1d_mem_trans               from_drv_wr_trans                       ;
       
    //array:to simulate mem   
    bit [REQ_DATA_WIDTH-1:0]    seqr_mem [bit [VERIF_ADDR_WIDTH-1:0]]   ;
    bit [VERIF_ADDR_WIDTH-1:0]  seqr_mem_addr                           ;
    bit [REQ_DATA_WIDTH-1:0]    seqr_mem_data                           ;
    
    //seqr to drv
    bit [REQ_DATA_WIDTH-1:0]    drv_rsp_addr_queue[$]                   ;
    
    function new(input l1d_cfg l1d_cfg_seqr);
        this.l1d_cfg_seqr = l1d_cfg_seqr    ;
    endfunction

    function set_mbx(input mailbox from_seq_mbx,input mailbox to_ref_mbx,input mailbox from_drv_mbx,input mailbox to_drv_mbx);
        this.from_seq_mbx  = from_seq_mbx  ;
        this.to_ref_mbx    = to_ref_mbx    ;
        this.from_drv_mbx  = from_drv_mbx  ;
        this.to_drv_mbx    = to_drv_mbx    ;
    endfunction

    task seq_write_mem();
    fork
        forever begin
            if(this.from_seq_mbx.num()!=0) begin
                this.from_seq_mbx.get(to_ref_trans)                   ;
                this.seqr_mem_addr = to_ref_trans.addr                ;
                this.seqr_mem_data = to_ref_trans.data                ;
                //write to local mem
                this.seqr_mem[this.seqr_mem_addr] = this.seqr_mem_data;
                //write to ref model
                to_ref_mbx.put(to_ref_trans)                          ;
                if (l1d_cfg_seqr.debug_en) $display("[DEBUG][DOWN_SEQR][%0t]transport random trans from SEQ to RES AND SEQR",$time);
            end
        end
    join_none
    endtask

    task get_drv_req();
        bit [VERIF_ADDR_WIDTH-1:0]  mem_addr                         ;
        fork
        forever begin
            if(this.from_drv_mbx.num()!=0) begin
                this.from_drv_mbx.peek(this.from_drv_rd_trans)       ;
                if(this.from_drv_rd_trans.op_is_read) begin
                    this.from_drv_mbx.get(this.from_drv_rd_trans)    ;
                    mem_addr    = this.from_drv_rd_trans.addr        ;
                    this.drv_rsp_addr_queue.push_back(mem_addr)      ;  
                    if (l1d_cfg_seqr.debug_en) $display("[DEBUG][DOWN_SEQR][%0t]get read request from driver,addr is %b",$time,mem_addr);
                end
            end
        end
        join
    endtask

    task generate_drv_rsp_io();
        bit [VERIF_ADDR_WIDTH-1:0]  mem_addr                         ;
        bit [REQ_DATA_WIDTH-1:0]    mem_data                         ;
        fork
            forever begin
                if(this.drv_rsp_addr_queue.size()!=0) begin
                    mem_addr = drv_rsp_addr_queue.pop_front();
                    for(int i=0;i<L1D_OFFSET_WIDTH;i++) begin
                        mem_addr              = mem_addr + 1'b1         ;
                        mem_data              = this.seqr_mem[mem_addr] ;
                        this.to_drv_trans.addr= mem_addr                ;
                        this.to_drv_trans.data= mem_data                ;
                        this.to_drv_mbx.put(to_drv_trans)               ;
                    end
                end
            end
        join_none
    endtask

    task generate_drv_rsp_ooo();
        bit [VERIF_ADDR_WIDTH-1:0]  mem_addr                         ;
        bit [REQ_DATA_WIDTH-1:0]    mem_data                         ;
        //random queue key
        int                         queue_key                        ;
        int                         min_key                          ;
        int                         max_key                          ;
        //random cycles
        int                         delay_cycles                     ;
        int                         delay_time                       ;
        fork 
            forever begin
                delay_cycles = ($urandom%5) + 1          ;
                delay_time   = delay_cycles * cycle_times;
                #delay_time;
                if(this.drv_rsp_addr_queue.size()!=0) begin
                    if (l1d_cfg_seqr.debug_en) $display("[DEBUG][DOWN_SEQR][%0t]SEQR to DRIVER QUEUE is not empty",$time)      ;
                    //------------generate random queue key
                    max_key    = drv_rsp_addr_queue.size();
                    min_key    = 0                        ;
                    if (l1d_cfg_seqr.debug_en) $display("[DEBUG][DOWN_SEQR][%0t]SEQR to DRIVER QUEUE size is $d",$time,max_key);

                    queue_key  = min_key + ($urandom %(max_key - min_key + 1));
                    if (l1d_cfg_seqr.debug_en) $display("[DEBUG][DOWN_SEQR][%0t]SEQR to DRIVER QUEUE size is $d",$time,max_key);
                    
                    //------------write to driver
                    mem_addr   = drv_rsp_addr_queue[queue_key]          ;
                    for(int i=0;i<L1D_OFFSET_WIDTH;i++) begin
                        mem_addr              = mem_addr + 1'b1         ;
                        mem_data              = this.seqr_mem[mem_addr] ;
                        this.to_drv_trans.addr= mem_addr                ;
                        this.to_drv_trans.data= mem_data                ;
                        this.to_drv_mbx.put(to_drv_trans)               ;
                        if (l1d_cfg_seqr.debug_en) $display("[DEBUG][DOWN_SEQR][%0t]SEQR to DRIVER write addr is $d",$time,this.to_drv_trans.addr);
                        if (l1d_cfg_seqr.debug_en) $display("[DEBUG][DOWN_SEQR][%0t]SEQR to DRIVER write data is $d",$time,this.to_drv_trans.data);
                    end
                    drv_rsp_addr_queue.delete(queue_key)                ;
                end
            end
        join_none
    endtask

    task down_evict_write_mem();
        bit [VERIF_ADDR_WIDTH-1:0]  mem_addr                         ;
        bit [REQ_DATA_WIDTH-1:0]    mem_data                         ;
        fork
            forever begin
                if(this.from_drv_mbx.num()!=0) begin
                    this.from_drv_mbx.peek(this.from_drv_wr_trans)   ;
                    if(!this.from_drv_wr_trans.op_is_read) begin
                        this.from_drv_mbx.get(this.from_drv_wr_trans);
                        mem_addr                = this.from_drv_wr_trans.addr    ;
                        mem_data                = this.from_drv_rd_trans.data    ;
                        this.seqr_mem[mem_addr] = mem_data                       ;
                        if (l1d_cfg_seqr.debug_en) $display("[DEBUG][DOWN_SEQR][%0t]get write request from driver,addr is %b,data is %b",$time,mem_addr,mem_data);
                    end
                end
            end
        join_none
    endtask
    
    task run();
        fork
            seq_write_mem();
            get_drv_req();
            generate_drv_rsp_io();
            down_evict_write_mem();
        join;
    endtask

endclass:l1d_down_sequencer