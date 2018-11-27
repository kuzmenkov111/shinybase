FROM kuzmenkov/docker-baseimage:latest

#Installation of nesesary package/software for this containers...
RUN echo "deb http://archive.ubuntu.com/ubuntu `cat /etc/container_environment/DISTRIB_CODENAME`-backports main restricted universe" >> /etc/apt/sources.list
RUN (echo "deb http://cran.mtu.edu/bin/linux/ubuntu `cat /etc/container_environment/DISTRIB_CODENAME`/" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9)

## Install some useful tools and dependencies for MRO
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
        wget \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /home/docker

# MRO 3.2.2.
#RUN wget https://www.dropbox.com/s/xrkzdhm1cq0ll1q/microsoft-r-open-3.3.2.tar.gz?dl=1 -O microsoft-r-open-3.3.2.tar.gz \
#&& echo "817aca692adffe20e590fc5218cb6992f24f29aa31864465569057534bce42c7 microsoft-r-open-3.3.2.tar.gz" > checksum.txt \


# Download, valiate, and unpack
RUN wget https://www.dropbox.com/s/uz4e4d0frk21cvn/microsoft-r-open-3.5.1.tar.gz?dl=1 -O microsoft-r-open-3.5.1.tar.gz \
&& echo "9791AAFB94844544930A1D896F2BF1404205DBF2EC059C51AE75EBB3A31B3792 microsoft-r-open-3.5.1.tar.gz" > checksum.txt \
	&& sha256sum -c --strict checksum.txt \
	&& tar -xf microsoft-r-open-3.5.1.tar.gz \
	&& cd /home/docker/microsoft-r-open \
	&& ./install.sh -a -u \
	&& ls logs && cat logs/*


# Clean up
WORKDIR /home/docker
RUN rm microsoft-r-open-3.5.1.tar.gz \
	&& rm checksum.txt \
&& rm -r microsoft-r-open

# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libssl1.0.0 \
    libxml2-dev \
    libssl-dev

# system library dependency for the euler app
RUN apt-get update && apt-get install -y \
    libmpfr-dev \
    gfortran \
    aptitude \
    libgdal-dev \
    libproj-dev \
    g++ \
    gdebi-core\
    libicu-dev \
    libpcre3-dev\
    libbz2-dev \
    liblzma-dev \
    libnlopt-dev \
    build-essential
    
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable
RUN apt-get update
RUN apt-get install -y libudunits2-dev libgdal-dev libgeos-dev 


RUN sudo apt-add-repository -y ppa:webupd8team/java \
&& apt-get update && echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections && apt-get install -y oracle-java8-installer \
&& R -e "Sys.setenv(JAVA_HOME = '/usr/lib/jvm/java-8-oracle/jre')"
RUN sudo java -version

#COPY Makeconf /usr/lib64/microsoft-r/3.4/lib64/R/etc/Makeconf
# libproj-de
#wget https://www.dropbox.com/s/hl0vx1f6rpfgxrx/shiny-server-1.5.3.838-amd64.deb?dl=1 -O shiny-server-1.5.3.838-amd64.deb

RUN wget https://www.dropbox.com/s/8v07th1mur5m91n/shiny-server-1.5.9.923-amd64.deb?dl=1 -O shiny-server-1.5.9.923-amd64.deb \
&& dpkg -i --force-depends shiny-server-1.5.9.923-amd64.deb \
          && rm shiny-server-1.5.9.923-amd64.deb && \
    R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cran.rstudio.com/')" \
          && mkdir -p /srv/shiny-server; sync  \
          && mkdir -p  /srv/shiny-server/examples; sync  
   # && rm -rf /var/lib/apt/lists/*

#COPY Makeconf /usr/lib64/microsoft-r/3.3/lib64/R/etc/Makeconf

RUN mkdir -p /etc/my_init.d
COPY startup.sh /etc/my_init.d/startup.sh
RUN chmod +x /etc/my_init.d/startup.sh

##Adding Deamons to containers
RUN mkdir /etc/service/shiny-server /var/log/shiny-server ; sync 
COPY shiny-server.sh /etc/service/shiny-server/run
RUN chmod +x /etc/service/shiny-server/run  \
    && cp /var/log/cron/config /var/log/shiny-server/ \
    && chown -R shiny /var/log/shiny-server \
    && sed -i '113 a <h2><a href="./examples/">Other examples of Shiny application</a> </h2>' /srv/shiny-server/index.html

COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
RUN mkdir /var/lib/shiny-server/bookmarks \
 && chown -R shiny:shiny /var/lib/shiny-server/bookmarks

RUN sudo rm -rf /srv/shiny-server/sample-apps \
&& rm -rf /srv/shiny-server/


#volume for Shiny Apps and static assets. Here is the folder for index.html(link) and sample apps.
VOLUME /srv/shiny-server    




EXPOSE 3838
