#!/bin/bash
#
# List of available containers:
#  wget -q https://registry.hub.docker.com/v1/repositories/neuropoly/sct/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}'

# simg file
#sudo singularity build sct.simg Singularity.v4.0.0-beta.0

# sandbox
sudo singularity build --sandbox sandbox Singularity.v4.0.0-beta.0
