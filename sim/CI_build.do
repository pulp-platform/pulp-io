# @Author: Alfio Di Mauro
# @Date:   2019-10-09 17:14:10
# @Last Modified by:   Alfio Di Mauro
# @Last Modified time: 2019-10-15 12:33:06
puts {
  ModelSim general compile script version 1.2
  Copyright (c) Doulos June 2017, SD
}

# Simply change the project settings in this section
# for each new project. There should be no need to
# modify the rest of the script.

set include_dir ../rtl/include

## parse dependencies
set filename ips_file_list.txt
set ip_design_files {}
set f [open $filename r]
foreach line [split [read $f] \n] {
    set ip_design_files $ip_design_files$line
}
## parse design files
set filename svh_file_list.txt
set svh_design_files {}
set f [open $filename r]
foreach line [split [read $f] \n] {
    set svh_design_files $svh_design_files$line
}
## parse design files
set filename rtl_file_list.txt
set rtl_design_files {}
set f [open $filename r]
foreach line [split [read $f] \n] {
    set rtl_design_files $rtl_design_files$line
}

set library_file_list {
                          
                          ips_dep_library {$ip_design_files}
                          design_library  {$rtl_design_files $svh_design_files}
                          test_library    {../tb/udma_subsystem_tb.sv}
}

set library_file_list [subst -nocommands $library_file_list]

set top_level              test_library.udma_subsystem_tb
set wave_patterns {}
set wave_radices {
                           hexadecimal {data q}
}

# After sourcing the script from ModelSim for the
# first time use these commands to recompile.

proc rw  {} {uplevel #0 source compile.tcl
            w }
proc r  {} {uplevel #0 source compile.tcl
             }            
proc rr {} {global last_compile_time
            set last_compile_time 0
            r                            }
proc q  {} {quit -force                  }
proc w  {} {do wave.do                   }

#Does this installation support Tk?
set tk_ok 1
if [catch {package require Tk}] {set tk_ok 0}

# Prefer a fixed point font for the transcript
set PrefMain(font) {Courier 10 roman normal}

# Compile out of date files
set time_now [clock seconds]
if [catch {set last_compile_time}] {
  set last_compile_time 0
}
foreach {library file_list} $library_file_list {
  vlib $library
  vmap work $library
  foreach file $file_list {
    if { $last_compile_time < [file mtime $file] } {
      if [regexp {.vhdl?$} $file] {
        vcom -93 $file
      } else {
        vlog $file +incdir+$include_dir -svinputport=net
      }
      set last_compile_time 0
    }
  }
}
set last_compile_time $time_now

# Load the simulation
#eval vsim -c -voptargs=+acc=mbcnprv $top_level -L design_library -L ips_dep_library

# Run the simulation
#run -all

# How long since project began?
if {[file isfile start_time.txt] == 0} {
  set f [open start_time.txt w]
  puts $f "Start time was [clock seconds]"
  close $f
} else {
  set f [open start_time.txt r]
  set line [gets $f]
  close $f
  regexp {\d+} $line start_time
  set total_time [expr ([clock seconds]-$start_time)/60]
  puts "Project time is $total_time minutes"
}