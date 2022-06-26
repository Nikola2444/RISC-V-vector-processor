
#process for getting script file directory
variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

#change working directory to script file directory
cd [getScriptDirectory]
#set ip_repo_path to script dir
set masterDir [getScriptDirectory]

# PACKAGE RISCV_AXI_IP
source riscv-v_package_ip.tcl

# Make block design
source riscv-v_bd_synth_impl_binary.tcl
