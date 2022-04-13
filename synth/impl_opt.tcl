
if { [string match "yes" $optimize] } {
    # TO OPTIMIZE DESITH IMPLEMENTATION ADD LISTED ARGUMENTS TO OPT_DESIGN, 
    #PLACE_DESYGN, PHYS_OPT_DESIGN AND ROUTE DESIGN, IF NOT EXPERIENCED CHANGE 
    #ONLY "DIRECTIVE" OPTION
    
    #********************OPT_DESIGN options********************************************
    opt_design -directive "Explore"
    
    #You can add one of listed arguments to opt_design. Check UG835 for more information on them
    
    #Example: 
    #        opt_design "-directive "Explore" \ 
    #                    -debug log 


    #-retarget
    #-propconst
    #-sweep
    #-bram_power_opt 
    #-remap
    #-aggressive_remap 
    #-resynth_area 
    #-resynth_seq_area

    #posible directives: "Explore", "ExploreArea", "ExploreWithRemap", "ExploreSequentialArea", 
    #                    "AddRemap", "NoBramPowerOpt", "RuntimeOptimized", "Default"
    #-directive <arg> 

    #-muxf_remap 
    #-hier_fanout_limit <arg>
    #-bufg_opt 
    #-shift_register_opt 
    #-dsp_register_opt
    #-control_set_merge 
    #-merge_equivalent_drivers 
    #-carry_remap
    #-debug_log 
    #-quiet 
    #-verbose

    
    #********************PLACE_DESIGN OPTIONS********************************************
    place_design -directive "ExtraTimingOpt"
    # Check UG835 page 1086 for all directive options
    #-directive <arg> 
    #-no_timing_driven 
    #-timing_summary
    #-unplace 
    #-post_place_opt 
    #-no_fanout_opt 
    #-no_bufg_opt 
    #-quiet
    #-verbose

    
    #********************PHYS_OPT_DESIGN OPTIONS********************************************
    phys_opt_design -directive "AggressiveExplore"

    #-fanout_opt 
    #-placement_opt 
    #-routing_opt
    #-slr_crossing_opt 
    #-rewire 
    #-insert_negative_edge_ffs
    #-critical_cell_opt 
    #-dsp_register_opt 
    #-bram_register_opt
    #-uram_register_opt 
    #-bram_enable_opt 
    #-shift_register_opt
    #-hold_fix 
    #-aggressive_hold_fix 
    #-retime
    #-force_replication_on_nets <args> 
    #-directive <arg>
    #-critical_pin_opt 
    #-clock_opt 
    #-path_groups <args>
    #-tns_cleanup 
    #-sll_reg_hold_fix 
    #-quiet 
    #-verbose    

    #********************ROUTE_DESIGN OPTIONS********************************************
    route_design -directive "MoreGlobalIterations"
    #-unroute 
    #-release_memory 
    #-nets <args>    #READ UG935 on how to se this
    #-physical_nets 
    #-pins <arg>     #READ UG935 on how to se this
    #-directive <arg> # Check UG835 page 1485 for all directive options
    #-tns_cleanup
    #-no_timing_driven 
    #-preserve -delay     #READ UG935 on how to se this
    #-auto_delay -max_delay <arg>     #READ UG935 on how to se this
    #-min_delay <arg> 
    #-timing_summary 
    #-finalize
    #-ultrathreads 
    #-quiet 
    #-verbose

    
}
