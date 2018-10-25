# Geospatial Swiss Army Knife image
FROM ubuntu:cosmic

# UTF-8 all the things
RUN \
    apt-get clean -y && apt-get update -y && \
    apt-get install -y apt-utils locales && \
    locale-gen en_US.UTF-8 && \
    apt-get clean all

# ENVs
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV ROOTDIR /usr/local/
# OPENJPEG versions prior to 2.3.0 have problems processing large jp2 files
# https://lists.osgeo.org/pipermail/gdal-dev/2017-October/047397.html
ENV OPENJPEG_VERSION 2.3.0
ENV GDAL_VERSION 2.3.2
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
# ENV SCALA_VERSION ${SCALA_VERSION:-2.12.6}
ENV SCALA_VERSION 2.12.7
ENV SBT_VERSION 1.2.4

# Load assets
WORKDIR $ROOTDIR/

RUN \
    apt-get install -y software-properties-common python3-software-properties && \
    apt-get clean all

RUN \
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886

RUN \
    apt-get update -y && \
    apt-get install -y \
        gcc \
        g++ \
        curl \
        build-essential \
        python-dev \
        python-numpy \
        python3-dev \
        python3-numpy \
        python3-pip \
        libcurl4-gnutls-dev \
        libproj-dev \
        libgeos-dev \
        libhdf4-alt-dev \
        libhdf5-serial-dev \
        bash-completion \
        cmake \
        imagemagick \
        libpng-dev \
        wget \
    && apt-get clean all

# Install Pip and AWS CLI
RUN pip3 install --upgrade pip awscli

# Compile and install OpenJPEG for GDAL
RUN \
    cd $ROOTDIR/src && \
    wget https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz && \
    tar -xvf v${OPENJPEG_VERSION}.tar.gz && \
    cd openjpeg-${OPENJPEG_VERSION}/ && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$ROOTDIR && \
    make -j && \
    make install && \
    rm -Rf $ROOTDIR/src/openjpeg* $ROOTDIR/src/v${OPENJPEG_VERSION}.tar.gz

# Compile and install GDAL
# FYI, GDAL fails to compile with make -j
RUN \
    cd $ROOTDIR/src && \
    wget http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz && \
    tar -xvf gdal-${GDAL_VERSION}.tar.gz && \
    cd gdal-${GDAL_VERSION} && \
    ./configure \
        --with-python \
        --with-curl \
        --with-openjpeg \
        --with-hdf4 \
        --with-hdf5 \
        --with-geos \
        --with-geotiff=internal \
        --with-hide-internal-symbols \
        --with-libtiff=internal \
        --with-libz=internal \
        --with-threads \
        --with-mrf \
        --without-jp2mrsid \
        --without-netcdf \
        --without-ecw \
    && \
    make && \
    make install && \
    ldconfig && \
    apt-get remove -y --purge build-essential && \
    apt-get autoremove -y && apt-get clean all && \
   # cd $ROOTDIR/src/gdal-${GDAL_VERSION}/swig/python && \
   # python3 setup.py build && \
   # python3 setup.py install && \
    rm -Rf $ROOTDIR/src/gdal*

# Install JDK
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends oracle-java8-installer && \
    apt-get clean all

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

# Scala expects this file
RUN mkdir -p /usr/lib/jvm/java-8-openjdk-amd64 && touch /usr/lib/jvm/java-8-openjdk-amd64/release

# Final apt-get cleanup
RUN rm -rf /var/lib/apt/lists/* && apt-get autoremove -y && apt-get clean all

# Externally accessible data is by default put in /data
WORKDIR /data
VOLUME ["/data"]

# Output version and capabilities by default.
CMD gdalinfo --version && gdalinfo --formats && java -version && javac -version && echo sbt sbtVersion: `sbt sbtVersion` && aws --version
