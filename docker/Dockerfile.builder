# Dockerfile for the environment to compile a MOSES server
# gleusch@ebay.com

FROM matrim/cmake-examples:2.8.12.2 as builder
WORKDIR /home/devuser/build
COPY ./ /home/devuser/build/

# git must be pulled locally
# RUN git submodule init && git submodule update

# Install libraries
RUN sudo apt-get update && \
    sudo apt-get install -y libbz2-dev

RUN make -f contrib/Makefiles/install-dependencies.gmake




