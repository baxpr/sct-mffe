#!/bin/bash
#
# Process fMRI:
#    Motion correction
#    Registration to mFFE
#    Warp to atlas space
#    ROI time series extraction

cd ../OUTPUTS
cp ../INPUTS/fmri.nii.gz .

# Topup?

# fMRI motion correction
sct_fmri_moco -i fmri.nii.gz 

# Find cord on mean fMRI to improve registration
sct_deepseg_sc -i fmri_moco_mean.nii.gz -c t2s

# Create mask for registration
sct_create_mask -i mffe1.nii.gz -p centerline,mffe1_seg.nii.gz -size 30mm \
-o mffe1_mask30.nii.gz

# Register mean fMRI to mFFE
sct_register_multimodal \
-i fmri_moco_mean.nii.gz -iseg fmri_moco_mean_seg.nii.gz \
-d mffe1.nii.gz -dseg mffe1_seg.nii.gz \
-m mffe1_mask30.nii.gz \
-param step=1,type=seg,algo=centermass,metric=MeanSquares,smooth=2:\
step=2,type=im,algo=slicereg,metric=MI

# Warp subject GM, WM, level to fMRI space (NN interp adequate?)

# Warp template CSF to fMRI space via mFFE space (NN adequate?)

# We want an fMRI QA

# We will also want fMRI results in template space
