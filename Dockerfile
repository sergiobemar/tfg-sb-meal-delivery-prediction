FROM r-base:latest
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libxt-dev \
    libssl-dev \
    libxml2 \
    libxml2-dev
# Instalacion de shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb
# Instalacion de los paquetes necesarios
RUN R -e "install.packages(c('shiny'), repos='http://cran.rstudio.com/')"
COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf
COPY /myapp /srv/shiny-server/
COPY shiny-server.sh /usr/bin/shiny-server.sh
EXPOSE 80
CMD ["/usr/bin/shiny-server.sh"]