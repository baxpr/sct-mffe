#!/bin/bash
#
# Test deepseg on first echo vs mean of three echoes

# Orient and copy files
cd ../OUTPUTS
cp ../INPUTS/mffe?.nii.gz .

# Compute e1+e2+e3
sct_maths -i mffe1.nii.gz -add mffe2.nii.gz mffe3.nii.gz -o mffesum.nii.gz

# Segment GM and WM
#    gmseg   :  gray matter
#    wmseg   :  gray matter
#    seg     :  cord
#    gw      :  synthetic T2 (GM=2, WM=1)
do_seg () {
	sct_deepseg_sc -i "${1}".nii.gz -c t2
	sct_deepseg_gm -i "${1}".nii.gz
	sct_maths -i "${1}"_seg.nii.gz -sub "${1}"_gmseg.nii.gz -o tmp.nii.gz
	sct_maths -i tmp.nii.gz -thr 0 -o "${1}"_wmseg.nii.gz
	rm tmp.nii.gz
	sct_maths -i "${1}"_gmseg.nii.gz -add "${1}"_seg.nii.gz -o "${1}"_gw.nii.gz
}
do_seg mffe1
do_seg mffesum


