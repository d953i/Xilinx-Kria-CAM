# Example camera designs for Xilinx Kria KV260 devkit

Complete ISP (Image Signal Processing) pipeline supported for Baremetal and Linux using opensource drivers from AMD (Xilinx).
Tested in Linux (Ubuntu BaseP) using V4L2 subsystem with output to frame buffer and to filesystem.
  
Currently supported cameras:
  - AR1335 on Kria IAS connector (directly to FPGA, not thru ISP AR1302)
  - IMX219 on Kria RPi connector

How to use:
  - Select camera by uncommenting appropriate define in create_project.tcl script
  - Create project by sourcesing create_project.tcl script in Vivado TCL console
  - Run Synth/Implementation and Generate bitstream
    
