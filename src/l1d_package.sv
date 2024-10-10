package l1d_package;
    //cache
    localparam integer unsigned REQ_DATA_WIDTH      = 64                                                                ;
    localparam integer unsigned REQ_DATA_EN_WIDTH   = REQ_DATA_WIDTH/8                                                  ;
    localparam integer unsigned REQ_ID_WIDHT        = 10                                                                ;
    localparam integer unsigned L1D_INDEX_WIDTH     = 4                                                                 ;
    localparam integer unsigned L1D_TAG_WIDTH       = 4                                                                 ;
    localparam integer unsigned L1D_OFFSET_WIDTH    = 2                                                                 ;
    localparam integer unsigned L1D_OFFSET_MAX      = (1<<L1D_OFFSET_WIDTH)-1                                           ;
    localparam integer unsigned L1D_TAG_RAM_DEPTH   = 1<<L1D_INDEX_WIDTH                                                ;
    localparam integer unsigned L1D_MSHR_ENTRY_NUM  = 32                                                                ;
    localparam integer unsigned L1D_MSHR_ID_WIDTH   = $clog2(L1D_MSHR_ENTRY_NUM)                                        ;
    localparam integer unsigned L1D_WAY_NUM         = 4                                                                 ;
    localparam integer unsigned L1D_WAY_NUM_WIDTH   = $clog2(L1D_WAY_NUM)                                               ;
    localparam integer unsigned WEIGHT_WIDHT        = L1D_INDEX_WIDTH                                                   ;
    localparam integer unsigned PRE_ALLO_NUM        = 4                                                                 ;
    //chi protocal                  
    localparam integer unsigned CHI_NODEID_WIDTH    = 7                                                                 ;
    localparam integer unsigned CHI_TRX_ADDR_WIDTH  = L1D_INDEX_WIDTH+L1D_TAG_WIDTH+L1D_OFFSET_WIDTH+L1D_WAY_NUM_WIDTH  ;
    
    localparam integer unsigned CHI_DATA_WIDTH      = REQ_DATA_WIDTH                                                     ; 
    localparam integer unsigned CHI_DATA_TAG_WIDTH  = CHI_DATA_WIDTH/32                                                  ; 
    localparam integer unsigned CHI_DATA_TU_WIDTH   = CHI_DATA_WIDTH/128                                                 ;
    localparam integer unsigned CHI_DATA_BE_WIDTH   = CHI_DATA_WIDTH/8                                                   ;
    localparam integer unsigned CHI_DATA_DC_WIDTH   = CHI_DATA_WIDTH/8                                                   ;
    localparam integer unsigned CHI_DATA_P_WIDTH    = CHI_DATA_WIDTH/64                                                  ;
                     
    //data ram                   
    localparam integer unsigned DATA_RAM_WIDTH      = REQ_DATA_WIDTH                                                     ;
    localparam integer unsigned DATA_RAM_DEPTH      = L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH+L1D_WAY_NUM_WIDTH                 ; 
    localparam integer unsigned CREDIT_BUF_DEPTH    = 4                                                                  ;
    localparam integer unsigned EVICT_PLD_VLD_DEPTH = CREDIT_BUF_DEPTH/(L1D_OFFSET_MAX+1) + 1                            ;
    
    //packed
    typedef logic [REQ_ID_WIDHT-1:0] sb_payld;

    typedef struct packed {
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_TAG_WIDTH-1:0]       tag                     ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                  ;   
        logic                           op_is_read              ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                 ;       
        logic [REQ_DATA_EN_WIDTH-1:0]   wr_data_byte_en         ;        
        sb_payld                        wr_sb_pld               ;
    } pack_l1d_req;

    typedef struct packed {
        logic                           need_rw                 ;
        logic                           need_evict              ;
        logic                           need_linefill           ;
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_TAG_WIDTH-1:0]       new_tag                 ;
        logic [L1D_TAG_WIDTH-1:0]       evict_tag               ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                  ;
        logic [L1D_WAY_NUM-1:0]         way                     ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                 ;       
        logic [REQ_DATA_EN_WIDTH-1:0]   wr_data_byte_en         ;     
        sb_payld                        wr_sb_pld               ;
        logic [L1D_MSHR_ID_WIDTH-1:0]   mshr_id                 ;
        logic [L1D_MSHR_ENTRY_NUM-1:0]  mshr_hzd_index_way_line ;
        logic [L1D_MSHR_ENTRY_NUM-1:0]  mshr_hzd_evict_tag_line ;
    } pack_l1d_mshr_state;

    typedef struct packed {
        logic                           rw_type                 ;
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_TAG_WIDTH-1:0]       new_tag                 ;
        logic [L1D_TAG_WIDTH-1:0]       evict_tag               ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                  ;
        logic [L1D_WAY_NUM-1:0]         way                     ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                 ;       
        logic [REQ_DATA_EN_WIDTH-1:0]   wr_data_byte_en         ;     
        sb_payld                        wr_sb_pld               ;
    } pack_l1d_mshr_entry_regfile;

    typedef struct packed {
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [WEIGHT_WIDHT-1:0]        new_weight              ;    
    } pack_l1d_weight_pld;

    typedef struct packed {
        logic                           rw_type                 ;
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                  ;
        logic [L1D_WAY_NUM-1:0]         way                     ;
        logic [REQ_DATA_WIDTH-1:0]      wr_data                 ;       
        logic [REQ_DATA_EN_WIDTH-1:0]   wr_data_byte_en         ; 
        logic                           wr_data_part            ;    
        sb_payld                        wr_sb_pld               ;
    } pack_data_ram_req_pld;

    typedef struct packed {
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                  ;
        logic [L1D_WAY_NUM-1:0]         way                     ;
        logic [L1D_MSHR_ID_WIDTH-1:0]   mshr_id                 ; 
    } pack_evict_req_pld;

    typedef struct packed {
        logic [L1D_INDEX_WIDTH-1:0]      index                  ;
        logic [L1D_WAY_NUM_WIDTH-1:0]    way                    ;
        logic [L1D_TAG_WIDTH-1:0]        tag                    ;
        logic [L1D_OFFSET_WIDTH-1:0]     offset                 ;
        logic                            evict                  ;
    } pack_downstream_req_pld;

    typedef struct packed {
        logic [L1D_INDEX_WIDTH-1:0]      index                  ;
        logic [L1D_WAY_NUM-1:0]          way                    ;
        logic [REQ_DATA_WIDTH-1:0]       wr_data                ;       
        logic [L1D_MSHR_ID_WIDTH-1:0]    mshr_id                ;
    } pack_data_pipe_linefill_req_pld;

    typedef struct packed {
        // logic [3:0]                      QoS                    ;
        // logic [NODEID_WIDTH-1:0]         TgtID                  ;
        // logic [NODEID_WIDTH-1:0]         SrcID                  ;
        logic [L1D_MSHR_ID_WIDTH-1:0]     TxnID                  ;  
        // logic [NODEID_WIDTH-1:0]          ReturnNID              ;
        // logic [NODEID_WIDTH-1:0]          StashNID               ;
        // logic                             StashNIDValid          ;
        // logic                             Endian                 ;
        // logic                             Deep                   ;    
        // logic [11:0]                      ReturnTxnID            ;      
        logic [6:0]                       Opcode                 ;
        logic [2:0]                       Size                   ;
        logic [CHI_TRX_ADDR_WIDTH-1:0]    Addr                   ;  
        // logic                             NS                     ;
        // logic                             NSE                    ;
        // logic                             LikelyShared           ;
        // logic                             AllowRetry             ;
        logic [1:0]                       Order                  ;
        // logic [3:0]                       PCrdType               ;
        // logic [3:0]                       MemAttr                ;
        // logic                             SnpsAttr               ;
        // logic                             DoDWT                  ;
        // logic [7:0]                       PGroupID               ;
        // logic [7:0]                       StashGroupID           ;
        // logic [7:0]                       TagGroupID             ;
        // logic                             Excl                   ;
        // logic                             SnoopMe                ;
        // logic                             CAH                    ;
        // logic                             ExpCompAck             ;   
        // logic [1:0]                       TagOp                  ;
        // logic                             TraceTag               ;
    } pack_req_flit;

    typedef struct packed {
        // logic [3:0]                      QoS                    ;
        // logic [NODEID_WIDTH-1:0]         TgtID                  ;
        // logic [NODEID_WIDTH-1:0]         SrcID                  ; 
        logic [L1D_MSHR_ID_WIDTH-1:0]     TxnID                  ;
        logic [4:0]                       Opcode                 ;
        logic [1:0]                       RespErr                ;
        logic [2:0]                       Resp                   ;
        // logic [2:0]                       FwdState               ;
        // logic [2:0]                       DataPull               ;
        // logic [2:0]                       CBusy                  ;
        // logic [11:0]                      DBID                   ;
        // logic [3:0]                       PCrdType               ;
        // logic [1:0]                       TagOp                  ;
        // logic                             TraceTag               ;
    } pack_rsp_flit;

    typedef struct packed {
        // logic [3:0]                      QoS                    ;
        // logic [NODEID_WIDTH-1:0]         TgtID                  ;
        // logic [NODEID_WIDTH-1:0]         SrcID                  ;
        logic  [L1D_MSHR_ID_WIDTH-1:0]      TxnID                  ;
        // logic  [NODEID_WIDTH-1:0]           HomeNID                ;
        logic  [3:0]                        Opcode                 ;
        logic  [1:0]                        RespErr                ;
        logic  [2:0]                        Resp                   ;
        // logic  [4:0]                        DataSource             ;
        // logic  [2:0]                        CBusy                  ;
        // logic  [11:0]                       DBID                   ;
        // logic  [1:0]                        CCID                   ;
        // logic  [1:0]                        DataID                 ;
        // logic  [1:0]                        TagOp                  ;
        // logic  [CHI_DATA_TAG_WIDTH-1:0]     Tag                    ;
        // logic  [CHI_DATA_TU_WIDTH-1:0]      Tu                     ;
        // logic                               TraceTag               ;
        // logic                               CAH                    ;                       
        logic  [CHI_DATA_WIDTH-1:0]         Data                   ;
        logic  [CHI_DATA_BE_WIDTH-1:0]      BE                     ;
        // logic  [CHI_DATA_DC_WIDTH-1:0]      DataCheck              ;
        // logic  [CHI_DATA_P_WIDTH-1:0]       Poison                 ;  
    } pack_data_flit;

    typedef struct packed {
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_WAY_NUM-1:0]         way                     ;
    } pack_mshr_dat_addr;

    typedef struct packed {
        logic [L1D_WAY_NUM-1:0]         way                     ;
        logic [L1D_INDEX_WIDTH-1:0]     index                   ;
        logic [L1D_OFFSET_WIDTH-1:0]    offset                  ;
    } pack_dat_addr;

    typedef struct packed {
        logic                           rw_type                 ;
        pack_dat_addr                   pack_addr               ;
        logic [REQ_DATA_WIDTH-1:0]      wr_req_dat              ;
        logic [REQ_DATA_EN_WIDTH-1:0]   wr_req_dat_be           ; 
        sb_payld                        wr_sb_pld               ;
    } pack_wr_dat_pld;

    typedef struct packed {
        pack_dat_addr                   evict_dat_addr          ;
        logic [L1D_MSHR_ID_WIDTH-1:0]   evict_id                ;
    } pack_evict_dat_pld;

    typedef struct packed {
        pack_dat_addr                   linefill_dat_addr       ;
        logic [REQ_DATA_WIDTH-1:0]      linefill_dat            ;                          
    } pack_linefill_dat_pld;

    typedef struct packed {
        pack_dat_addr                   dat_ram_addr            ;
        logic                           rw_type                 ;  //1 : read 0:write
        // logic                           rw_line                 ; //if evict line read; if line fill line write
        logic [REQ_DATA_WIDTH-1:0]      rw_data                 ;
        logic [REQ_DATA_EN_WIDTH-1:0]   wr_data_byte_en         ; 
        sb_payld                        wr_sb_pld               ;
        logic                           op_is_downstream        ;
        logic [L1D_MSHR_ID_WIDTH-1:0]   wr_ID                   ;
        
    } pack_dat_ram_pld;
endpackage



