module vrp_arb_rr#(
    parameter type pack_pld = logic                               ,
    parameter int unsigned BIN_WIDTH = 4                          ,
    localparam int unsigned OH_WIDTH = 1<<BIN_WIDTH               
)(
    input  logic                 clk                              ,
    input  logic                 rst_n                            ,
    input  logic [OH_WIDTH-1:0]  v_in_vld                         ,
    output logic [OH_WIDTH-1:0]  v_in_rdy                         ,
    input  pack_pld              v_in_pld[OH_WIDTH-1:0]           ,
    output logic                 out_vld                          ,
    input  logic                 out_rdy                          ,
    output pack_pld              out_pld                          ,                 
    output logic [BIN_WIDTH-1:0] out_idx                        
);

logic [BIN_WIDTH-1:0]  free_idx           ;
logic [OH_WIDTH-1:0]   free_idx_oh        ;
logic [OH_WIDTH-1:0]   pre_free_idx_oh    ;
logic [OH_WIDTH-1:0]   high_prio_mask     ;
logic [OH_WIDTH-1:0]   low_prio_mask      ;

//fix priority signals
logic [OH_WIDTH-1:0]   high_prio_entry_vld;
logic [OH_WIDTH-1:0]   low_prio_entry_vld ;
logic [OH_WIDTH-1:0]   high_prio_free_oh  ;
logic [OH_WIDTH-1:0]   low_prio_free_oh   ;
logic [BIN_WIDTH-1:0]  high_prio_free_idx ;
logic [BIN_WIDTH-1:0]  low_prio_free_idx  ;
logic                  high_prio_vld      ;
logic                  low_prio_vld       ;

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)        pre_free_idx_oh <= {{1'b1},{(OH_WIDTH-1){1'b0}}} ;
    else              pre_free_idx_oh <= free_idx_oh                   ;
end

genvar i ;
generate for(i=0;i<OH_WIDTH;i++) begin
    if(i==OH_WIDTH-1) 
        assign low_prio_mask[i] = pre_free_idx_oh[i]                           ;
    else
        assign low_prio_mask[i] = low_prio_mask[i+1] || pre_free_idx_oh[i]     ;
end
endgenerate

generate for(i=0;i<OH_WIDTH;i++) begin
    if(i==0)
        assign high_prio_mask[i] = 1'b0                                        ;
    else
        assign high_prio_mask[i] = high_prio_mask[i-1] || pre_free_idx_oh[i-1] ;
end
endgenerate

assign high_prio_entry_vld = v_in_vld & high_prio_mask;
assign low_prio_entry_vld  = v_in_vld & low_prio_mask ;

cmn_lead_one #(
    .ENTRY_NUM      (OH_WIDTH)
)u_cmn_lead_one_low_prio(
    .v_entry_vld    (high_prio_entry_vld  ),
    .v_free_idx_oh  (high_prio_free_oh    ),
    .v_free_idx_bin (high_prio_free_idx   ),
    .v_free_vld     (high_prio_vld        )
);

cmn_lead_one #(
    .ENTRY_NUM      (OH_WIDTH)
)u_cmn_lead_one_high_prio(
    .v_entry_vld    (low_prio_entry_vld   ),
    .v_free_idx_oh  (low_prio_free_oh     ),
    .v_free_idx_bin (low_prio_free_idx    ),
    .v_free_vld     (low_prio_vld         )
);

assign out_vld     = high_prio_vld || low_prio_vld                          ;
assign free_idx_oh = high_prio_vld ? high_prio_free_oh : low_prio_free_oh   ;
assign free_idx    = high_prio_vld ? high_prio_free_idx: low_prio_free_idx  ;
assign v_in_rdy    = out_rdy       ? {OH_WIDTH{1'b0}}  : free_idx_oh        ;


assign out_idx     = free_idx                                               ;
always_comb begin
    for (int i=0;i<OH_WIDTH;i++) begin
        if(free_idx_oh[i]) begin
            out_pld = v_in_pld[i]                   ;
        end
    end
end
endmodule