# Actually build Moses. You need to have built Dockerfile.builder as ${USER}/moses-builder
ARG USER
FROM ${USER}/mosesserver-builder:latest 
WORKDIR /home/devuser/build


ARG COMPILEOPT
RUN ./compile.sh ${COMPILEOPT}


FROM ubuntu:14.04
WORKDIR /opt/bin/
COPY --from=0 /home/devuser/build/bin/ /opt/bin/
