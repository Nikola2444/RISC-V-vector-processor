# Script for running vivado synthesis on one or multiple files
# Should be invoked by vivado in batch mode or from vivado in tcl shell mode

if {$argc < 1 || $argc > 10 } {
  puts "The 'run_synth.tcl' script can be run with one or two arguments"
  puts "First argument needs to be a top_module name"
  puts "Second argument can be either a filename or another tcl script"
  puts "If it's a filename, it will be synthesized alone"
  puts "If it's not provided, it will be asumed based on top_module name"
  puts "Example: vivado -mode batch -source ./run_synth.tcl sdna_dma sdna_dma.sv"
  puts "If it's a tcl script, it must contain only read_vhdl and read_verilog commands"
  puts "These commands need to include all the files needed in the design, in the hierarchical order"
  puts "Example: vivado -mode batch -source run_synth.tcl -tclargs sdna_top.sv top.tcl"
  puts "Please try again."
  exit
}
if {$argc == 1} {
  puts "No second argument, assuming file_name is the same as top_name"
}

puts [lindex $argv 0]
puts [lindex $argv 1]
puts [lindex $argv 2]
puts [lindex $argv 3]
puts [lindex $argv 4]



#extracting tcl arguments
set top_name [lindex $argv 0]
set src_files [lindex $argv 1]
set run_impl [lindex $argv 2]
set one_or_all [lindex $argv 3]
set frequency [lindex $argv 4]
set part_name [lindex $argv 5]
set optimize [lindex $argv 6]
set clk_name [lindex $argv 7]
set clk2_name [lindex $argv 8]




if {[string match "yes" $src_files]} {
    set num_of_boards 4
} else {
    set num_of_boards 1
}

variable pjt_files
if { [string match "*.f" $src_files] } {
  set pjt_files $src_files }


variable verilog_files
if { [string match "*.v" $src_files] } {
  set verilog_file $src_files
} else {
  set verilog_file $top_name
  append verilog_file ".v"
 }


variable sysver_files
if { [string match "*.sv" $src_files] } {
  set sysver_file $src_files
} else {
  set sysver_file $top_name
  append sysver_file ".sv"
 }


variable vhdl_files
if { [string match "*.vhd" $src_files] } {
  set vhdl_file $src_files
} else {
  set vhdl_file $top_name
  append vhdl_file ".vhd"
}



set milliseconds [clock clicks]
variable time [format "%s_%03d" [clock format [clock seconds] -format %Y%m%d_%H%M%S] [expr {$milliseconds % 1000}] ]

# All generated files will be in this directory
set result_dir "result_"
append result_dir $top_name
append result_dir "_"
append result_dir $time

#process for getting script file directory
variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
  variable dispScriptFile
  set scriptFolder [file dirname $dispScriptFile]
  return $scriptFolder
}

#change working directory to script file directory
#cd [getScriptDirectory]
#set curr_dir [getScriptDirectory]
set curr_dir "./"
#make a directory for result files
file mkdir $result_dir
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
set part_name $part_name
create_project -in_memory -part $part_name
#set_param project.singleFileAddWarning.threshold 0
#set_param project.compositeFile.enableAutoGeneration 0
#set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir $curr_dir/$result_dir/.webtalk [current_project]
set_property parent.project_path $curr_dir/$result_dir/.project [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language verilog [current_project]
#set_property ip_cache_permissions disable [current_project]
#

if { [info exists verilog_file] } {
  read_verilog -library xil_defaultlib -quiet $verilog_file
}

if { [info exists sysver_file] } {
  read_verilog -sv -library xil_defaultlib -quiet $sysver_file
}

if { [info exists vhdl_file] } {
  read_vhdl -library xil_defaultlib -quiet $vhdl_file
}


if { [info exists pjt_files] } {
    #  puts "Sourcing tcl script"
    #  source $pjt_files

    puts "You have these environment variables set:"
    foreach index [array names env] {
        #puts "$index: $env($index)"
        set $index $env($index)
    }

    set fp [open $pjt_files r]
    set file_data [read $fp]
    close $fp

    set data [split $file_data "\n"]
    #foreach line $data {
    #puts [subst $data]
    read_verilog -sv -library xil_defaultlib [subst $file_data]
    # do some line processing here
    #}
}

# TODO Put your part name here, default is Alveo card U200



#Calculating clock period and pulse width
set period [expr 1000.0 / $frequency]
set period2 [expr $period/2]
set wafeform_width "0.000 [expr $period / 2]"
set wafeform_width2 "0.000 [expr $period2 / 2]"
    
file mkdir $curr_dir/$result_dir/$part_name

source "synth_opt.tcl"
puts $optimize
puts $part_name
# Run synthesis with chosen optimizations
synth_design -part $part_name -top $top_name -flatten_hierarchy $flatten_hierarchy -gated_clock_conversion "off" -directive $directive -bufg "12" $no_lc -fanout_limit "10000" -shreg_min_size $shreg_min_size -mode out_of_context -fsm_extraction $fsm_extraction -resource_sharing $resource_sharing -cascade_dsp "auto" -control_set_opt_threshold $control_set_opt_threshold -max_bram "-1" -max_uram "-1" -max_dsp "-1" -max_bram_cascade_height "-1" -max_uram_cascade_height "-1"

#create clock for synthesis
create_clock -period $period -name clk -waveform $wafeform_width [get_ports $clk_name]

if { [string match "no_clock" $clk2_name] } {
    puts "no second clock"
} else {
    create_clock -period $period2 -name clk_2 -waveform $wafeform_width2 [get_ports $clk2_name]
}

file mkdir $curr_dir/$result_dir/$part_name/

write_checkpoint -force -noxdef $curr_dir/$result_dir/$part_name/.xil_dcp/.dcp
report_utilization -verbose -file $curr_dir/$result_dir/$part_name/module_util.rpt
report_utilization -hierarchical -verbose -file $curr_dir/$result_dir/$part_name/hierarchy_util.rpt    
report_timing_summary -max_paths 10 -file  $curr_dir/$result_dir/$part_name/timing_summary_synthesis.rpt



if { [string match "yes" $run_impl] } {
    if { [string match "no" $optimize] } {
        opt_design
        place_design 
        write_checkpoint -force post_place.dcp
        phys_opt_design
        route_design 
    } else {
        source "impl_opt.tcl"
    }
    write_checkpoint -force post_route.dcp
    report_utilization -verbose -file $curr_dir/$result_dir/$part_name/impl_module_util.rpt
    report_utilization -hierarchical -verbose -file $curr_dir/$result_dir/$part_name/impl_hierarchy_util.rpt    
    
    report_timing_summary -max_paths 10 -file  $curr_dir/$result_dir/$part_name/timing_summary_implementation.rpt
    #write_bitstream -force sys_integration_top.bit
    
}

