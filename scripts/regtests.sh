
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
#   straight_ref               ??
#   warp_straight2curve        straight to subj
#   warp_curve2straight        subj to straight
#   straightening.cache        ??
# Other files in tmp dir with -r 0
sct_label_vertebrae -i mffe.nii.gz -s mffe_seg.nii.gz -c t2 -initcenter 3 -r 0


# Register label+seg+im to template



exit 0


# Kurt suggestion 1
sct_register_multimodal \
-i mffe.nii.gz -iseg mffe_seg.nii.gz \
-d ${TDIR}/PAM50_t2s.nii.gz -dseg {TDIR}/PAM50_t2s_seg.nii.gz \
-o mffe_tem.nii.gz \
-owarp mffe_tem_warp.nii.gz \
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
