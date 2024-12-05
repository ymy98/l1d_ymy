// `timescale 1ns/1ps
`include "l1d_env.sv"
module l1d_env_top();
    logic                           clk                            ;
    l1d_env                         l1d_env_tb                     ;
    logic                           rst_n                          ;
    l1d_cfg                         l1d_cfg_tb                     ;
    L1D_downstream_if               l1d_down_vif(clk,rst_n)        ;
    L1D_upstream_if                 l1d_up_vif(clk,rst_n)          ;
    l1d_top u_l1d_top(
        .clk(clk),                        
        .rst_n(rst_n),
        .upstream_req_vld(l1d_up_vif.upstream_req_vld),
        .upstream_req_rdy(l1d_up_vif.upstream_req_rdy),
        .upstream_req_pld(l1d_up_vif.upstream_req_pld),
        .cancel_last_trans(l1d_up_vif.cancel_last_trans),
        .clear_mshr_rd(l1d_up_vif.clear_mshr_rd),
        .upstream_tag_hit(l1d_up_vif.upstream_tag_hit),
        .upstream_ack_en(l1d_up_vif.upstream_ack_en),
        .upstream_ack_dat(l1d_up_vif.upstream_ack_dat),
        .upstream_sb_pld(l1d_up_vif.upstream_sb_pld),
        .downstream_req_rdy(l1d_down_vif.downstream_req_rdy),
        .downstream_req_vld(l1d_down_vif.downstream_req_vld),
        .downstream_req_pld(l1d_down_vif.downstream_req_pld),
        .downstream_req_id(l1d_down_vif.downstream_req_id),
        .downstream_rsp_vld(l1d_down_vif.downstream_rsp_vld),
        .downstream_rsp_rdy(l1d_down_vif.downstream_rsp_rdy),
        .downstream_rsp_pld(l1d_down_vif.downstream_rsp_pld),
        .downstream_rsp_id(l1d_down_vif.downstream_rsp_id),
        .downstream_evict_vld(l1d_down_vif.downstream_evict_vld),
        .downstream_evict_pld(l1d_down_vif.downstream_evict_pld),
        .downstream_evict_rdy(l1d_down_vif.downstream_evict_rdy)
    );
    
    initial begin
        //new
        l1d_cfg_tb                  = new()          ;
        l1d_cfg_tb.debug_en         = 1'b1           ;
        l1d_env_tb                  = new(l1d_cfg_tb);   
        //connect
        l1d_env_tb.l1d_down_vif     = l1d_down_vif   ;
        l1d_env_tb.l1d_up_vif       = l1d_up_vif     ;
        $display("[DEBUG][ENV_TB]pass l1d_up_vif to ENV" );
        l1d_env_tb.connect()                         ;
        @(posedge l1d_up_vif.clk);
        $display("[DEBUG][ENV_TB]%0t detect posedge clk",$time);
        l1d_env_tb.run()                             ;
        repeat(10) @(posedge clk)                    ;    
        $finish;
    end

    initial begin
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end
    end

    initial begin
        $fsdbDumpfile("top.fsdb")       ;
        $fsdbDumpvars(0, l1d_env_top)   ;    
        repeat(100) @(posedge clk)      ;
        $display("TIMEOUT!!!!!!!!")     ;
        $finish;
    end
endmodule