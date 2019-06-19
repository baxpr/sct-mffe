#!/bin/bash
#
# Process fMRI:
#    Motion correction
#    Registration to mFFE
#    Warp to atlas space
#    ROI time series extraction

cd ../OUTPUTS
cp ../INPUTS/fmri.nii.gz .

# Which images will we work on?
MFFE=mffe1
FMRI=fmri

# Topup?

# fMRI motion correction
sct_fmri_moco -i ${FMRI}.nii.gz 

# Find cord on mean fMRI to improve registration
sct_deepseg_sc -i ${FMRI}_moco_mean.nii.gz -c t2s

# Create mask for registration
sct_create_mask -i ${MFFE}.nii.gz -p centerline,${MFFE}_seg.nii.gz -size 30mm \
-o ${MFFE}_mask30.nii.gz

# Register mean fMRI to mFFE
sct_register_multimodal \
-i ${FMRI}_moco_mean.nii.gz -iseg ${FMRI}_moco_mean_seg.nii.gz \
-d ${MFFE}.nii.gz -dseg ${MFFE}_seg.nii.gz \
-m ${MFFE}_mask30.nii.gz \
-param step=1,type=seg,algo=centermass,metric=MeanSquares,smooth=2:\
step=2,type=im,algo=slicereg,metric=MI

# Warp subject GM, WM, level to fMRI space (NN interp adequate?)

# Warp template CSF to fMRI space via mFFE space (NN adequate?)

# We want an fMRI QA

# We will also want fMRI results in template space
