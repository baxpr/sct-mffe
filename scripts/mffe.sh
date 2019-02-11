#!/bin/bash
#
# Process mFFE:
#    Compute T1W from multiecho mFFE
#    Segmentation
#    Registration to atlas
#    Extract cross-sectional area

# Compute T1W from multiecho mFFE
# Register the echoes
# Compute the computation

# Spinal cord
#sct_propseg
sct_deepseg_sc

# Gray matter
#sct_segment_graymatter
sct_deepseg_gm

# White matter = cord - gray matter
sct_maths
