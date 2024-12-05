package l1d_verif_package;
    import l1d_package::*;

    localparam integer unsigned VERIF_ADDR_WIDTH = MASK_ADDR_WIDTH+L1D_INDEX_WIDTH+L1D_TAG_WIDTH+L1D_OFFSET_WIDTH;
    typedef bit [REQ_ID_WIDHT-1:0] sb_verif_payld;
    int cycle_times = 10                         ;

    typedef struct packed {
        bit [MASK_ADDR_WIDTH-1:0]     mask_addr                  ;
        bit [L1D_TAG_WIDTH-1:0]       tag                        ;
        bit [L1D_INDEX_WIDTH-1:0]     index                      ;
        bit [L1D_OFFSET_WIDTH-1:0]    offset                     ;
        bit                           op_is_read                 ;
        bit [REQ_DATA_WIDTH-1:0]      wr_data                    ;
        bit [REQ_DE_WIDTH-1:0]        wr_data_be                 ;
        sb_verif_payld                sb_pld                     ;
    } pack_l1d_verif_tag_req;

    typedef struct packed{
        sb_verif_payld                sb_pld                     ;
        bit[L1D_MSHR_ID_WIDTH-1:0]    mshr_id                    ;
        logic [L1D_WAY_NUM-1:0]       way                        ;
    } pack_l1d_down_drv_pld;
endpackage