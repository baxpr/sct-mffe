
Vsubj = spm_vol('../OUTPUTS/mffe1_seg_labeled_discs.nii');
Ysubj = spm_read_vols(Vsubj);

Vtem = spm_vol('../OUTPUTS/PAM50_label_disc.nii');
Ytem = spm_read_vols(Vtem);

vals = unique(Ysubj);
Ytem(~ismember(Ytem(:),vals)) = 0;

Vout = Vtem;
Vout.fname = '../OUTPUTS/PAM50_label_disc_cropped.nii';
spm_write_vol(Vout,Ytem);
