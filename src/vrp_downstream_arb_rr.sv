module vrp_downstream_arb_rr 
    import l1d_package::*;
(
    input  logic                           clk                              ,
    input  logic                           rst_n                            ,
    input  logic [L1D_MSHR_ENTRY_NUM-1:0]  v_in_vld                         ,
    output logic [L1D_MSHR_ENTRY_NUM-1:0]  v_in_rdy                         ,
    input  pack_downstream_req_pld         v_in_pld [L1D_MSHR_ID_WIDTH-1:0] ,
    output logic                           out_flitpend                     ,
    output logic                           out_flitv                        ,
    output pack_req_flit                   out_flit                         ,
    input  logic                           out_lcrdv                        
);

logic [L1D_MSHR_ID_WIDTH-1:0] free_idx;
logic                         out_vld ;
logic                         out_rdy ;

vrp_arb_rr#(
    .BIN_WIDTH (L1D_MSHR_ID_WIDTH )
)u_vrp_arb_rr(
    .clk       (clk     ),
    .rst_n     (rst_n   ),
    .v_in_vld  (v_in_vld),
    .v_in_rdy  (v_in_rdy),
    .out_vld   (out_vld ),
    .out_rdy   (out_rdy ),
    .out_idx   (free_idx)
);

assign out_rdy             = out_lcrdv       ;
assign out_flitpend        = out_vld         ;

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)  begin
        out_flitv            <= 1'b0;
        out_flit             <= {$bits(pack_req_flit){1'b0}};
    end
    else begin
        if(out_vld && out_rdy) begin         
            out_flitv        <= 1'b1                                                         ;
            out_flit.TxnID   <= free_idx                                                     ;
            out_flit.Opcode  <= v_in_pld[free_idx].evict ? 6'h1d : 6'h4                      ; //evict ? write no snoop full:read no snoop
            out_flit.Size    <= 3'b101                                                       ; //32bytes 64x4
            out_flit.Addr    <= v_in_pld[free_idx][$bits(pack_downstream_req_pld)-1:1]       ;
            out_flit.Order   <= 2'b0                                                         ;
        end
        else                   begin
            out_flitv        <= 1'b0                                                         ;
            out_flit         <= {$bits(pack_req_flit){1'b0}}                                 ;
        end
    end
end

endmodule