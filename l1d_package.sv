package l1d_package;
    
    localparam integer unsigned REQ_DATA_WIDTH      = 64;
    localparam integer unsigned REQ_DATA_EN_WIDTH   = REQ_DATA_WIDTH/8;

    localparam integer unsigned L1D_INDEX_WIDTH     = 4;
    localparam integer unsigned L1D_TAG_WIDTH       = 4;
    localparam integer unsigned L1D_OFFSET_WIDTH    = 4;
    localparam integer unsigned L1D_MSHR_ENTRY_NUM  = 32;
    localparam integer unsigned L1D_MSHR_ID_WIDTH   = 5;

    typedef struct packed {
        logic                           need_rw                 ;
        logic                           need_evict              ;
        logic                           need_linefill           ;
        logic                           need_wirte              ;
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_TAG_WIDTH-1:0]       new_tag                 ;
        logic [L1D_TAG_WIDTH-1:0]       evict_tag               ;
    } pack_l1d_mshr_state;

    typedef struct packed {
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_TAG_WIDTH-1:0]       tag                     ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                  ;   
        logic                           op_is_read              ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                 ;       
        logic [REQ_DATA_EN_WIDTH-1:0]   wr_data_byte_en         ;                
    } pack_l1d_req;


endpackage



