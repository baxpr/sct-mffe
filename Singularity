Bootstrap: docker
From: ubuntu:16.04

%help

  SCT

%files


%labels
  Maintainer baxter.rogers@vanderbilt.edu

%post
  apt-get update
  apt-get install -y wget unzip zip xvfb

  # Download and install Spinal Cord Toolbox
  wget -nv -P /opt https://github.com/neuropoly/spinalcordtoolbox/archive/v3.2.7.tar.gz
  cd /opt
  tar -zxf spinalcordtoolbox-3.2.7.tar.gz
  rm spinalcordtoolbox-3.2.7.tar.gz
  cd spinalcordtoolbox-3.2.7
  env \
    SCT_INSTALL_TYPE=in-place \
    ASK_REPORT_QUESTION=false \
    change_default_path=yes \
    ./install_sct

  # Create input/output directories for binding
  mkdir /INPUTS && mkdir /OUTPUTS

%runscript
  bash "$@"
