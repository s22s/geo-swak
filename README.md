# Astraea Geo Swiss Army Knife Docker Images

This Dockerfile creates and image with the following:
* Ubuntu 16.04 (Xenial Xerus)
* GDAL compiled with JPEG200 support via OpenJPEG
* JRE 8
* Scala and SBT
* Python 3
* AWS CLI

## Provenance
* GDAL based mostly on [geographica/gdal2](https://github.com/GeographicaGS/Docker-GDAL2), and to a lesser extent 
  [geodata/gdal](https://github.com/geo-data/gdal-docker)
* Java install based on [https://github.com/anapsix/docker-oracle-java8]
* Scala/SBT install based on [hseeberger/scala-sbt](https://github.com/hseeberger/scala-sbt)
* Python install based on [https://askubuntu.com/questions/865554/how-do-i-install-python-3-6-using-apt-get]

## Usage

Running the container without any arguments will by default output the GDAL
version string as well as the supported raster and vector formats:

    docker run astraea/geoswak

The following command will open a bash shell in an Ubuntu based environment
with GDAL available:

    docker run -t -i astraea/geoswak /bin/bash

You will most likely want to work with data on the host system from within the
docker container, in which case run the container with the -v option. Assuming
you have a raster called `test.tif` in your current working directory on your
host system, running the following command should invoke `gdalinfo` on
`test.tif`:

    docker run -v $(pwd):/data astraea/geoswak gdalinfo test.tif

This works because the current working directory is set to `/data` in the
container, and you have mapped the current working directory on your host to
`/data`.

Note that the image tagged `latest`, GDAL represents the latest code *at the
time the image was built*. If you want to include the most up-to-date commits
then you need to build the docker image yourself locally along these lines:

    docker build -t astraea/geoswak:local git://github.com/geo-data/gdal-docker/
