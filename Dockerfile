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

RUN sudo apt-get install -y software-properties-common
RUN sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN sudo apt-get update -y
RUN sudo apt-get install -y gcc-4.9
RUN sudo apt-get install -y g++-4.9
RUN sudo apt-get update -y
RUN sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.9
RUN sudo update-alternatives --config gcc
RUN sudo apt-get install -y gfortran-4.9
RUN sudo update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-4.9 60
RUN sudo update-alternatives --config gfortran

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


# basic shiny functionality
RUN R -e "install.packages('binom', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('dplyr', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('ggplot2', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('reshape', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('curl', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('httr', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('devtools', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('remotes', repos='https://cran.r-project.org/')" \
#&& R -e "remotes::install_url('https://cran.r-project.org/src/contrib/httpuv_1.4.3.tar.gz')" \
#&& R -e "download.file('https://github.com/rstudio/httpuv/archive/master.zip', 'httpuv-master.zip'); unlink('httpuv-master', recursive = TRUE); unzip('httpuv-master.zip', unzip = '/usr/bin/unzip'); file.mode('httpuv-master/src/libuv/configure')" \
#&& R -e "options(unzip = 'internal'); options(unzip = '/usr/bin/unzip'); devtools::install_github('rstudio/httpuv')" \
#&& R -e "options(unzip = 'internal'); devtools::install_github('rstudio/shiny')" \
&& R -e "install.packages('formattable', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('car', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('fmsb', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('igraph', repos='https://cran.r-project.org/')" \
&& sudo su - -c "R -e \"install.packages('miniUI', repos='https://cran.r-project.org/');options(unzip = 'internal'); remotes::install_github('daattali/shinyjs')\"" \
#RUN R -e "options(unzip = 'internal'); devtools::install_github('daattali/shinyjs')" \
&& R -e "install.packages('scales', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('crosstalk', repos='https://cran.r-project.org/')" \
&& sudo su - -c "R -e \"options(unzip = 'internal'); remotes::install_github('rstudio/DT')\"" \
#RUN R -e "devtools::install_github('rstudio/DT')" \
&& sudo su - -c "R -e \"install.packages(c('raster', 'sp', 'viridis'), repos='https://cran.r-project.org/');options(unzip = 'internal'); remotes::install_github('rstudio/leaflet')\"" \
&& sudo su - -c "R -e \"options(unzip = 'internal'); remotes::install_github('bhaskarvk/leaflet.extras')\"" \
&& R -e "install.packages('ggrepel', repos='https://cran.r-project.org/')" \
#RUN R -e "install.packages('leaflet', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('visNetwork', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('purrr', repos='https://cran.r-project.org/')" \
&& sudo su - -c "R -e \"options(unzip = 'internal'); remotes::install_github('kuzmenkov111/highcharter')\"" 

RUN sudo rm -rf /srv/shiny-server/sample-apps \
&& rm -rf /srv/shiny-server/


#volume for Shiny Apps and static assets. Here is the folder for index.html(link) and sample apps.
VOLUME /srv/shiny-server    




EXPOSE 3838
