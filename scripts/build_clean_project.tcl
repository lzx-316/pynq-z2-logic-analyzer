# ============================================================================
#  PYNQ-Z2 logic analyzer - clean rebuild driver
#
#  What it does:
#    1. creates the Vivado project from recreate_project.tcl in a clean folder
#    2. runs synthesis + implementation
#    3. writes the bitstream and exports the XSA
#    4. copies the new .bit / .hwh into <build_dir>/release_files
#
#  How to run (Vivado 2026.1 Tcl Console):
#      source D:/FPGA/production/repo/scripts/build_clean_project.tcl
#
#  Or fully in batch mode (no GUI):
#      vivado -mode batch -source D:/FPGA/production/repo/scripts/build_clean_project.tcl -log build.log
#
#  IMPORTANT: this script never writes into repo/pynq. The frozen v2-baseline
#  bitstream stays untouched until the new one is compared on the board.
# ============================================================================

set build_dir    "D:/FPGA/build_clean"
set repo_scripts "D:/FPGA/production/repo/scripts"
set proj_name    "logic_analyzer_50m_complete_v2"
set jobs         8

if { [file exists [file join $build_dir $proj_name]] } {
    puts "ERROR: $build_dir/$proj_name already exists."
    puts "ERROR: create_project cannot overwrite it. Delete that folder (or change build_dir) and run again."
    error "build directory is not clean"
}
if { [llength [current_project -quiet]] != 0 } {
    puts "ERROR: a project is already open. Use File -> Close Project first."
    error "close the open project before running this script"
}

file mkdir $build_dir
cd $build_dir

# recreate_project.tcl reads these two variables when it is sourced.
set ::origin_dir_loc $repo_scripts

puts "INFO: clean build directory : $build_dir"
puts "INFO: sources will be read from $repo_scripts/../rtl, /../constraints, /../tb"

# ---------------------------------------------------------------- 1. project
source [file normalize "$repo_scripts/recreate_project.tcl"]

# ------------------------------------------------------------ 2. synthesis
launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
if { [get_property PROGRESS [get_runs synth_1]] ne "100%" } {
    puts "ERROR: synth_1 progress = [get_property PROGRESS [get_runs synth_1]]"
    puts "ERROR: see the run log, do not continue"
    error "synthesis did not finish"
}

# --------------------------------------------------------- 3. implementation
launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1
if { [get_property PROGRESS [get_runs impl_1]] ne "100%" } {
    puts "ERROR: impl_1 progress = [get_property PROGRESS [get_runs impl_1]]"
    puts "ERROR: see the run log, do not continue"
    error "implementation did not finish"
}
puts "INFO: impl_1 status = [get_property STATUS [get_runs impl_1]]"

# ------------------------------------------------- 4. reports + XSA + copies
open_run impl_1

set out_dir [file normalize "$build_dir/release_files"]
file mkdir $out_dir

report_utilization    -file [file join $out_dir utilization.rpt]
report_timing_summary -file [file join $out_dir timing_summary.rpt]
report_drc            -file [file join $out_dir drc.rpt]

write_hw_platform -fixed -include_bit -force -file [file join $out_dir design_1.xsa]

proc find_first {pattern} {
    set hits [glob -nocomplain -types f $pattern]
    if { [llength $hits] == 0 } {
        return ""
    }
    return [lindex $hits 0]
}

set bit_src [find_first [file join $build_dir "*" "*.runs" "impl_1" "*.bit"]]
set hwh_src [find_first [file join $build_dir "*" "*.gen" "sources_1" "bd" "design_1" "hw_handoff" "*.hwh"]]
if { $hwh_src eq "" } {
    set hwh_src [find_first [file join $build_dir "*" "*.runs" "impl_1" "*.hwh"]]
}

if { $bit_src eq "" } {
    puts "ERROR: no .bit file found under $build_dir"
    error "bitstream missing"
}

file copy -force $bit_src [file join $out_dir logic_analyzer.bit]
puts "INFO: bit copied from $bit_src"

if { $hwh_src eq "" } {
    puts "ERROR: no .hwh file found, the Overlay will not load without it"
} else {
    file copy -force $hwh_src [file join $out_dir logic_analyzer.hwh]
    puts "INFO: hwh copied from $hwh_src"
}

puts "============================================================"
puts "DONE. Release files are in: $out_dir"
puts "  logic_analyzer.bit / logic_analyzer.hwh  -> board test"
puts "  design_1.xsa                             -> reproduce / archive"
puts "  utilization.rpt / timing_summary.rpt / drc.rpt -> report"
puts "Check WNS in timing_summary.rpt before you call it a release."
puts "Do NOT copy these into repo/pynq before the 10-21 comparison."
puts "============================================================"
