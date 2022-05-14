#Based on https://github.com/colmap/colmap/blob/dev/docker/Dockerfile
FROM nvidia/cuda:11.6.0-devel-ubuntu20.04

# Prevent stop building ubuntu at time zone selection.  
ENV DEBIAN_FRONTEND=noninteractive

#Install Essential Utilities
RUN apt update -y &&\
    apt install -y python3 wget tar 

# Prepare and empty machine for building
RUN apt-get update && apt-get install -y \
    libmetis-dev \
    git \
    cmake \
    build-essential \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libboost-test-dev \
    libeigen3-dev \
    libsuitesparse-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev

# Build and install ceres solver
RUN apt-get -y install \
    libatlas-base-dev \
    libsuitesparse-dev
ARG CERES_SOLVER_VERSION=2.1.0
RUN git clone https://github.com/ceres-solver/ceres-solver.git --tag ${CERES_SOLVER_VERSION}
RUN cd ${CERES_SOLVER_VERSION} && \
	mkdir build && \
	cd build && \
	cmake .. -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF && \
	make -j4 && \
	make install

# Build and install COLMAP

# Note: This Dockerfile has been tested using COLMAP pre-release 3.7.
# Later versions of COLMAP (which will be automatically cloned as default) may
# have problems using the environment described thus far. If you encounter
# problems and want to install the tested release, then uncomment the branch
# specification in the line below
WORKDIR /root
RUN git clone https://github.com/colmap/colmap.git 

RUN cd colmap && \
	git checkout dev && \
	mkdir build && \
	cd build && \
	cmake .. && \
	make -j4 && \
	make install

## Install Gdal
RUN add-apt-repository ppa:ubuntugis/ppa && apt-get update && \
    apt-get update && \
    apt-get install gdal-bin && \
    apt-get install libgdal-dev &&\
    export CPLUS_INCLUDE_PATH=/usr/include/gdal &&\
    export C_INCLUDE_PATH=/usr/include/gdal &&\
    pip install GDAL
WORKDIR /work
# For Python 3.8 use our SatelliteSurfaceReconstruction/requirements.txt instead of VisSatSatelliteStereo/requirements.txt
RUN git clone https://github.com/SBCV/SatelliteSurfaceReconstruction.git
##Install VisSatSatelliteStereo
RUN git clone https://github.com/SBCV/SatelliteSurfaceReconstruction.git &&\
    git clone https://github.com/Kai-46/VisSatSatelliteStereo && \
    pip install -r SatelliteSurfaceReconstruction/requirements.txt
WORKDIR /root
#Install MVE
RUN git clone https://github.com/simonfuhrmann/mve.git &&\
     cd mve &&\
     make j8
#Install MVS-Texturing 
RUN git clone https://github.com/nmoehrle/mvs-texturing.git &&\
    cd mvs-texturing &&\
    cd mvs-texturing &&\
    make -j
#Install MeshLab
RUN wget https://github.com/cnr-isti-vclab/meshlab/releases/download/MeshLab-2022.02/MeshLab2022.02-linux.tar.gz && \
    tar -zvxf  MeshLab2022.02-linux.tar.gz  &&\
    cd  MeshLab2022.02-linux &&\
    ./configure &&\
    make &&\
    make install
#Delete Install stuff
RUN rm -rf /root/*
ENV PYTHONPATH=${PYTHONPATH}:/work/SatelliteSurfaceReconstruction:/work/VisSatSatelliteStereo
