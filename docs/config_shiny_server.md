<h1>Config Shiny Server on VM Engine</h1>

<h2>Steps</h2>

- [1. Create a VM Machine in VM Engine](#1-create-a-vm-machine-in-vm-engine)
- [2. Set SSH keys in GitHub and clone repository](#2-set-ssh-keys-in-github-and-clone-repository)
- [3. Install Docker](#3-install-docker)
- [4. R Installation](#4-r-installation)
- [5. Docker](#5-docker)
- [6. Build Docker image](#6-build-docker-image)
- [7. Push to Docker Hub](#7-push-to-docker-hub)
- [8. ShinyProxy](#8-shinyproxy)
	- [8.1. (Optional for testing) Install Java](#81-optional-for-testing-install-java)
	- [8.2. (Optional for testing) Install Maven](#82-optional-for-testing-install-maven)
	- [8.3. (Optional for testing) Launch ShinyProxy](#83-optional-for-testing-launch-shinyproxy)
	- [8.4. (Optional for testing) Config ShinyProxy](#84-optional-for-testing-config-shinyproxy)
- [9. Deploy ShinyProxy using Docker](#9-deploy-shinyproxy-using-docker)
- [10. (Optional) *OpenID* Authentication](#10-optional-openid-authentication)

## 1. Create a VM Machine in VM Engine

For this server it's used a Ubuntu machine v18.04 LTS with 2 CPUs and 2 GB of memory, besides its estimated cost is $13,85 in europe-west1 region, if machine was always on.

Then, install the main packages:

```
# update system packages and install the required packages
sudo apt-get update
sudo apt-get install bzip2 libxml2-dev libsm6 libxrender1 libfontconfig1 git
```

## 2. Set SSH keys in GitHub and clone repository

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

## 3. Install Docker

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

## 4. R Installation

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

## 5. Docker

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

## 6. Build Docker image

Now, from the main path, where is *Dockerfile*, you can run the following command in order to build the image of Shiny Server. The name *shiny-app* can be exchanged for another of our choice.

```
sudo docker build -t shiny-app .
```

Then, when the image is built, you can run now the docker container to deploy the ShinyApp.

```
sudo docker run -it -p 80:3838 shiny-app
```

With this command, you are setting that it was interactive and allocated a pseudo-TTY with ```-it``` and the port redirection ```-p [HOST PORT]:[CONTAINER PORT]```. At the end, it's set the name of the image, in this case *shiny-app*.

## 7. Push to Docker Hub

So that ShinyProxy was able to run our specific Docker image, it's necessary to keep it into Docker Hub which allows to pull it. For this step, it's mandatory to authenticate into the platform with a username.

```
docker login --username=sergiobemar
```

Then, you can push/pull the images you need. For push a image, it's needed to tag the image and then push it.

```
docker images
docker tag [IMAGE ID] sergiobemar/shiny-app-orders:latest
docker push sergiobemar/shiny-app-orders:latest
```

## 8. ShinyProxy

In this project, *ShinyProxy* it's deployed using a Docker image, but it's possible to install it natively. Due to be useful in order to learn about this *framework*, at the first time native installation was tested so the steps would be the following:

### 8.1. (Optional for testing) Install Java

In order to be able to use ShinyProxy, it's needed to have installed Java and Maven. At first, let's start with Java.

Use the following commands on the terminal to add Java repository to the system and then to install it.

```
sudo add-apt-repository ppa:linuxuprising/java

sudo apt-get update

sudo apt-get install default-jdk

```

When Java is installed, you can check it using the following command.
```
java -version
```

The result obtained should be such as this.

![ShinyProxy - Java Installation](images/shinyproxy-1-java-installation.png)

### 8.2. (Optional for testing) Install Maven

Maven is a necessary package for ShinyProxy, so let's install it.

```
sudo apt install maven
```

Once the installation is finished, check that everything was right.

```
mvn -version
```

![ShinyProxy - Maven Installation](images/shinyproxy-2-maven-installation.png)

### 8.3. (Optional for testing) Launch ShinyProxy

Now, everything is ready to start to install ShinyProxy and configure it.

First, we need to clone the repository from *GitHub* and compile it using *Maven*.

```
git clone https://github.com/openanalytics/shinyproxy.git

cd shinyproxy/

mvn -U clean install
```

If everything was ok, a file such as *`target/shinyproxy-2.x.x.jar`* should exist.

### 8.4. (Optional for testing) Config ShinyProxy

Now, we have to set the Shiny dashboard that it's created for the project as the application used by ShinyProxy, for be capable of making this configuration exists the file *`target/classes/application.yml`*. 

Edit it with the following configuration:

```
proxy:
	title: Open Analytics Shiny Proxy
	logo-url: http://www.openanalytics.eu/sites/www.openanalytics.eu/themes/oa/logo.png
	landing-page: /
	heartbeat-rate: 10000
	heartbeat-timeout: 60000
	port: 8080
	authentication: ldap
	admin-groups: scientists
	# Example: 'simple' authentication configuration
	users:
	- name: jack
		password: password
		groups: scientists
	- name: jeff
		password: password
		groups: mathematicians
	specs:
		- id: 01_hello
			display-name: Hello Application
			description: Application which demonstrates the basics of a Shiny app
			container-cmd: ["R", "-e", "shinyproxy::run_01_hello()"]
			container-image: openanalytics/shinyproxy-demo
			access-groups: [scientists, mathematicians]
```

## 9. Deploy ShinyProxy using Docker

Using a Docker image is the choosen solution. For this proposal, at first it's needed to create both a `Dockerfile` and `application.yml`.

+ `Dockerfile`

	This image downloads, compile and run ShinyProxy, and also provides the following `application.yml` to the container.
	
	```
	FROM openjdk:8-jre

	RUN mkdir -p /opt/shinyproxy/
	RUN wget https://www.shinyproxy.io/downloads/shinyproxy-2.3.1.jar -O /opt/shinyproxy/shinyproxy.jar
	COPY application.yml /opt/shinyproxy/application.yml

	RUN cat /opt/shinyproxy/application.yml

	WORKDIR /opt/shinyproxy/
	CMD ["java", "-jar", "/opt/shinyproxy/shinyproxy.jar"]
	```

+ `application.yml`

	In this file there are the whole configuration about ShinyProxy related to connections, aplications and authentication.

	```
	proxy:
	port: 8080
	admin-groups: admins
	container-wait-time: 60000
	authentication: simple
	users:
		- name: jack
			password: password
			groups: scientists
	docker:
		internal-networking: true
	specs:
		- id: 01_prediction
			display-name: Plataforma de Pedidos
			description: Plataforma para el reporting de pedidos realizados así como de la previsión de futuras ventas.
			container-image: sergiobemar/shiny-app-orders
			container-network: sp-net

	logging:
	file: shinyproxy.log

	```

	At the first time it's better in order to test the functionality to use a simple authentication. Then, due to using a image pushed from *Docker Hub* it's necessary set the parameter

	```
	proxy
		[...]
		docker:
			internal-networking: true
	```

	Then, you can follow a configuration for the app like the previous, but it's very important to set the `container-network` parameter with the network that container will use.

Then, you can go to the `shinyproxy/` folder and run the following commands:

```
docker service create --network sp-net
docker build -t shinyproxy .
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock --net sp-net -p 80:8080 shinyproxy
```

## 10. (Optional) *OpenID* Authentication

It's very intersting in order to improve the login experience use an *OpenID* provider to allow the users to authenticate in the system using a login that they might know, like Google login.

You can use providers like *[Auth0](https://auth0.com/)* or get a Google Cloud credential, for the project it's used the second option. For making this process, it's necessary to use an own domain which redirects to the ShinyProxy machine, this procedure can be made using GCP too.

1. Create a DNS zone

![Create a DNS Zone](./images/auth/1-dns-create-zone-dns.png)

2. Create a record set with the domain pointing to the IP of ShinyProxy machine

![Point to the machine](./images/auth/2-dns-create-record-set.png)

3. Create the credentials and redirect to the used domain

![GCP Credentials](./images/auth/3-openid-credentials.png)

<h1>Useful links</h1>

+ [Crear imagen Docker con Shiny Server](https://www.analyticslane.com/2020/07/10/crear-imagen-docker-con-shiny-server/)
+ [Deploying an R Shiny App With Docker](https://www.r-bloggers.com/deploying-an-r-shiny-app-with-docker/)
+ [Dockerize a ShinyApp](https://juanitorduz.github.io/dockerize-a-shinyapp/)
+ [Download Shiny Server for Ubuntu 16.04 or later](https://rstudio.com/products/shiny/download-server/ubuntu/)
+ [GitHub - ShinyProxy Configuration Examples](https://github.com/openanalytics/shinyproxy-config-examples)
+ [GitHub - ShinyProxy Template](https://github.com/openanalytics/shinyproxy-template)
+ [Google Cloud - Container Registry - Advanced authentication](https://cloud.google.com/container-registry/docs/advanced-authentication#helpers)
+ [Google Cloud - Container Registry - Pushing and pulling images](https://cloud.google.com/container-registry/docs/pushing-and-pulling)
+ [How To Dockerize ShinyApps](https://www.statworx.com/de/blog/how-to-dockerize-shinyapps/)
+ [How To Install R on Ubuntu 18.04 Quickstart](https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04-quickstart)
+ [Introduction to renv](https://rstudio.github.io/renv/articles/renv.html)
+ [ShinyProxy - Deploying Apps](https://www.shinyproxy.io/deploying-apps/)
+ [ShinyProxy - Meetup](https://github.com/karobotco/meetupcientificas)
+ [ShinyProxy - template](https://github.com/xmc811/ShinyProxy-template)