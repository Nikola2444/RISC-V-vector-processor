if { [string match "no" $optimize] } {
    # DO NOT TOUCH! THESE ARE DEFUALUT CONFIGURATIONS
    set flatten_hierarchy "none"
    set directive "default"
    set bufg "12"
    set fanout_limit "10000"
    set shreg_min_size "5"
    set fsm_extraction "one_hot"
    set resource_sharing "off"
    set control_set_opt_threshold "auto"
    set no_lc "-no_lc"
} else {
    #CHANGE THESE IS YOU WANT SYNTHESIS OPTIMIZATION
    # CHECK Xilinx UG901 .pdf for more information 
    
    #Possible options: "auto", "rebuilt", "none"
    set flatten_hierarchy "rebuilt"
    #possible options: "default", "RuntimeOptimized", "AreaOptimized_high", "AreaOptimized_medium",
    #                  "AlternateRoutability", "AreaMapLargeShiftRegToBRAM", "AreaMultThresholdDSP",
    #                  "FewerCarryChains", "PerformanceOptimized" 
    set directive "PerformanceOptimized"
    
    set bufg "12"
    set fanout_limit "10000"
    set shreg_min_size "5"
    #Possible options: "one_hot" "sequential", "johnson", "gray", "auto", "none"
    set fsm_extraction "one_hot"
   
    set resource_sharing "auto"
    set control_set_opt_threshold "auto"
    set no_lc "-no_lc"
}
