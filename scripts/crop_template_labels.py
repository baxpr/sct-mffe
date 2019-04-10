#!/usr/bin/python

import nibabel
import sys
import numpy

subject_fname = sys.argv[1]
template_fname = sys.argv[2]

subject_img = nibabel.load(subject_fname)
subject_vals = numpy.unique(subject_img.get_fdata())
print(subject_vals)

template_img = nibabel.load(template_fname)
template_data = template_img.get_fdata()
print(numpy.unique(template_data))

inds = numpy.isin(template_data,subject_vals)
template_data[numpy.logical_not(inds)] = 0
print(numpy.unique(template_data))

cropped_template_img = nibabel.Nifti1Image(template_data,template_img.affine,template_img.header)
nibabel.save(cropped_template_img,'PAM50_label_disc_cropped.nii.gz')
