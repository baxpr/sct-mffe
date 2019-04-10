
# Orient and copy files
TDIR=/home/sct/sct_4.0.0-beta.0/data/PAM50/template
cd ../OUTPUTS
cp ../INPUTS/mffe?.nii.gz .

# Compute e1+e2+e3
sct_maths -i mffe1.nii.gz -add mffe2.nii.gz mffe3.nii.gz -o mffesum.nii.gz

# Compare GM seg of e1 vs sum
# In current test subject, the echo1 image has decent segmentation but 
# summed echo image does not
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


# sct_register_multimodal is not smart enough to handle non-identical label sets:
# Exception: Error: number of source and destination landmarks are not the same,
# so landmarks cannot be paired.
# Solution would be to copy template label and remove ones we don't have in mffe
# cp ${TDIR}/PAM50_label_disc.nii.gz .
# gunzip PAM50_label_disc.nii.gz
# gunzip -k mffe1_seg_labeled_discs.nii.gz
# crop_template_labels.m

# Register GM segmentation to GM template - syn
# Works well but will probably be garbage outside the GM region
sct_register_multimodal \
-i mffe1_gmseg.nii.gz \
-iseg mffe1_seg.nii.gz \
-ilabel mffe1_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_gm.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii \
-o mffe1_gmseg_lss.nii.gz \
-owarp mffe1_gmseg_lss_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg,poly=3:\
step=2,type=im,algo=syn


# Register GM segmentation to GM template - affine
# Works less well but might be ok outside the GM region
sct_register_multimodal \
-i mffe1_gmseg.nii.gz \
-iseg mffe1_seg.nii.gz \
-ilabel mffe1_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_gm.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii \
-o mffe1_gmseg_lsa.nii.gz \
-owarp mffe1_gmseg_lsa_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg,poly=3:\
step=2,type=im,algo=affine


# Create GM+WM image and register that
# Really not bad. Anats don't register that well but that's partly due to disagreement
# between PAM t2s and PAM cord seg.
sct_maths -i mffe1_gmseg.nii.gz -add mffe1_seg.nii.gz -o mffe1_gw.nii.gz
sct_maths -i ${TDIR}/PAM50_gm.nii.gz -add ${TDIR}/PAM50_cord.nii.gz -o PAM50_gw.nii.gz

sct_register_multimodal \
-i mffe1_gw.nii.gz \
-iseg mffe1_seg.nii.gz \
-ilabel mffe1_seg_labeled_discs.nii.gz \
-d PAM50_gw.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii \
-o mffe1_gw_lss.nii.gz \
-owarp mffe1_gw_lss_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg,poly=3:\
step=2,type=im,algo=syn



# Bring along image
sct_apply_transfo -x spline \
-i mffe1.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-w mffe1_gmseg_lss_warp.nii.gz \
-o mffe1_warped_gmlss.nii.gz

sct_apply_transfo -x spline \
-i mffe1.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-w mffe1_gmseg_lsa_warp.nii.gz \
-o mffe1_warped_gmlsa.nii.gz

sct_apply_transfo -x spline \
-i mffe1.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-w mffe1_gw_lss_warp.nii.gz \
-o mffe1_warped_gwlss.nii.gz

