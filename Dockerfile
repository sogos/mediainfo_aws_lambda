# PURPOSE: This Dockerfile will prepare an Amazon Linux docker image with everything needed to compile binary MediaInfo libraries for Python 3.7 and Python 3.8
# USAGE: 
# 1. Build the docker image:
#     docker build --tag=pymediainfo-layer-factory:latest .
# 2. Build and copy MediaInfo libraries to ./pymediainfo-python[37,38].zip
#     docker run --rm -it -v $(pwd):/data pymediainfo-layer-factory cp /packages/pymediainfo-python37.zip /data

FROM amazonlinux:1

WORKDIR /
RUN yum update -y
RUN yum install gcc gcc-c++ openssl-devel bzip2-devel libffi-devel wget tar gzip zip make zlib-devel -y

# Install Python 3.9
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tgz
RUN tar -xzf Python-3.9.0.tgz
WORKDIR /Python-3.9.0
RUN ./configure --enable-optimizations
RUN make install

# Install Python 3.8
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tgz
RUN tar -xzf Python-3.8.0.tgz
WORKDIR /Python-3.8.0
RUN ./configure --enable-optimizations
RUN make install

# Install Python 3.7
WORKDIR /
RUN wget https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tgz
RUN tar -xzvf Python-3.7.5.tgz
WORKDIR /Python-3.7.5
RUN ./configure --enable-optimizations
RUN make install

# Install Python packages
RUN mkdir /packages
RUN echo "pymediainfo" >> /packages/requirements.txt
RUN mkdir -p /packages/pymediainfo-3.7/python/lib/python3.7/site-packages
RUN mkdir -p /packages/pymediainfo-3.8/python/lib/python3.8/site-packages
RUN mkdir -p /packages/pymediainfo-3.9/python/lib/python3.9/site-packages
RUN pip3.7 install -r /packages/requirements.txt -t /packages/pymediainfo-3.7/python/lib/python3.7/site-packages
RUN pip3.8 install -r /packages/requirements.txt -t /packages/pymediainfo-3.8/python/lib/python3.8/site-packages
RUN pip3.9 install -r /packages/requirements.txt -t /packages/pymediainfo-3.9/python/lib/python3.9/site-packages

# Download MediaInfo
WORKDIR /root
RUN wget https://mediaarea.net/download/binary/libmediainfo0/19.09/MediaInfo_DLL_19.09_GNU_FromSource.tar.gz
RUN tar -xzvf MediaInfo_DLL_19.09_GNU_FromSource.tar.gz

# Compile MediaInfo with Support for URL Inputs
WORKDIR /root/MediaInfo_DLL_GNU_FromSource/
RUN ./SO_Compile.sh

# Create zip files for Lambda Layer deployment
RUN cp /root/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/* /packages/pymediainfo-3.7/python
RUN cp /root/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/* /packages/pymediainfo-3.8/python
RUN cp /root/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/* /packages/pymediainfo-3.9/python
RUN cp /root/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/* /packages/pymediainfo-3.7/
RUN cp /root/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/* /packages/pymediainfo-3.8/
RUN cp /root/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/* /packages/pymediainfo-3.9/
WORKDIR /packages/pymediainfo-3.7/
RUN zip -r9 /packages/pymediainfo-python37.zip .
WORKDIR /packages/pymediainfo-3.8/
RUN zip -r9 /packages/pymediainfo-python38.zip .
WORKDIR /packages/pymediainfo-3.9/
RUN zip -r9 /packages/pymediainfo-python39.zip .
WORKDIR /packages/
RUN rm -rf /packages/pymediainfo-3.7/
RUN rm -rf /packages/pymediainfo-3.8/
RUN rm -rf /packages/pymediainfo-3.9/
