#!/bin/bash
#
# Process mFFE:
#    Compute T1W from multiecho mFFE
#    Segmentation
#    Registration to atlas
#    Extract cross-sectional area

# For X11 forwarding when running within docker container
export DISPLAY=host.docker.internal:0


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

# Working dir
cd ../OUTPUTS

# Get files
cp ../INPUTS/mffe_e1.nii.gz mffe.nii.gz

# Segment cord
sct_deepseg_sc -i mffe.nii.gz -c t2

# Auto-label vertebrae. The C3/C4 disc is at FOV center in this case. We should 
# expose this option (initcenter or initz) in general e.g.
#  sct_label_vertebrae -i t2.nii.gz -s t2_seg_manual.nii.gz "$(< init_label_vertebrae.txt)"
sct_label_vertebrae -i mffe.nii.gz -s mffe_seg.nii.gz -c t2 -initcenter 3

# Create the specific labels we need for template registration - for -l option
#sct_label_utils -i mffe_seg_labeled.nii.gz -vert-body 3,4

exit 0

# Create mask
sct_create_mask -i mffe.nii.gz -p centerline,mffe_seg.nii.gz -size 35mm -o mask.nii.gz

# Crop data for faster processing
#sct_crop_image -i mffe.nii.gz -m mask.nii.gz -o m_mffe.nii.gz
#sct_crop_image -i mffe_seg.nii.gz -m mask.nii.gz -o m_mffe_seg.nii.gz

# Default registration to template
# This has multiple bugs in 3.2.4
sct_register_to_template -i mffe.nii.gz -s mffe_seg.nii.gz \
-ldisc mffe_seg_labeled_discs.nii.gz -c t2

# Register template->T1w_ax (using template-T1w as initial transformation)
#sct_register_to_template -i mffe.nii.gz -s mffe_seg.nii.gz \
#-ldisc mffe_seg_labeled_discs.nii.gz -ref subject -c t2 \
#-param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:\
#step=2,type=im,algo=bsplinesyn,metric=CC,iter=5,gradStep=0.5

# Warp template
#sct_warp_template -d m_mffe.nii.gz -w warp_template2anat.nii.gz

