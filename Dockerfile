# Geospatial Swiss Army Knife image
FROM openjdk:13-jdk-slim

# UTF-8 all the things
RUN \
    apt-get clean -y && apt-get update && \
    apt-get install -y apt-utils locales && \
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8 && \
    apt-get clean all

# ENVs
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV ROOTDIR /usr/local/
#ENV LD_LIBRARY_PATH /usr/local/lib
#ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
# Load assets
WORKDIR $ROOTDIR/

# pkg-config needed by gdal to find openjpeg
# gdal uses curl, libcurl4
# gdal build uses cmake
RUN \
    apt-get update && \
    apt-get install -y \
        pkg-config \
        software-properties-common \
        python-pip \
        python2.7 \
        python-numpy \
        python3-software-properties \
        python3-pip \
        gcc \
        g++ \
        curl \
        build-essential \
        libcurl4-gnutls-dev \
        file \
        sqlite3 \
        libsqlite3-dev \
        bash-completion \
        cmake \
        wget \
        imagemagick \
    && apt-get clean all

# Install Pip and AWS CLI
RUN pip3 install --upgrade pip awscli

# OPENJPEG versions prior to 2.3.0 have problems processing large jp2 files
# https://lists.osgeo.org/pipermail/gdal-dev/2017-October/047397.html
ENV OPENJPEG_VERSION 2.3.1

# Compile and install OpenJPEG for GDAL
RUN \
    cd $ROOTDIR/src && \
    wget -q https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz && \
    tar -xvf v${OPENJPEG_VERSION}.tar.gz && \
    cd openjpeg-${OPENJPEG_VERSION}/ && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$ROOTDIR && \
    make -j4 && \
    make install && \
    rm -Rf $ROOTDIR/src/openjpeg* $ROOTDIR/src/v${OPENJPEG_VERSION}.tar.gz

ENV PROJ_VERSION 6.3.2

# Compile and install PROJ 6
RUN \
    cd $ROOTDIR/src && \
    wget -q https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz && \
    tar -xvf proj-${PROJ_VERSION}.tar.gz && \
    cd proj-${PROJ_VERSION}/ && \
    ./configure && \
    make -j4 && \
    make install && \
    rm -Rf $ROOTDIR/src/proj-*

ENV GDAL_VERSION 3.1.2

# Compile and install GDAL
# JPEG2000 - used by Sentinel-2, use openjpeg and none of the others
# GeoTIFF - included, use internal version
RUN \
    cd $ROOTDIR/src && \
    wget http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz && \
    tar -xvf gdal-${GDAL_VERSION}.tar.gz && \
    cd gdal-${GDAL_VERSION} && \
    ./configure \
        --with-curl \
        --with-geos \
        --with-geotiff=internal \
        --with-hide-internal-symbols \
        --with-jpeg \
        --with-libtiff=internal \
        --with-libz=internal \
        --with-openjpeg \
        --with-png \
        --with-python \
        --with-threads \
        --without-cfitsio \
        --without-cryptopp \
        --without-ecw \
        --without-expat \
        --without-fme \
        --without-freexl \
        --without-gif \
        --without-gif \
        --without-gnm \
        --without-grass \
        --without-hdf4 \
        --without-hdf5 \
        --without-idb \
        --without-ingres \
        --without-jasper \
        --without-jp2mrsid \
        --without-kakadu \
        --without-libgrass \
        --without-libkml \
        --without-libtool \
        --without-mrsid \
        --without-mysql \
        --without-netcdf \
        --without-odbc \
        --without-ogdi \
        --without-pcidsk \
        --without-pcraster \
        --without-pcre \
        --without-perl \
        --without-pg \
        --without-qhull \
        --without-sde \
        --without-sqlite3 \
        --without-webp \
        --without-xerces \
        --without-xml2 | tee /dev/stderr | grep "OpenJPEG support:\s\+yes" \
    && \
    make -j4 && \
    make install && \
    ldconfig && \
    apt-get remove -y --purge build-essential && \
    apt-get autoremove -y && apt-get clean all && \
    rm -Rf $ROOTDIR/src/gdal*

# Final apt-get cleanup
RUN rm -rf /var/lib/apt/lists/* && apt-get autoremove -y && apt-get clean all

# install these for gdal_calc.py
RUN pip3 install --upgrade numpy
RUN pip3 install --upgrade GDAL


# Load assets
WORKDIR $ROOTDIR/

ENV SCALA_VERSION 2.13.3
ENV SBT_VERSION 1.3.13

# Install Scala
RUN \
  curl -fsL https://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz | tar xfz - -C /root/ && \
  echo >> /root/.bashrc && \
  echo "export PATH=~/scala-$SCALA_VERSION/bin:$PATH" >> /root/.bashrc

# Install SBT
RUN \
  curl -L -o sbt-$SBT_VERSION.deb https://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get install sbt && \
  apt-get clean all && \
  sbt sbtVersion

# Final apt-get cleanup
RUN rm -rf /var/lib/apt/lists/* && apt-get autoremove -y && apt-get clean all

COPY vcog.py /usr/local/bin
RUN chmod u+x /usr/local/bin/vcog.py

# Externally accessible data is by default put in /data
WORKDIR /data
VOLUME ["/data"]

# Output version and capabilities by default.
CMD gdalinfo --version && gdalinfo --formats && java -version && javac -version && echo sbt sbtVersion: `sbt sbtVersion` && aws --version
