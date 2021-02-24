# Short README for the HDL directory

This directory contains, besides a license file, two different subdirectories.

1. ["./patch_multiplier_pipeline"](patch_multiplier_pipeline/)
2. ["./feature_convolution_pipeline"](feature_convolution_pipeline/)
   
Both are HDL implementations that try to accelerate the image convolution, the second being the newer, faster and more complex solution.  
Each directory provides a ready-to-use bitstream but also a README that describes the setup and build process of the HDL design.

If you want to run the image convolution, please make sure to use the right software implementation with its corresponding HDL implementation.  
The `mode` argument of the Python script in `../Cython/` requires `fpga1` for the bitstream of the  `patch_multiplier_pipeline` implementation and `fpga2` for the `feature_convolution_pipeline`.