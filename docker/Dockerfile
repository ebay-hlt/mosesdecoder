# Actually build Moses. You need to have built Dockerfile.builder as ${USER}/moses-builder
FROM gleusch/mosesserver-builder:latest 
WORKDIR /home/devuser/build


RUN ./compile-noirst.sh


FROM ubuntu:14.04
WORKDIR /opt/bin/
COPY --from=0 /home/devuser/build/bin/ /opt/bin/
