#!/bin/bash
#
# Process mFFE:
#    Compute T1W from multiecho mFFE
#    Segmentation
#    Registration to atlas
#    Extract cross-sectional area

# For X11 forwarding when running within docker container
export DISPLAY=host.docker.internal:0

# Compute T1W from multiecho mFFE
# Register the echoes
# Compute the computation

# Spinal cord
sct_propseg -i ../INPUTS/mffe.nii.gz -c t2 -ofolder OUTPUTS -CSF -cross -centerline-binary

#-qc OUTPUTS/qc_deepseg_sc
sct_deepseg_sc -i ../INPUTS/mffe.nii.gz -c t2 -ofolder OUTPUTS 

# Gray matter
#sct_segment_graymatter
sct_deepseg_gm -i INPUTS/mffe.nii.gz -o OUTPUTS/mffe_gm.nii.gz

# White matter = cord - gray matter
sct_maths
