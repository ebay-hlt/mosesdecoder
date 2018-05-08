Docker images for Moses
=======================

These are docker images containing a Moses decoder/server (and the other Moses binaries). 


Build
=====

In the parent directory, run

```
docker build -t ${USER}/mosesserver-builder -f docker/Dockerfile.builder .
docker build -t ${USER}/mosesserver -f docker/Dockerfile --build-arg USER=$USER --build-arg COMPILEOPT=-j4 .
```

Use image
=========

```
docker run -ti --rm gleusch/mosesserver
```

