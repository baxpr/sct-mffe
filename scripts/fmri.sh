#!/bin/bash
#
# Process fMRI:
#    Motion correction
#    Registration to mFFE
#    Warp to atlas space
#    ROI time series extraction

# Eventually we need topup in our container so we can apply to these fmri

cd ../OUTPUTS
cp ../INPUTS/fmri.nii.gz .

sct_fmri_moco -i fmri.nii.gz 
