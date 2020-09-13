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

```
sudo su - \
-c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""

sudo apt-get install gdebi-core
wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.14.948-amd64.deb
sudo gdebi shiny-server-1.5.14.948-amd64.deb
```



## Step 4:

Create a *Dockerfile* in current directory (where it's located *app.R*) with the following code:

```
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

Now, from the main path, where is *Dockerfile*, you can run the following command in order to build the image of Shiny Server. The name *shiny_app* can be exchanged for another of our choice.

```
docker build -t shiny_app .
```

# Useful links
+ [How To Install R on Ubuntu 18.04 Quickstart](https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04-quickstart)