
# Orient and copy files
cd ../OUTPUTS
cp ../INPUTS/mffe?.nii.gz .

# Compute e1+e2+e3
sct_maths -i mffe1.nii.gz -add mffe2.nii.gz mffe3.nii.gz -o mffesum.nii.gz

# Compare GM seg of e1 vs sum
do_seg () {
	tag=`basename "${1}" .nii.gz`
	sct_deepseg_sc -i "${tag}".nii.gz -c t2
	sct_deepseg_gm -i "${tag}".nii.gz
	sct_maths -i "${tag}"_seg.nii.gz -sub "${tag}"_gmseg.nii.gz -o tmp.nii.gz
	sct_maths -i tmp.nii.gz -thr 0 -o "${tag}"_wmseg.nii.gz
	rm tmp.nii.gz
}
do_seg mffe1.nii.gz
do_seg mffesum.nii.gz

# Same for labels
sct_label_vertebrae -i mffe1.nii.gz -s mffe1_seg.nii.gz -c t2 -initcenter 3 -r 0
sct_label_vertebrae -i mffesum.nii.gz -s mffesum_seg.nii.gz -c t2 -initcenter 3 -r 0

