package l1d_package;
    //cache
    localparam integer unsigned REQ_DATA_WIDTH      = 256                                                               ;
    localparam integer unsigned REQ_DE_WIDTH        = REQ_DATA_WIDTH/8                                                  ;
    localparam integer unsigned REQ_ID_WIDHT        = 10                                                                ;
    localparam integer unsigned L1D_INDEX_WIDTH     = 6                                                                 ;
    localparam integer unsigned L1D_INDEX_NUM       = 1<<L1D_INDEX_WIDTH                                                ;
    localparam integer unsigned L1D_TAG_WIDTH       = 20                                                                ;
    localparam integer unsigned L1D_OFFSET_WIDTH    = 1                                                                 ;
    localparam integer unsigned L1D_OFFSET_NUM      = 1<<L1D_OFFSET_WIDTH                                               ;
    localparam integer unsigned L1D_MSHR_ENTRY_NUM  = 32                                                                ;
    localparam integer unsigned L1D_MSHR_ID_WIDTH   = $clog2(L1D_MSHR_ENTRY_NUM)                                        ;
    localparam integer unsigned L1D_WAY_NUM         = 4                                                                 ;
    localparam integer unsigned L1D_WAY_WIDTH       = $clog2(L1D_WAY_NUM)                                               ;
    // localparam integer unsigned WEIGHT_WIDHT        = L1D_INDEX_WIDTH                                                ;
    localparam integer unsigned PRE_ALLO_NUM        = 4                                                                 ;
    //tag ram addr
    localparam integer unsigned L1D_TAG_RAM_WIDHT   = L1D_WAY_NUM * L1D_TAG_WIDTH                                       ;
    localparam integer unsigned LAD_TAG_RAM_DEPTH   = L1D_INDEX_NUM                                                     ;              
    localparam integer unsigned MASK_ADDR_WIDTH     = $clog2(REQ_DE_WIDTH)                                              ;

    //chi protocal                  
    // localparam integer unsigned CHI_NODEID_WIDTH    = 7                                                                 ;
    // localparam integer unsigned CHI_TRX_ADDR_WIDTH  = L1D_INDEX_WIDTH+L1D_TAG_WIDTH+L1D_OFFSET_WIDTH+L1D_WAY_WIDTH      ;
    // localparam integer unsigned CHI_DATA_WIDTH      = REQ_DATA_WIDTH                                                    ; 
    // localparam integer unsigned CHI_DATA_TAG_WIDTH  = CHI_DATA_WIDTH/32                                                 ; 
    // localparam integer unsigned CHI_DATA_TU_WIDTH   = CHI_DATA_WIDTH/128                                                ;
    // localparam integer unsigned CHI_DATA_B E_WIDTH   = CHI_DATA_WIDTH/8                                                 ;
    // localparam integer unsigned CHI_DATA_DC_WIDTH   = CHI_DATA_WIDTH/8                                                  ;
    // localparam integer unsigned CHI_DATA_P_WIDTH    = CHI_DATA_WIDTH/64                                                 ;
                     
    //data ram                   
    localparam integer unsigned DATA_RAM_WIDTH      = REQ_DATA_WIDTH                                                    ;
    localparam integer unsigned DATA_RAM_DEPTH      = L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH+L1D_WAY_WIDTH                    ; 
    localparam integer unsigned CREDIT_BUF_DEPTH    = 4                                                                 ;
    localparam integer unsigned EVICT_PLD_VLD_DEPTH = CREDIT_BUF_DEPTH/(L1D_OFFSET_NUM+1) + 1                           ;

    typedef logic [REQ_ID_WIDHT-1:0] sb_payld;

    typedef struct packed {
        logic [MASK_ADDR_WIDTH-1:0]     mask_addr                  ;
        logic [L1D_TAG_WIDTH-1:0]       tag                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;   
        logic                           op_is_read                 ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                    ;       
        logic [REQ_DE_WIDTH-1:0]        wr_data_be                 ;        
        sb_payld                        sb_pld                     ;
    } pack_l1d_tag_req;

    typedef struct packed {
        logic                           need_evict                 ;
        logic                           need_linefill              ;
        logic [L1D_TAG_WIDTH-1:0]       evict_tag                  ;
        logic [L1D_WAY_NUM-1:0]         way                        ;
        logic [MASK_ADDR_WIDTH-1:0]     mask_addr                  ;
        logic [L1D_TAG_WIDTH-1:0]       tag                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;   
        logic                           op_is_read                 ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                    ;       
        logic [REQ_DE_WIDTH-1:0]        wr_data_be                 ;        
        sb_payld                        sb_pld                     ;
    } pack_l1d_tag_rsp;
 
    typedef struct packed {
        logic [L1D_WAY_NUM-1:0][L1D_TAG_WIDTH-1:0]       line_tag  ;
        logic [L1D_WAY_NUM-1:0]                          tag_be    ;
        logic [L1D_TAG_WIDTH-1:0]                        tag       ;
        logic [L1D_INDEX_WIDTH-1:0]                      index     ;
        logic [L1D_WAY_WIDTH-1:0]                        way       ;
    } pack_l1d_tag_pipe_wr_pld;

    typedef struct packed {
        logic [L1D_TAG_WIDTH-1:0]       tag                        ;
        logic [L1D_WAY_NUM-1:0]         way                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;   
        sb_payld                        sb_pld                     ;
    } pack_l1d_mshr_downstream_req_pld; 

    typedef struct packed {
        logic [L1D_WAY_NUM-1:0]         way                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;   
        logic                           op_is_read                 ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                    ;       
        logic [REQ_DE_WIDTH-1:0]        wr_data_be                 ;        
        sb_payld                        sb_pld                     ;
    } pack_l1d_mshr_rw_req_pld;

    typedef struct packed {
        logic [L1D_TAG_WIDTH-1:0]       tag                        ;
        logic [L1D_WAY_NUM-1:0]         way                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;
        logic                           rd_last                    ;
    } pack_l1d_mshr_evict_req_pld;

    typedef struct packed {
        logic [L1D_TAG_WIDTH-1:0]       evict_tag                  ;
        logic [L1D_WAY_NUM-1:0]         way                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_TAG_WIDTH-1:0]       tag                        ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;   
        logic                           op_is_read                 ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                    ;       
        logic [REQ_DE_WIDTH-1:0]        wr_data_be                 ;        
        sb_payld                        sb_pld                     ;
    } pack_l1d_mshr_ety_regfile;

    typedef struct packed {
        logic [L1D_WAY_NUM-1:0]         way                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;   
        sb_payld                        sb_pld                     ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                    ;     
        logic                           wr_last                    ;
    } pack_l1d_data_pipe_downstream_rsp;

    typedef struct packed {
        // logic [L1D_MSHR_ID_WIDTH-1:0]   evict_id                   ;
        logic [L1D_WAY_NUM-1:0]         way                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;   
        logic                           op_is_read                 ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                    ;
        logic [REQ_DE_WIDTH-1:0]        wr_data_be                 ;         
        sb_payld                        sb_pld                     ;
    } pack_l1d_data_ram_req;
    
    typedef struct packed {
        logic [L1D_TAG_WIDTH-1:0]       tag                        ;
        logic [L1D_INDEX_WIDTH-1:0]     index                      ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                     ;  
        logic [REQ_DATA_WIDTH-1:0]      wr_data                    ;
        logic                           rd_last                    ;
        logic [L1D_MSHR_ID_WIDTH-1:0]   evict_id                   ;
    } pack_l1d_data_ram_evict_req;
endpackage