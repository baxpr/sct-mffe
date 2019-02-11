#!/bin/bash
#
# Process mFFE:
#    Compute T1W from multiecho mFFE
#    Segmentation
#    Registration to atlas
#    Extract cross-sectional area

# For X11 forwarding when running within docker container
export DISPLAY=host.docker.internal:0

# Working dir
cd ../OUTPUTS

# Average echoes from multiecho mFFE
# Poor result from segmentation in this particular case
#sct_maths -i mffe_e1.nii.gz -add mffe_e2.nii.gz,mffe_e3.nii.gz -o ../OUTPUTS/mffe_sum.nii.gz

# Spinal cord
#sct_propseg -i ../INPUTS/mffe.nii.gz -c t2 -ofolder OUTPUTS -CSF -cross -centerline-binary

#-qc OUTPUTS/qc_deepseg_sc
#sct_deepseg_sc -i ../INPUTS/mffe_e1.nii.gz -c t2

# Gray matter
#sct_segment_graymatter
#sct_deepseg_gm -i ../INPUTS/mffe_e1.nii.gz -o mffe_e1_gm.nii.gz

# White matter = cord - gray matter


# Segment cord
sct_deepseg_sc -i ../INPUTS/mffe_e1.nii.gz -c t2

# Create mask
sct_create_mask -i ../INPUTS/mffe_e1.nii.gz -p centerline,mffe_e1_seg.nii.gz -size 40mm -o mffe_e1_mask.nii.gz

# Crop data for faster processing
sct_crop_image -i ../INPUTS/mffe_e1.nii.gz -m mffe_e1_mask.nii.gz -o mffe_e1_crop.nii.gz

# Auto-label vertebrae
sct_label_vertebrae -i mffe_e1_crop.nii.gz -s mffe_e1_seg.nii.gz -c t2 -initcenter 3


# Create label 4 at the mid-FOV, because we know the FOV is centered at C3-C4 disc.
sct_label_utils -i mffe_e1_seg.nii.gz -create-seg -1,4 -o label_c3c4.nii.gz

# Register template->T1w_ax (using template-T1w as initial transformation)
# As it stands, this does not get the Z direction correct
sct_register_to_template -i mffe_e1_crop.nii.gz -s mffe_e1_seg.nii.gz \
-ldisc label_c3c4.nii.gz -ref subject -c t2 \
-param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,\
algo=bsplinesyn,metric=MeanSquares,iter=5,gradStep=0.5

# Warp template
sct_warp_template -d mffe_e1_crop.nii.gz -w warp_template2anat.nii.gz

