# Build a Docker image containing Oracle Java 8

[Download Server JRE 8](http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html) `.tar.gz` file and drop it inside folder `java-8`.

Build it:

```
$ cd java-8
$ docker build -t oracle/serverjre:8-windowsservercore -f windowsservercore/Dockerfile .
$ docker build -t oracle/serverjre:8-nanoserver -f nanoserver/Dockerfile .
```
