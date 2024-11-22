module l1d_data_pipe_data_ram
    import l1d_package::*;
(
    //from arbiter
    output logic                             data_ram_req_rdy           ,
    input  logic                             data_ram_req_vld           ,
    input  pack_l1d_data_ram_req             data_ram_req_pld           ,
    input  logic                             evict_req_id               ,
    
    output logic                             upstream_ack_en            ,
    output logic [REQ_DATA_WIDTH-1:0]        upstream_ack_dat           ,
    output sb_payld                          upstream_sb_pld              

);

//-----------------------------
//-----addr decoder: for evict
//-----------------------------

//-------------------------
//-----data ram
//-------------------------

//-------------------------
//-----evict buffer
//-------------------------


//--------------------------
//-----upstream writer
//--------------------------

//--------------------------
//-----arbiter
//--------------------------

endmodule