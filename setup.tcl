read_file -type sourcelist ../../l1d_filelist.f
set_option top l1d_top
current_goal Design_Read -top l1d_top
set_option enableSV09 yes
link_design -force