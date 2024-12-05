// import l1d_verif_package::*;
// `include "l1d_if.sv"
class l1d_up_trans;
    // rand bit                             vld                 ;
    rand pack_l1d_verif_tag_req             pld                 ;
    rand bit                                cancel_last_trans   ;
    rand bit                                clear_mshr_rd       ;
    //constraint
    constraint pld_is_write{
        pld.op_is_read == 1'b0;
        // vld            == 1'b1;
    }
    constraint pld_not_cancel{
        cancel_last_trans == 1'b0;
        clear_mshr_rd     == 1'b0;
    }
    //new
    function new();
        // vld = 1'b1;
    endfunction

    function void display(input string msg= "");
        $display("%sDisplay Trans Messsage",msg);
        // $display("%10s:$5d","vld",vld);
        $display("%10s:%20b","tag",pld.tag);
        $display("%10s:%20b","index",pld.index);
        $display("%10s:%20b","offset",pld.offset);
        $display("%10s:%20b","op_is_read",pld.op_is_read);
        $display("%10s:%20b","sb_pld",pld.sb_pld);
        if(!pld.op_is_read)begin
            $display("%10s:%64h","wr_data",pld.wr_data);
            $display("%10s:%8h","wr_data_be",pld.wr_data_be);
        end
    endfunction   
    
    function copy_to(output l1d_up_trans trans);
        trans = new this;
    endfunction
endclass:l1d_up_trans