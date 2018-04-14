Docker images for Moses
=======================

These are docker images containing a Moses decoder/server (and the other Moses binaries). 


Build
=====

In the parent directory, run

```
docker build -t gleusch/mosesserver -f docker/Dockerfile .
docker build -t gleusch/mosesserver-build -f docker/Dockerfile.build .
```

You should change the user name accordingly.


Use image
=========

```
docker run -ti --rm gleusch/mosesserver
```

