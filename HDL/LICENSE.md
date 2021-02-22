Most of the code in this folder is from Xillybus and thus licensed under the xillybus conditions further down. Differences are listed directly below

## ./patch_multiplier_pipeline/

The following files are not from xillybus and licensed under the MIT license (see the [LICENSE.md](LICENSE.md) in the root directory of the repository):
* any file with the .vhdl ending

The `xillydemo.vhd` is from xillibus but modified by us. Please make a diff to the official `xillydemo.vhd` if you want to see the modifications.

## ./feature_convolution_pipeline/

The following files are not from xillybus and licensed under the MIT license (see the LICENSE.md in the root directory of the repository):
* any file in the srcnn subfolder

The `xillydemo.vhd` is from xillibus but modified by us. Please make a diff to the official `xillydemo.vhd` if you want to see the modifications.

# xillybus license

The different license formats for the Xillybus IP core are listed below. This was accessed from [Xillybus' website](http://xillybus.com/licensing) on 22nd Feb 2021. Please check their website for any changes to these terms.

# Evaluation license

Any IP core downloaded from this site (e.g. a demo bundle from the download area or a core generated in the IP Core Factory) is free for any use, as long as this use reasonably matches the term "evaluation". This includes incorporating the core in end-user designs, running real-life data and field testing. There is no limitation on how the core is used, as long as the sole purpose of this use is to evaluate its capabilities and fitness for a certain application. In case of doubt, please send a description of your intentions to licensing@xillybus.com.
Educational license

The no-fee Educational license is granted for academic purposes: Instruction in classrooms, use in student labs, assignments and student projects as well as in research projects with limited or no budget. Projects that are intended for commercial products or services, or the development of such, are not covered by this license. In case of doubt, please send an email to licensing@xillybus.com with the details of your project.

The Educational license covers any IP core downloaded from this site, including cores generated in the IP Core Factory.

# Production license

After a reasonable evaluation of Xillybus IP cores (possibly generated in the IP Core Factory), commercial clients should apply for a Production license to ensure their legitimate use of the core.

Obtaining a Production License only changes the legal status of the licensed material; there are no licensing keys, dongles or other licensing enforcement methods involved, as the full range of products and services is open for use during the evaluation stage. Accordingly, the deliverable against the licensing fee is a written document, which grants the use of the IP core beyond the limitations of the other, non-fee licenses.

The license is given as a standard SignOnce Site license for cores targeting Xilinx FPGAs, and a similar license for Altera FPGAs. These licenses involve a single, one-off licensing fee payment against the permission to involve a specific IP core in an unlimited number of FPGAs and/or FPGA projects.

This specific IP core is generated and downloaded from the IP Core Factory prior to the licensing process. Its ID number is explicitly written in the licensing document, and hence covers only the IP core with that ID.

# Obtaining quotes

The fee for a Production license varies between 25,000 and 85,000 USD, depending on the configuration and performance requirements.

Budgetary quotes (given as plain emails), as well as formal ones, are given for a specific IP core from the IP Core Factory. As the pricing of Xillybus' IP cores depends on the attributes of the core, this method allows an accurate and concise communication of the needs and expectations.

The procedure for obtaining a quote (formal and budgetary alike) is thus:

   * Register at the IP Core Factory.
   * Configure an IP core that accurately matches your requirements.
   * Generate and download the IP core bundle.
   * Possibly test the IP core in the target FPGA design.
   * Note the IP core ID from the custom IP core bundle's README file (a five-digit number).
   * Send a request for quote to licensing@xillybus.com, stating this core ID.

It's recommended to set up the IP core according to the FPGA project's natural requirements, possibly including extra utility streams for various less important purposes. These extra streams typically have a low impact on the licensing fee, if at all, but may add a significant value to the IP core.

# Free software
## Host driver for Windows

The Xillybus Windows driver is given in binary format. Any use and distribution of this software is allowed.
## Host driver for Linux

The Xillybus Linux driver is free software, released under GPLv2, exactly like most of the Linux kernel itself. You are free to copy and use these drivers. Please refer to the license text for details.
## Linux distributions

The Linux distributions offered on the site (Xillinux images as well as the Xillybus mini-distro for Microblaze) are released under GPL, and can be used with no restriction like any Linux distribution such as RHEL, Fedora, Ubuntu etc.
