module l1d_mshr_data_ram_arb
import l1d_package::*;
(
    input  pack_data_ram_req_pld mshr_bps_pld    ,
    input  pack_data_ram_req_pld mshr_entry_pld  ,
    input  logic                 mshr_bps_vld    ,
    input  logic                 mshr_entry_vld  ,
    output pack_data_ram_req_pld data_ram_pld    ,
    output logic                 data_ram_vld            
);

assign data_ram_pld = mshr_bps_vld ? mshr_bps_pld : mshr_entry_pld;
assign data_ram_vld = mshr_bps_vld || mshr_entry_vld              ;
endmodule