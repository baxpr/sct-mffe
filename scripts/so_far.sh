#!/bin/bash

# For X11 forwarding when running within docker container (only needed for QCs)
#export DISPLAY=host.docker.internal:0

# Images:
#   mffe                       Input mFFE
#   fmri                       Input fMRI time series
#   mffe_seg                   Cord mask
#   mffe_gmseg                 Gray matter mask
#   mffe_wmseg                 White matter mask
#   warp_curve2straight        Warp from mFFE to straightened, from label step
#   warp_straight2curve        Reverse of above
#   straight_ref               Straightened mFFE
#   mffe_seg_labeled           Vertebral body label points
#   mffe_seg_labeled_discs     Disc label points
#   mffe_mask30                30mm mask around cord
#   fmri_moco                  Motion corrected fMRI
#   fmri_moco_mean             Mean fMRI after motion correction
#   fmri_moco_mean_seg         Cord mask
#   fmri_moco_mean_reg         fMRI aligned to mFFE
#   mffe_reg                   mFFE aligned to fMRI
#   warp_mffe2fmri_moco_mean   Warp from mFFE to fMRI
#   warp_fmri_moco_mean2mffe   Warp from fMRI to mFFE

# Get ready
cd ../OUTPUTS
cp ../INPUTS/mffe_e1.nii.gz ./mffe.nii.gz
cp ../INPUTS/fmri.nii.gz .

# Segment cord and gray matter, compute white matter
sct_deepseg_sc -i mffe.nii.gz -c t2
sct_deepseg_gm -i mffe.nii.gz
sct_maths -i mffe_seg.nii.gz -sub mffe_gmseg.nii.gz -o tmp.nii.gz
sct_maths -i tmp.nii.gz -thr 0 -o mffe_wmseg.nii.gz
rm tmp.nii.gz

# Auto-label vertebrae. The C3/C4 disc is at FOV center in this case. We should 
# expose this option (initcenter or initz) in general e.g.
#  sct_label_vertebrae -i t2.nii.gz -s t2_seg_manual.nii.gz "$(< init_label_vertebrae.txt)"
# It is possible to Manage Files in XNAT GUI and add a suitable file as a 
# scan resource, but it's two-step process (Add Folder, Upload File)
# Maybe write a script to find scans with missing level file and upload?
sct_label_vertebrae -i mffe.nii.gz -s mffe_seg.nii.gz -c t2 -initcenter 3

# Create mask for registration
sct_create_mask -i mffe.nii.gz -p centerline,mffe_seg.nii.gz -size 30mm \
-o mffe_mask30.nii.gz

# fMRI motion correction
sct_fmri_moco -i fmri.nii.gz 

# Find cord on mean fMRI to improve registration
sct_deepseg_sc -i fmri_moco_mean.nii.gz -c t2s

# Register mean fMRI to mFFE
sct_register_multimodal \
-i fmri_moco_mean.nii.gz -iseg fmri_moco_mean_seg.nii.gz \
-d mffe.nii.gz -dseg mffe_seg.nii.gz \
-m mffe_mask30.nii.gz \
-param step=1,type=seg,algo=centermass,metric=MeanSquares,smooth=2:\
step=2,type=im,algo=slicereg,metric=MI


# To try:

# Create straightened label map

# Register straightened mFFE to template
#sct_register_multimodal \
#-i straight_ref.nii.gz -iseg straight_seg.nii.gz \
#-d PAM50_t2s.nii.gz -dseg PAM50_t2s_seg.nii.gz \
#-m mffe_mask30.nii.gz \
#-param step=1,type=seg,algo=centermass,metric=MeanSquares,smooth=2:\
#step=2,type=im,algo=slicereg,metric=MI
