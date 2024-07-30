#syntax=docker/dockerfile:1

FROM ubuntu:16.04

WORKDIR /root/

#BASE
RUN apt update -y && apt upgrade -y

#INSTALL SOME DEPENDENCIES
RUN apt install -y wget
RUN apt install -y build-essential
RUN apt install -y zlib1g-dev
RUN apt install -y gfortran
RUN apt install -y bzip2
RUN apt install -y libbz2-dev
RUN apt install -y liblzma-dev
RUN apt install -y libpcre3 libpcre3-dev
RUN apt install -y libcurl4-gnutls-dev

#INSTALL R 3.4.1
RUN wget -c https://cran.r-project.org/src/base/R-3/R-3.4.1.tar.gz
RUN tar -xf R-3.4.1.tar.gz && rm R-3.4.1.tar.gz
WORKDIR /root/R-3.4.1
RUN ./configure --with-readline=no --with-x=no
RUN make -j $(expr $(nproc --all) / 2)
RUN make install

WORKDIR /usr/bin
RUN ln -s /root/R-3.4.1/bin/R
WORKDIR /usr/lib
RUN ln -s ~/R-3.4.1/lib

WORKDIR /root

#INSTALL MORE DEP AND PYTHON 2.7.14
RUN apt install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev

RUN wget https://www.python.org/ftp/python/2.7.14/Python-2.7.14.tgz
RUN tar -xf Python-2.7.14.tgz && rm Python-2.7.14.tgz
WORKDIR /root/Python-2.7.14
RUN ./configure --with-ensurepip=install --enable-optimizations --prefix=$HOME --enable-loadable-sqlite-extensions --enable-shared && make -j $(expr $(nproc --all) / 2) && make install
WORKDIR /usr/bin
RUN ln -s ~/Python-2.7.14/python
WORKDIR /usr/lib
RUN ln -s ~/Python-2.7.14/libpython2.7.so && ln -s ~/Python-2.7.14/libpython2.7.so.1.0
RUN python -m pip install --upgrade --trusted-host pypi.python.org pip

RUN apt install -y libncurses-dev
RUN apt install -y libcurl3
RUN apt install -y git vim

WORKDIR /root

#SQuIRE DEPENDENCIES
RUN python -m pip install six
RUN python -m pip install urllib3[secure]
RUN python -m pip install setuptools
RUN python -m pip install --upgrade setuptools
RUN python -m pip install pyfaidx
RUN python -m pip install tqdm

#SQuIRE INSTALLATION
RUN git clone https://github.com/messagian/SQuIRE/
WORKDIR /root/SQuIRE

RUN python squire/Build.py -v -s all

#UCSC tools

WORKDIR /root/ucsc
RUN rsync -aP rsync://hgdownload.soe.ucsc.edu/genome/admin/exe/linux.x86_64/ ./
WORKDIR /root
RUN bash -i; source .bashrc; echo "export PATH='/root/ucsc':\$PATH" | tee -a .bashrc

WORKDIR /root

# RUN wget https://github.com/cli/cli/releases/download/v2.52.0/gh_2.52.0_linux_amd64.deb
# RUN dpkg -i gh_2.52.0_linux_amd64.deb

#prep SQuIRE
RUN mkdir squire_data
RUN export PATH='/root/ucsc':$PATH; python SQuIRE/squire/Fetch.py -b hg38 -f -c -r -g -x -p 32 -v && python SQuIRE/squire/Clean.py -b hg38 -v