# FPGA Hardware Getting-Started

This guide described how to get the bitstream of the feature_convolution_pipeline HDL design.  
It also describes which steps we had to do in order to get the custom Xillybus IP Core files,
but we have already added these files to this repository.

---

## Step1: Download xillinux zedboard evaluation

Go to http://xillybus.com/xillinux and download the "boot partition kit" for the Zedboard.
(On the main page, scroll down to section "Download" and click on "Zedboard").  
Extract the downloaded zip folder. This will be your workplace for this HDL project.

### Step1.1: If you just want to build our project
Copy the following files from the git repository into the xillinux evaluation folder structure:  
Replace the files 
  - xillybus.v _( /vhdl/src )_
  - xillybus_core.v _( /vhdl/src )_
  - xillydemo.vhd _( /vhdl/src )_
  - xillybus_core.ngc _( /cores )_

in the demo project with the files from this repository _( ./xillinux-eval-zedboard-2.0c/* )_.

__Now you can skip the next steps__ and directly __jump to [Step 6](##Step6:-Execute-TCL-script-of-xillydemo)__.

---

## Step2: Follow the Xillybus Getting-Started Guide

On [this page](http://xillybus.com/downloads/doc/xillybus_getting_started_zynq.pdf), a getting-started guide for Xillybus on Zynq can be found
Follow the instructions in section 3.3.3 "Preparing xillydemo.vhd".

---

## Step3: Generate custom Xillybus IP core

- Visit http://xillybus.com/ipfactory/ and register an account.
- Generate an AXI Xillybus core for Zynq-7000
- Following interfaces had to be added/present for our design:
   - xillybus_read_32:
     - 32bit, upstream, 195 MB/s, Data acquisition/playback (asynchronous stream)
   - xillybus_write_feature_32:
     - 32bit, downstream, 160MB/s, Data exchange with coprocessor (asynchronous stream)
   - xillybus_write_kernel_32:
     - 32bit, downstream, 160MB/s, Data exchange with coprocessor (asynchronous stream)
   - xillybus_config:
     - 32bit, downstream, 1MB/s, Address/data interface 5bit (synchronous, addressable stream)
   - xillybus_command:
     - 8bit, downstream, 1MB/s, General purpose, __synchronous!__
     - uncheck autoset internals, 4 buffers, 4kB buffers

---

## Step4: Follow README of your Custom Xillybus IP Core
Replace the xillybus.v and xillybus_core.v files ( /vhdl/src ) and xillybus_core.ngc ( /cores ) in the demo project.  
Change parts of the xillydemo.vhd according to the instantiation template.

---

## Step5: Instantiate your own design in xillydemo.vhd and connect the ports
Now the self-written design can be instantiated in xillydemo.vhd.  
The interfaces that have been defined during Xillybus IP Core generation can be connected to your design.  
For asynchronous streams the example FIFOs may be suitable.

Again, for this project, we have already done this step.  
__DO NOT__ change xillydemo.vhd by yourself, but use the file delivered with this repository, if you want to build our HDL code.

---

## Step6: Execute TCL script of xillydemo
Follow the Xillybus Getting-Started guide section 3.3.4:

- Open Vivado
- Select Tools > Run Tcl Script...
- Select the script "xillydemo-vivado.tcl" in the /vhdl directory of the xillydemo.

---

## Step7: When the Vivado project has been created
- Add the design sources in the ./srcnn folder.
- Modify the compile order: config_pkg.vhdl should be the first of the srcnn files.

---

## Step8: Instantiate the multiplier IP Core

- Click "IP Catalog", and select "Math Functions > Multipliers > Multiplier"
- The name of the generated IP Core should be "mult_gen_0"
- Select "Parallel Multiplier", with A and B being signed 32-bit inputs
- The "Use Mults" and "Speed Optimized" options should be selected
- Switch to the "Output and Control" tab and select 2 pipeline stages with a "Clock Enable" function
- Click OK and select "Global" synthesis option
- Generate

---

## Step9: Synthesize design and generate bitstream
Now you can run the synthesis and implementation od the design in Vivado.

In the case that you receive up to 11 critical warnings, this could still be OK as there exists an issue with the demo project.  
You can look at https://forums.xilinx.com/t5/Design-Entry/Vivado-critical-warning-when-creating-hardware-wrapper/td-p/762938 for further detail.



