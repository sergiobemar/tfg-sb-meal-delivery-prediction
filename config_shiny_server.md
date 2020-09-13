# Config Shiny Server on VM Engine

## Step 0: Create a VM Machine in VM Engine

For this server it's used a Ubuntu machine v18.04 LTS with 2 CPUs and 2 GB of memory, besides its estimated cost is $13,85 in europe-west1 region, if machine was always on.

Then, install the main packages:

```
# update system packages and install the required packages
sudo apt-get update
sudo apt-get install bzip2 libxml2-dev libsm6 libxrender1 libfontconfig1 git
```

## Step 1: Set SSH keys in GitHub and clone repository

```
ssh-keygen -t rsa -b 4096 -C "youremail@email.com"
cat .ssh/id_rsa.pub
```

```
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

# clone the project repo
git clone git@github.com:sergiobemar/tfg-sb-meal-delivery-prediction.git
```

## Step 2: Install Docker

To install Docker it's possible following [this tutorial](https://www.digitalocean.com/community/tutorials/como-instalar-y-usar-docker-en-ubuntu-18-04-1-es):

```
sudo apt install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update

apt-cache policy docker-ce
sudo apt install docker-ce

sudo systemctl status docker
```

Then, current user is added to *docker* group.

```
sudo usermod -aG docker ${USER}
su - ${USER}

# Check if it's added
id -nG
```

## Step 3: R Installation

In order to test the functionality before creating the container it's possible to test if the app runs using R, so the following code correspond with the commands which R can be installed.

```
# Add GPG Key
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

# Add the R Repository
sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/'

# Update Package Lists
sudo apt update

# Install R
sudo apt install r-base

# Test install
sudo -i R
```

Also, for RShiny Sever installation, here are the steps:

```
sudo su - \
-c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""

sudo apt-get install gdebi-core
wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.14.948-amd64.deb
sudo gdebi shiny-server-1.5.14.948-amd64.deb
```



## Step 4: Docker

Create a *Dockerfile* in current directory (where it's located *app.R*) with the following code:

```
FROM openanalytics/r-base

LABEL maintainer "Tobias Verbeke <tobias.verbeke@openanalytics.eu>"

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
    libssl1.0.0

# system library dependency for the euler app
RUN apt-get update && apt-get install -y \
    libmpfr-dev

# basic shiny functionality
RUN R -e "install.packages(c('shiny', 'rmarkdown', 'remotes'), repos='https://cloud.r-project.org/')"

# install dependencies of the app
RUN R -e "install.packages(c('dplyr', 'data.table', 'plotly', 'purrr', 'lubridate', 'jsonlite', 'shiny', 'shinydashboard', 'DT', 'shinyWidgets', 'httr', 'shinyBS'), repos='https://cloud.r-project.org/')"

# install shinysky
RUN R -e "remotes::install_github('AnalytixWare/ShinySky')"

# copy the app to the image
RUN mkdir /root/app
COPY app /root/app

COPY Rprofile.site /usr/lib/R/etc/

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/root/app')"]

```

## Step 5: Create Shiny Server config file and executable

The ```shiny-server.conf``` is neccessary because it's set the user who run the server. In this case, you would have to change *shiny* user by yours.

```
run_as shiny;
server {
  listen 80;
  location / {
    site_dir /srv/shiny-server;
    log_dir /var/log/shiny-server;
    directory_index on;
  }
}
```

And then, the another file is ```shiny-server.sh``` which have the commands to run the server. The different from the .conf file is while it has the configuration for the server, the other runs it.

```
#!/bin/sh
mkdir -p /var/log/shiny-server
chown shiny.shiny /var/log/shiny-server
exec shiny-server >> /var/log/shiny-server.log 2>&1
```

## Step 6: Build Docker image

Now, from the main path, where is *Dockerfile*, you can run the following command in order to build the image of Shiny Server. The name *shiny-app* can be exchanged for another of our choice.

```
sudo docker build -t shiny-app .
```

Then, when the image is built, you can run now the docker container to deploy the ShinyApp.

```
sudo docker run -it -p 80:3838 shiny-app
```

With this command, you are setting that it was interactive and allocated a pseudo-TTY with ```-it``` and the port redirection ```-p [HOST PORT]:[CONTAINER PORT]```. At the end, it's set the name of the image, in this case *shiny-app*.

# Useful links
+ [Crear imagen Docker con Shiny Server](https://www.analyticslane.com/2020/07/10/crear-imagen-docker-con-shiny-server/)
+ [Deploying an R Shiny App With Docker](https://www.r-bloggers.com/deploying-an-r-shiny-app-with-docker/)
+ [Dockerize a ShinyApp](https://juanitorduz.github.io/dockerize-a-shinyapp/)
+ [Download Shiny Server for Ubuntu 16.04 or later](https://rstudio.com/products/shiny/download-server/ubuntu/)
+ [GitHub - ShinyProxy Configuration Examples](https://github.com/openanalytics/shinyproxy-config-examples)
+ [GitHub - ShinyProxy Template](https://github.com/openanalytics/shinyproxy-template)
+ [How To Dockerize ShinyApps](https://www.statworx.com/de/blog/how-to-dockerize-shinyapps/)
+ [How To Install R on Ubuntu 18.04 Quickstart](https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04-quickstart)
+ [Introduction to renv](https://rstudio.github.io/renv/articles/renv.html)
+ [Shinyproxy - Deploying Apps](https://www.shinyproxy.io/deploying-apps/)