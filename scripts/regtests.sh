
cd ../OUTPUTS
cp ../INPUTS/mffe_e1.nii.gz ./mffe.nii.gz
cp ../INPUTS/fmri.nii.gz .

TDIR=/home/sct/sct_4.0.0-beta.0/data/PAM50/template

# Segment
#   mffe_seg                            cord label
#   mffe_{gm,wm}_seg                    gray, white labels
#   image_in_RPI_resampled_seg.nii.gz   ??
sct_deepseg_sc -i mffe.nii.gz -c t2
sct_deepseg_gm -i mffe.nii.gz
sct_maths -i mffe_seg.nii.gz -sub mffe_gmseg.nii.gz -o tmp.nii.gz
sct_maths -i tmp.nii.gz -thr 0 -o mffe_wmseg.nii.gz
rm tmp.nii.gz

# Label (includes straighten, sort of)
#   mffe_seg_labeled_discs     disc points (subj space)
#   mffe_seg_labeled           full labels (subj space)
#   straight_ref               mffe in straight space
#   warp_straight2curve        straight to subj
#   warp_curve2straight        subj to straight
#   straightening.cache        ??
# Other files in tmp dir with -r 0
sct_label_vertebrae -i mffe.nii.gz -s mffe_seg.nii.gz -c t2 -initcenter 3 -r 0

# We may be able to use sct_straighten_spinalcord directly or in addition to get
# image and labels in straightened space

# Register label+seg+im to template
#   Label step: Tx_Ty_Tz_Sz is the min dof required
#   Seg step: use translation, rigid, or affine
#   Im step: use affine or syn
#
# Try:
#   mask on destination image (template) with -m
#   crop source image e.g. 50mm around centerline (for speed)
#   shrink factor in first Im step (for speed)
#   smooth in first Im step (for accuracy)
#   smaller mask for final Im step to just get cord/CSF

# sct_register_multimodal is not smart enough to handle non-identical label sets:
# Exception: Error: number of source and destination landmarks are not the same,
# so landmarks cannot be paired.
# Solution would be to copy template label and remove ones we don't have in mffe
# cp ${TDIR}/PAM50_label_disc.nii.gz .
# gunzip PAM50_label_disc.nii.gz
# gunzip -k mffe_seg_labeled_discs.nii.gz
# crop_template_labels.m

# This works halfway well. Some 0.5-1mm errors in registration of GM, cord edges
# Can we add in-plane rotation? E.g. image based with aggressive mask
# ls = label, slicewise seg
sct_register_multimodal \
-i mffe.nii.gz \
-iseg mffe_seg.nii.gz \
-ilabel mffe_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii \
-o mffe_ls.nii.gz \
-owarp mffe_ls_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg,poly=3

# Bring along the label maps
for map in mffe_seg mffe_gmseg mffe_wmseg mffe_seg_labeled ; do
	sct_apply_transfo -x nn \
	-i ${map}.nii.gz \
	-d ${TDIR}/PAM50_t2s.nii.gz \
	-w mffe_ls_warp.nii.gz \
	-o ${map}_ls.nii.gz
done



# Can we get subject disc points warped to template space?
# Problem: points are an entire huge slice thick (5mm). These really need to be
# handled as discrete point coords rather than by resampling the image.


exit 0


# Expand the template centerline to show dividing GM
sct_maths \
-i ${TDIR}/PAM50_centerline.nii.gz \
-dilate 50,0,0 \
-o PAM50_centerline_plusX.nii.gz

sct_maths \
-i ${TDIR}/PAM50_centerline.nii.gz \
-dilate 0,50,0 \
-o PAM50_centerline_plusY.nii.gz



# la = label, affine seg
# Worse, not usable. Doesn't straighten
sct_register_multimodal \
-i mffe.nii.gz \
-iseg mffe_seg.nii.gz \
-ilabel mffe_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii.gz \
-o mffe_tem_la.nii.gz \
-owarp mffe_tem_la_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=affine

# lr = label, rigid seg
# Also not usable, also doesn't straighten
sct_register_multimodal \
-i mffe.nii.gz \
-iseg mffe_seg.nii.gz \
-ilabel mffe_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii.gz \
-o mffe_tem_lr.nii.gz \
-owarp mffe_tem_lr_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=rigid


# lsa = label, slicewise, affine seg
# Very subtle differences from slicewise only (ls) and still poor reg
# for the gray matter
sct_register_multimodal \
-i mffe.nii.gz \
-iseg mffe_seg.nii.gz \
-ilabel mffe_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii.gz \
-o mffe_tem_lsa.nii.gz \
-owarp mffe_tem_lsa_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg:\
step=2,type=seg,algo=affine


# lsi
# No improvement
sct_register_multimodal \
-i mffe.nii.gz \
-iseg mffe_seg.nii.gz \
-ilabel mffe_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii.gz \
-o mffe_tem_lsi.nii.gz \
-owarp mffe_tem_lsi_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg:\
step=2,type=im,algo=affine

