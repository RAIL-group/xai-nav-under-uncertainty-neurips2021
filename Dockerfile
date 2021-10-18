FROM nvidia/cudagl:11.1-devel-ubuntu20.04

ENV VIRTUALGL_VERSION 2.5.2


# Install all apt dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN apt-get update && apt-get install -y software-properties-common
# Add ppa for python3.6 install
RUN apt-add-repository -y ppa:deadsnakes/ppa
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	curl ca-certificates cmake git python3.6 python3.6-dev \
	xvfb libxv1 libxrender1 libxrender-dev g++ libgeos-dev \
	libboost-all-dev libcgal-dev ffmpeg python3-tk \
	texlive texlive-latex-extra dvipng cm-super \
	libeigen3-dev


# Install VirtualGL
RUN curl -sSL https://downloads.sourceforge.net/project/virtualgl/"${VIRTUALGL_VERSION}"/virtualgl_"${VIRTUALGL_VERSION}"_amd64.deb -o virtualgl_"${VIRTUALGL_VERSION}"_amd64.deb && \
	dpkg -i virtualgl_*_amd64.deb && \
	/opt/VirtualGL/bin/vglserver_config -config +s +f -t && \
	rm virtualgl_*_amd64.deb


# Install python dependencies
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py && rm get-pip.py
COPY src/requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY src/lsp_accel lsp_accel
RUN pip3 install ./lsp_accel
# Needed for using matplotlib without a screen
RUN echo "backend: TkAgg" > matplotlibrc


# Copy the remaining code
COPY src/common common
COPY src/environments environments
COPY src/gridmap gridmap
COPY src/scripts scripts
COPY src/xai xai
COPY src/unitybridge unitybridge
COPY src/tests tests


# Set up the starting point for running the code
COPY src/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
