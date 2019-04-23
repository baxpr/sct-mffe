
# Orient and copy files
cd ../OUTPUTS
cp ../INPUTS/mffe?.nii.gz .

# Location of template
TDIR=/home/sct/sct_4.0.0-beta.0/data/PAM50/template

# Compute e1+e2+e3
sct_maths -i mffe1.nii.gz -add mffe2.nii.gz mffe3.nii.gz -o mffesum.nii.gz

# Which image will we work on?
MFFE=mffe1

# Segment GM and WM
#    gmseg   :  gray matter
#    wmseg   :  white matter
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
do_seg ${MFFE}

# Get vertebral labels
sct_label_vertebrae -i ${MFFE}.nii.gz -s ${MFFE}_seg.nii.gz -c t2 -initcenter 3 -r 0

# Crop template to relevant levels. sct_register_multimodal is not smart enough to 
# handle non-identical label sets:
cp ${TDIR}/PAM50_label_disc.nii.gz .
python ../scripts/crop_template_labels.py ${MFFE}_seg_labeled_discs.nii.gz ${TDIR}/PAM50_label_disc.nii.gz

# Create synthetic T2 from template
sct_maths -i ${TDIR}/PAM50_gm.nii.gz -add ${TDIR}/PAM50_cord.nii.gz -o PAM50_gw.nii.gz

# Register to template
sct_register_multimodal \
-i ${MFFE}_gw.nii.gz \
-iseg ${MFFE}_seg.nii.gz \
-ilabel ${MFFE}_seg_labeled_discs.nii.gz \
-d PAM50_gw.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii.gz \
-o ${MFFE}_gw_warped.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg,poly=3:\
step=2,type=im,algo=syn

# Warp the original image to template space
sct_apply_transfo -x spline \
-i ${MFFE}.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-w warp_${MFFE}_gw2PAM50_gw.nii.gz \
-o ${MFFE}_warped.nii.gz

# Get a NN resampling of the GW image in template space
sct_apply_transfo -x nn \
-i ${MFFE}_gw.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-w warp_${MFFE}_gw2PAM50_gw.nii.gz \
-o ${MFFE}_gw_warped_nn.nii.gz


# Get cross sectional area, etc. CSA can be summed within level but other
# shape params are only per slice
sct_process_segmentation \
-i ${MFFE}_seg.nii.gz \
-p csa \
-vert 1:30 \
-vertfile ${MFFE}_seg_labeled.nii.gz \
-perlevel 1 \
-o ${MFFE}_csa.csv

sct_process_segmentation \
-i ${MFFE}_seg.nii.gz \
-p shape \
-o ${MFFE}_shape.csv

