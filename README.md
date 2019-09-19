# Astraea Geo Swiss Army Knife Docker Images

This Dockerfile creates and image with the following:
* Ubuntu 18.04 (Cosmic Cuttlefish)
* GDAL, compiled with HDF4, HDF5, and JPEG2000 (OpenJPEG) support
* Java JRE 8
* Scala and SBT
* Python 3
* AWS CLI

Images generated from this build are published to [https://hub.docker.com/r/s22s/geo-swak]

## Provenance
* GDAL based mostly on [geographica/gdal2](https://github.com/GeographicaGS/Docker-GDAL2), and to a lesser extent 
  [geodata/gdal](https://github.com/geo-data/gdal-docker)
* Java install based on [https://github.com/anapsix/docker-oracle-java8]
* Scala/SBT install based on [hseeberger/scala-sbt](https://github.com/hseeberger/scala-sbt)
* Python install based on [https://askubuntu.com/questions/865554/how-do-i-install-python-3-6-using-apt-get]

## Usage

### Build

    $ docker build --no-cache -t s22s/geo-swak:latest .
    Sending build context to Docker daemon  105.5kB
    Step 1/27 : FROM ubuntu:xenial
    ...
    Successfully built ea85116c15b1
    Successfully tagged s22s/geo-swak:latest
    $ docker push s22s/geo-swak

### Run

Running the container without any arguments will by default output the GDAL
version string as well as the supported raster and vector formats:

    docker run s22s/geo-swak

The following command will open a bash shell in an Ubuntu based environment
with GDAL available:

    docker run -it s22s/geo-swak /bin/bash

You will most likely want to work with data on the host system from within the
docker container, in which case run the container with the -v option. 

    docker run -it -v $(pwd):/data s22s/geo-swak /bin/bash 

Assuming
you have a raster called `test.tif` in your current working directory on your
host system, running the following command should invoke `gdalinfo` on
`test.tif`:

    docker run -it -v $(pwd):/data s22s/geo-swak gdalinfo test.tif

This works because the current working directory is set to `/data` in the
container, and you have mapped the current working directory on your host to
`/data`.

Note that the image tagged `latest`, GDAL represents the latest code *at the
time the image was built*. If you want to include the most up-to-date commits
then you need to build the docker image yourself locally along these lines:

    docker build -t s22s/geo-swak:local git://github.com/geo-data/gdal-docker/
    
Bash functions can make the GDAL tools run as if they were installed locally.  Add this to your 
.bashrc (or .bash_profile, if .bash_profile does not source your .bashrc):

```bash
############################
# start geo-swak functions #
############################

function g {
  docker run -it -v $(pwd):/data s22s/geo-swak "$@"
}

function gdalinfo {
  g gdalinfo "$@"
}

function gdal_translate {
  g gdal_translate "$@"
}

function gdalwarp {
  g gdalwarp "$@"
}

function ogr2ogr {
  g ogr2ogr "$@"
}

function ogrinfo {
  g ogrinfo "$@"
}

##########################
# end geo-swak functions #
##########################
```    

With this, you can just run commands like `gdalinfo band1.tif`, and it will run that command inside the docker container.  
functions can be added for other commands, or they can be run with a command like `g gdalinfo band1.tif`.
If the file are in a directory other than one below the pwd, then then volume mount (-v) as part of the command will need
to be modified. 
