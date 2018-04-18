# Dockerfile for the environment to compile a MOSES server
# gleusch@ebay.com

FROM matrim/cmake-examples:2.8.12.2 as builder
WORKDIR /home/devuser/build
COPY ./ /home/devuser/build/

ENV TERM linux

# git must be pulled locally
# RUN git submodule init && git submodule update

# Install libraries
# autoconf              to build irstlm
# git                   to install irstlm
# google-perftools      for tcmalloc
# libbz-2               for .bz2 support 
# libtool               to build irstlm

RUN sudo apt-get update && \
    sudo apt-get install -y \
        autoconf \
        git \
        google-perftools \
        libbz2-dev \
        libtool


RUN make -f contrib/Makefiles/install-dependencies.gmake