# lsisyn with mask
# Fails, no output
sct_register_multimodal \
-i mffe.nii.gz \
-iseg mffe_seg.nii.gz \
-ilabel mffe_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii.gz \
-o mffe_tem_lsisyn.nii.gz \
-owarp mffe_tem_lsisyn_warp.nii.gz \
-m mask.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg:\
step=2,type=im,algo=syn


# next try two steps, ls, then im with -initwarp and tight mask
# Perhaps a marginal improvement with affine?
sct_create_mask \
-i ${TDIR}/PAM50_cord.nii.gz \
-p centerline,${TDIR}/PAM50_cord.nii.gz \
-size 20mm \
-o mask.nii.gz

sct_register_multimodal \
-i mffe.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-initwarp mffe_ls_warp.nii.gz \
-o mffe_lsm.nii.gz \
-owarp mffe_lsm_warp.nii.gz \
-m mask.nii.gz \
-param step=1,type=im,algo=affine,metric=CC

# Bring along the label maps
for map in mffe_seg mffe_gmseg mffe_wmseg mffe_seg_labeled ; do
	sct_apply_transfo -x nn \
	-i ${map}.nii.gz \
	-d ${TDIR}/PAM50_t2s.nii.gz \
	-w mffe_lsm_warp.nii.gz \
	-o ${map}_lsm.nii.gz
done


# try with syn
# Might need this, seems some kind of process timer isn't working right:
#   Note: you can opt out of Sentry reporting by editing the file 
#   ${SCT_DIR}/bin/sct_launcher and delete the line starting with "export SENTRY_DSN"
# Nope still failed. But failed step works when run directly in temp dir ????
sct_register_multimodal \
-i mffe.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz \
-initwarp mffe_tem_ls_warp.nii.gz \
-o mffe_tem_ls_ms.nii.gz \
-owarp mffe_tem_ls_ms_warp.nii.gz \
-m mask.nii.gz \
-param step=1,type=im,algo=syn





# lk1 Kurt suggestion 1 plus labels
# Too much warpiness, poor registration
sct_register_multimodal \
-i mffe.nii.gz -iseg mffe_seg.nii.gz \
-ilabel mffe_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz -dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii.gz \
-o mffe_lk1.nii.gz \
-owarp mffe_lk1_warp.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg,metric=MeanSquares:\
step=2,type=seg,algo=affine,metric=MeanSquares,gradStep=0.2:\
step=3,type=im,algo=syn,metric=MI,iter=5,shrink=2


# lkm1 Kurt + label + mask
# Some parts good, some parts poor
sct_register_multimodal \
-i mffe.nii.gz -iseg mffe_seg.nii.gz \
-ilabel mffe_seg_labeled_discs.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz -dseg ${TDIR}/PAM50_cord.nii.gz \
-dlabel PAM50_label_disc_cropped.nii.gz \
-o mffe_lkm1.nii.gz \
-owarp mffe_lkm1_warp.nii.gz \
-m mask.nii.gz \
-param step=0,type=label,dof=Tx_Ty_Tz_Sz:\
step=1,type=seg,algo=slicereg,metric=MeanSquares:\
step=2,type=seg,algo=affine,metric=MeanSquares,gradStep=0.2:\
step=3,type=im,algo=syn,metric=MeanSquares,iter=5,shrink=2


exit 0


# k1 Kurt suggestion 1
sct_register_multimodal \
-i mffe.nii.gz -iseg mffe_seg.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz -dseg {TDIR}/PAM50_t2s_seg.nii.gz \
-o mffe_k1.nii.gz \
-owarp mffe_k1_warp.nii.gz \
-param step=1,type=seg,algo=slicereg,metric=MeanSquares:\
step=2,type=seg,algo=affine,metric=MeanSquares,gradStep=0.2:\
step=3,type=im,algo=syn,metric=MI,iter=5,shrink=2

# Kurt suggestion 2
#-param step=1,type=seg,algo=affine,metric=MeanSquares,smooth=0,iter=20,gradStep=2:\
#step=2,type=seg,algo=affine,metric=MeanSquares,smooth=0,iter=10,gradStep=.5:\
#step=3,type=im,algo=syn,metric=MeanSquares,smooth=0,iter=10,gradStep=.5

# Add label step
# mffe_seg_labeled_discs matches PAM50_label_disc
sct_register_multimodal \
-i mffe.nii.gz -iseg mffe_seg.nii.gz -ilabel mffe_seg_labeled_discs.nii.gz \
-d PAM50_t2s.nii.gz -dseg PAM50_t2s_seg.nii.gz -dlabel PAM50_label_disc.nii.gz \
-o mffe_tem.nii.gz \
-owarp mffe_tem_warp.nii.gz \
-param step=1,type=seg,algo=slicereg,metric=MeanSquares:\
step=2,type=seg,algo=affine,metric=MeanSquares,gradStep=0.2:\
step=3,type=im,algo=syn,metric=MI,iter=5,shrink=2
