ansible-windows-docker-springboot
======================================================================================
[![Build Status](https://travis-ci.org/jonashackt/ansible-windows-docker-springboot.svg?branch=master)](https://travis-ci.org/jonashackt/ansible-windows-docker-springboot)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-jonashackt-660198.svg)](https://galaxy.ansible.com/jonashackt)

## Example project showing how to provision, deploy and run Spring Boot apps inside Docker Windows Containers on Windows Host using Packer, Powershell, Vagrant & Ansible

This is a follow-up to the repository [ansible-windows-springboot](https://github.com/jonashackt/ansible-windows-springboot) and the blog post [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/). There are two corresponding follow up blog posts available:

* [Running Spring Boot Apps on Docker Windows Containers with Ansible: A Complete Guide incl Packer, Vagrant & Powershell](https://blog.codecentric.de/en/2017/04/ansible-docker-windows-containers-spring-boot/)
* [Scaling Spring Boot Apps on Docker Windows Containers with Ansible: A Complete Guide incl Spring Cloud Netflix and Docker Compose](https://blog.codecentric.de/en/2017/05/ansible-docker-windows-containers-scaling-spring-cloud-netflix-docker-compose/)

This repository uses the following example Spring Boot / Cloud applications for provisioning: [cxf-spring-cloud-netflix-docker](https://github.com/jonashackt/cxf-spring-cloud-netflix-docker)

## Before you start...

Because [Microsoft &amp; Docker Inc. developed a native Docker implementation on Windows](https://blog.docker.com/2016/09/dockerforws2016/) using Hyper-V (or even a thinner layer) which let´s you run tiny little Windows containers inside your Windows box, which are accessible through the Docker API, I wanted to get my hands on them as soon as I heard of it. A list of [example Windows Docker Images is provided here](https://hub.docker.com/r/microsoft/).

Firing up Spring Boot apps with Ansible on Windows using Docker sound´s like the next step after [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/).

> Before we start: The most important point here is to start with a __correct Build Number__ of Windows 10 (1607, Anniversary Update)/Windows Server 2016. It took me days to figure that out, but it won´t work with for example 10.0.14393.67 - but will with 10.0.14393.206! I ran over [the advice on this howto](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10) to fast, because I thought "Windows 10 Anniversary should be enough, don´t bother me with build numbers". But take care! The final `docker run` won´t work (but all the other steps before, which made it so hard to understand)... Here are two examples of the output of a `(Get-ItemProperty -Path c:\windows\system32\hal.dll).VersionInfo.FileVersion` on a Powershell:

__Good build number:__

![Windows_build_number_Docker_working](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/Windows_build_number_Docker_working.png)

__Bad build number:__

![Windows_build_number_Docker_failing](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/Windows_build_number_Docker_failing.png)

Because of the minimal required build of Windows 10 or Server 2016, we sadly can´t use the easy to download and easy to handle [Vagrant box with Windows 10 from the Microsoft Edge developer site](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/#downloads). So we have to look after an alternative box to start from. My goal was to start from a original Microsoft Image and show a 100% replicable way how to get to a running Vagrant box. Because besides the Microsoft Edge boxes (which have don´t have the correct build number for now) there aren´t any official from Microsoft around in [Vagrant Atlas](https://atlas.hashicorp.com/boxes/search?utf8=%E2%9C%93&sort=&provider=&q=windows+10). And hey - we´re dealing with Windows! I don´t want to have someone installing things on a VM I don´t know... 


## Preperation: Find a Windows Box - the Evalutation ISO

After a bit of research, you´ll find another way to evaluate a current Windows Version: The [Windows 10 Enterprise Evalutation ISO](https://www.microsoft.com/de-de/evalcenter/evaluate-windows-10-enterprise) or the [Windows Server 2016 Evalutation ISO](https://www.microsoft.com/de-de/evalcenter/evaluate-windows-server-2016). Both the Windows 2016 Server and the 10 Enterprise come with a 180 Days Evaluation licence (you have to register a live-ID for that).

> __DISCLAIMER:__ There are [two Windows Container Types](https://docs.microsoft.com/en-us/virtualization/windowscontainers/about/) : __Windows Server Containers__ (aka isolation level "process" or shared Windows kernel) and __Hyper-V-Containers__ (aka isolation level "hyper-v"). Windows 10 only supports the latter one. But Hyper-V-Containers seem not the thing you´re used to, when it comes to the Docker core concepts - because Docker relies on Process-Level isolation and __does not__ use a Hypervisor. So with that knowledge I would strongly encourage you to go with Windows Server 2016 and leave Windows 10 behind. At first glance it seems somehow "easier" to start with the "smaller" Windows 10. But don´t do that! I can also back this advice with lot´s of ours (when not days) trying to get things to work for myself or with customers - and finally switching to Windows Server and everything was just fine!

So if you really want to go with Windows 10 anyway, it shouldn´t be that much work to write your own Packer template and use the other ISO instead. Here we´ll stay with Windows Server 2016.


## Step 0 - How to build Ansible-ready Vagrant box from a Windows ISO ([step0-packer-windows-vagrantbox](https://github.com/jonashackt/ansible-windows-docker-springboot/tree/master/step0-packer-windows-vagrantbox))

The problem with an ISO - it´s not a nice Vagrant box we can fireup easily for development. But hey! There´s something for us: [packer.io](https://packer.io/). This smart tool is able to produce machine images in every flavour - also as a Vagrant box ;) And [from the docs](https://www.packer.io/docs/post-processors/vagrant.html): "[Packer] ... is in fact how the official boxes distributed by Vagrant are created." On a Mac you can install it with:

`brew install packer` 

We also install Windows completely [unattended](https://social.technet.microsoft.com/wiki/contents/articles/36609.windows-server-2016-unattended-installation.aspx) - which means, we don´t have to click on a single installation screen ;) And we configure it already completely for compatibility with Ansible. Which means several things:

* configure WinRM (aka Powershell remoting) correctly (including Firewall settings)
* install VirtualBox Guest tools (just for better usability)
* configure Ansible connectivity 

The WinRM connectivity is configured through the [Autounattend.xml[(https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/packer/Autounattend.xml). At the end we run the configure-ansible.ps1 - which will call the https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1. But this is done mostly for habing a better feeling, because WinRM should be configured already sufficiently. 

If you like to dig deeper into the myriads of configuration options, have a look into Stefan Scherers GitHub repositories, e.g. https://github.com/StefanScherer/docker-windows-box - where I learned everything I had to - and also borrowed the mentioned [Autounattend.xml[(https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/packer/Autounattend.xml) from. You can also create one yourself from ground up - but you´ll need a running Windows instance and then install the [Windows Assessment and Deployment Kit (Windows ADK)](https://developer.microsoft.com/de-de/windows/hardware/windows-assessment-deployment-kit).


#### Build your Windows Server 2016 Vagrant box

Download the [14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO](https://www.microsoft.com/de-de/evalcenter/evaluate-windows-server-2016) and place it into the __/packer__ folder.

Inside the `step0-packer-windows-vagrantbox` directory start the build with this command:

```
packer build -var iso_url=14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO -var iso_checksum=70721288bbcdfe3239d8f8c0fae55f1f windows_server_2016_docker.json
```

Now get yourself a coffee. This will take some time ;)

#### Add the box and run it


After successful packer build, you can init the Vagrant box (and receive a Vagrantfile):
```
vagrant init windows_2016_docker_virtualbox.box 
```

Now fire up your Windows Server 2016 box:

```
vagrant up
```


## Step 1 - Prepare your Windows Box to run Docker Windows Containers with Ansible ([step1-prepare-docker-windows](https://github.com/jonashackt/ansible-windows-docker-springboot/tree/master/step1-prepare-docker-windows))

If you don´t want to go with the discribed way of using packer to build your own Vagrant box and start with your own custom Windows Server 2016 machine right away - no problem! Just be sure to [prepare your machine correctly for Ansible](https://github.com/jonashackt/ansible-windows-springboot#prepare-the-windows-box-for-ansible-communication).

Now let´s check the Ansible connectivity. `cd..` into the root folder `ansible-windows-docker-springboot`:

```
ansible ansible-windows-docker-springboot-dev -i hostsfile -m win_ping
```

Getting a __SUCCESS__ responde, we can start to prepare our Windows box to run Windows Docker Containers. Let´s run the preparation playbook: 

```
ansible-playbook -i hostsfile prepare-docker-windows.yml --extra-vars "host=ansible-windows-docker-springboot-dev"
```

This does those things for you: 

* Checking, if you have the correct minimum build version of Windows
* Install the necessary Windows Features `containers` and `Hyper-V` (this is done Windows Version agnostic - so it will work with Windows 10 AND Server 2016 - which is quite unique, becaue Microsoft itself always distinquishes between these versions)
* Reboot your Windows Box, if necessary
* Install the current Docker version (via [chocolatey docker package](https://chocolatey.org/packages/docker). And although the package claims to only install the client, it also provides the Docker Server (which means this is 100% identical with the [step 2. Install Docker in Microsoft´s tutorial](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10)).)
* Register and Start the Docker Windows service
* Installing docker-compose (this is only needed for multiple containers)
* Running a first Windows container inside your Windows box (via `docker run microsoft/dotnet-samples:dotnetapp-nanoserver`)
* Building the `springboot-oraclejre-nanoserver` Docker image to run our Spring Boot Apps later on


If Docker on Windows with Windows Docker Containers is fully configured, you should see something like this (which definitely means, Docker is running perfectly fine on your Windows box!):

```
TASK [Docker is ready on your Box and waiting for your Containers :)] **********
ok: [127.0.0.1] => {
    "msg": [
        "", 
        "        Dotnet-bot: Welcome to using .NET Core!", 
        "    __________________", 
        "                      \\", 
        "                       \\", 
        "                          ....", 
        "                          ....'", 
        "                           ....", 
        "                        ..........", 
        "                    .............'..'..", 
        "                 ................'..'.....", 
        "               .......'..........'..'..'....", 
        "              ........'..........'..'..'.....", 
        "             .'....'..'..........'..'.......'.", 
        "             .'..................'...   ......", 
        "             .  ......'.........         .....", 
        "             .                           ......", 
        "            ..    .            ..        ......", 
        "           ....       .                 .......", 
        "           ......  .......          ............", 
        "            ................  ......................", 
        "            ........................'................", 
        "           ......................'..'......    .......", 
        "        .........................'..'.....       .......", 
        "     ........    ..'.............'..'....      ..........", 
        "   ..'..'...      ...............'.......      ..........", 
        "  ...'......     ...... ..........  ......         .......", 
        " ...........   .......              ........        ......", 
        ".......        '...'.'.              '.'.'.'         ....", 
        ".......       .....'..               ..'.....", 
        "   ..       ..........               ..'........", 
        "          ............               ..............", 
        "         .............               '..............", 
        "        ...........'..              .'.'............", 
        "       ...............              .'.'.............", 
        "      .............'..               ..'..'...........", 
        "      ...............                 .'..............", 
        "       .........                        ..............", 
        "        .....", 
        "", 
        "", 
        "**Environment**", 
        "Platform: .NET Core 1.0", 
        "OS: Microsoft Windows 10.0.14393 ", 
        ""
    ]
}

```


## Step 2 - How to run a simple Spring Boot App inside a Docker Windows Container with Ansible ([step2-single-spring-boot-app](https://github.com/jonashackt/ansible-windows-docker-springboot/tree/master/step2-single-spring-boot-app))


Everything needed here is inside [step2-single-spring-boot-app](https://github.com/jonashackt/ansible-windows-docker-springboot/tree/master/step2-single-spring-boot-app). Be sure to have cloned and (Maven-) build the example simple Spring Boot app [weatherbackend](https://github.com/jonashackt/spring-cloud-netflix-docker/tree/master/weatherbackend). Let´s cd into `step2-single-spring-boot-app` and run the playbook:

```
ansible-playbook -i hostsfile ansible-windows-docker-springboot.yml --extra-vars "host=ansible-windows-docker-springboot-dev app_name=weatherbackend jar_input_path=../../cxf-spring-cloud-netflix-docker/weatherbackend/target/weatherbackend-0.0.1-SNAPSHOT.jar"
```

This should run a single Spring Boot app inside a Docker Windows Container on your Windows box.

![spring-boot-example-running-docker-windows-containers](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/spring-boot-example-running-docker-windows-containers.png)

## Step 3 - How to scale multiple Spring Boot Apps inside a Docker Windows Containers with Ansible, docker-compose and Spring Cloud Netflix ([step4-multiple-spring-boot-apps-docker-compose](https://github.com/jonashackt/ansible-windows-docker-springboot/tree/master/step4-multiple-spring-boot-apps-docker-compose))


Everything needed here is inside [step3-multiple-spring-boot-apps-docker-compose](https://github.com/jonashackt/ansible-windows-docker-springboot/tree/master/step3-multiple-spring-boot-apps-docker-compose). Be sure to have cloned and (Maven-) build the complete Spring Cloud example apps [cxf-spring-cloud-netflix-docker](https://github.com/jonashackt/spring-cloud-netflix-docker).  Let´s cd into `step3-multiple-spring-boot-apps-docker-compose` and run the playbook:

```
ansible-playbook -i hostsfile ansible-windows-docker-springboot.yml --extra-vars "host=ansible-windows-docker-springboot-dev"
```

This will fire up multiple containers running Spring Boot Apps inside Docker Windows Containers on your Windows box. They will leverage the power of Spring Cloud Netflix with Zuul as a Proxy and Eureka as Service Registry (which dynamically tells Zuul, which Apps to route).

But with [docker-compose](https://docs.docker.com/compose/) you are now able to __easily fire up your hole application with one command__ (`docker-compose`) and deployment with Ansible also gets much faster through that (all the Docker containers are build at once and startet in parallel).
Additionally, it is now possible to easily scale your Containers. If you want to scale the weatherbackend from 1 to 5 containers for example, just do the following inside __c:\spring-boot\__ :

```
docker-compose scale weatherbackend=5
```

A few seconds later (depending on the power of your machine), you should be able to see them all in Eureka:

![spring-cloud-example-running-docker-windows-containers-docker-compose](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/spring-cloud-example-running-docker-windows-containers-docker-compose.png)



## Best practices

##### Using Powershell on Host to Connect to Container

```
docker ps -a 
```
Look up your containers´ id, then do
```
docker exec -ti YourContainerIdHere powershell
```

##### Check if your Spring Boot app is running inside the Container

```
iwr http://localhost:8080/swagger-ui.html -UseBasicParsing
```

##### Set Proxy with Ansible, if you have a corporate firewall

See https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon:

```
  - name: Set Proxy for docker pull to work (http)
    win_environment:
      state: present
      name: HTTP_PROXY
      value: http://username:password@proxy:port/
      level: machine

  - name: Set Proxy for docker pull to work (https)
    win_environment:
      state: present
      name: HTTPS_PROXY
      value: http://username:password@proxy:port/
      level: machine
```

## Known Issues

If something doesnt work as expected, see this guide here https://docs.microsoft.com/en-us/virtualization/windowscontainers/troubleshooting

Especially this command here is useful to check, whether something isn´t working as expected:
```
Invoke-WebRequest https://aka.ms/Debug-ContainerHost.ps1 -UseBasicParsing | Invoke-Expression
```

And network seems to be a really tricky part with all this non-localhost, Hyper-V network-stuff ...

#### Network

Good overview:

![windows-docker-network-architecture](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/windows-docker-network-architecture.png)
(from https://blogs.technet.microsoft.com/virtualization/2016/05/05/windows-container-networking/)

###### Useful commands

Show Docker Networks
```
docker network ls
```

Inspect one of these networks
```
docker network inspect networkNameHere
```

A good (e.g. working) starting configuration for the Windows Docker Network shows something like this

![docker-network-correct-nat-config](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/docker-network-correct-nat-config.png)

If the "IPAM" section shows an empty Subnet & Gateway, you may have the problem, that your NAT wont work and you can´t connect to your Docker-Containers from the Windows Docker Host itself (see Caveats and Gotchas section on https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-networking)

###### localhost to forward to Windows Containers isn´t working as expected

[On Windows it isn´t possible to do what you know from Linux](https://blog.sixeyed.com/published-ports-on-windows-containers-dont-do-loopback/): Run a `docker run -d -p 80:80 microsoft/iis` and go to `http://localhost` won´t work sadly! But before I hear you scream: "Hey, why is that `-p 80:80` thingy for - if that simple thing isn´t working?!" Well, if you come from outside the Windows Docker Host Maschine and try this IP, it will work - so everything will work, except of your localhost-Tests :D

> But this is only temporarily --> The Windows Docker team is on it and the fix will be released soon as a Windows Update - see [github Issue 458](https://github.com/docker/for-win/issues/458)

###### Network docs

Helpful knowledge! Docker Windows Networks work slightly different to Linux ones (localhost!) https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-networking

https://blogs.technet.microsoft.com/virtualization/2016/05/05/windows-container-networking/

https://4sysops.com/archives/windows-container-networking-part-1-configuring-nat/

## Resources

##### Microsoft & Docker Inc docs

[Windows Containers Documentation](https://docs.microsoft.com/en-us/virtualization/windowscontainers/index)

[Configure Docker on Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon)

https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-server

https://docs.docker.com/docker-for-windows/troubleshoot/

https://docs.docker.com/docker-for-windows/#docker-settings

https://www.docker.com/microsoft

https://docs.com/taylorb/8408/dockercon-2016-dockerizing-windows-server?c=4TNCe4

https://blogs.technet.microsoft.com/virtualization/2016/10/18/use-docker-compose-and-service-discovery-on-windows-to-scale-out-your-multi-service-container-application/

https://github.com/Microsoft/Virtualization-Documentation/tree/live/windows-container-samples

https://blogs.technet.microsoft.com/virtualization/2017/02/09/overlay-network-driver-with-support-for-docker-swarm-mode-now-available-to-windows-insiders-on-windows-10/

Newest Insider builds: https://insider.windows.com/ or here https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewadvanced


##### Good resources

https://blog.docker.com/2016/09/build-your-first-docker-windows-server-container/

[Walktrough Windows Docker Containers](https://github.com/artisticcheese/artisticcheesecontainer/wiki)

[Video: John Starks’ black belt session about Windows Server & Docker at DockerCon ‘16](https://www.youtube.com/watch?v=85nCF5S8Qok)

https://blog.sixeyed.com/windows-containers-and-docker-5-things-you-need-to-know/

https://github.com/StefanScherer/dockerfiles-windows

https://github.com/joefitzgerald/packer-windows

https://github.com/StefanScherer/docker-windows-box

Install docker-compose on Windows Server 2016: https://github.com/docker/for-win/issues/448#issuecomment-276328342

If Service discovery doen´t work reliable: http://stackoverflow.com/questions/43041297/docker-dns-for-service-discovery-to-resolve-windows-container%C2%B4s-address-by-name/43041298#43041298



# Docker Container Orchestration with Linux & Windows mixed OS setup

Example steps showing how to provision and run Spring Boot Apps with Docker Swarm &amp; Docker in mixed mode on Linux AND Windows (Docker Windows Containers!)

## Why more?

We went quite fare with that setup - and broke up most boundaries inside our heads, what´s possible with Windows. But there´s one step left: leaving the one machine our services are running on and do a step further to go for a multi-machine setup, incl. blue-green-deployments/no-time-out-deployments and kind of "bring-my-hole-app-UP" (regardles, on which server it is running)

## Kubernetes or Docker Swarm?

Everything seems to point to Kubernetes - biggest mediashare, most google searches, most blog posts and so on. But there´s one thing that __today__ bring´s me on the Docker Swarm path: And that´s the __Docker Windows Container Support__ in the current feature set implemented. As of Kubernetes 1.6 Windows Server 2016 (which is capable of running Windows Server Containers) there´s a basic support of Docker Windows Containers in Kubernetes - with two main limitations:

* Networksubsystem HNS isn´t really Kubernetes-ready - so you have to manually put Routingtables together
* Only one Docker Container per Pod is supported right now

Both things mean, that you litterally can´t leverage the benefits of Kubernetes as a Container Orchestration tool with Docker Windows Containers right now. Things might change soon though, if Microsoft releases it´s Version 1709 Windows Server 2016 and Kubernetes 1.8 goes live. But both isn´t now, so we first of all have to go with the competitor Docker Swarm, which should be also a good thing to start - and we´ll later switch to Kubernetes.


## Step 4 - A Multi-machine Windows- & Linux- mixed OS Vagrant setup ([step4-windows-linux-multimachine-vagrant](https://github.com/jonashackt/ansible-windows-docker-springboot/tree/master/step4-windows-linux-multimachine-vagrant))

There are basically two options to achieve a completely comprehensible setup: running more than one virtual machine on your local machine or go into the cloud. To decide which way to go, I had to rethink about what I wanted to show with this project. My goal is to show a setup of an Docker Orchestration tool to scale Docker Containers on both Windows and Linux - without messing with the specialities of one of the many cloud providers. Not to mention the financial perspective. So for the first setup, I wanted to go with a few virtual machines that run on my laptop.

As I really got to love Vagrant as a tool to handle my Virtual machines, why not do it with that again? And thank´s to a colleague of mine´s hint, I found the [Vagrant multi-machine docs](https://www.vagrantup.com/docs/multi-machine/).


Inside the `step0-packer-windows-vagrantbox` directory start the build for another Windows box (that does not provide a provider config, which wouldn´t work within a Vagrant multimachine setup) with this command:

```
packer build -var iso_url=14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO -var iso_checksum=70721288bbcdfe3239d8f8c0fae55f1f -var template_url=vagrantfile-windows_2016-multimachine.template -var box_output_name=windows_2016_docker_multimachine2.box windows_server_2016_docker.json
```

Add new Windows 2016 Vagrant box:
```
vagrant box add --name windows_2016_multimachine windows_2016_docker_multimachine.box
```

Now switch over to `step4-windows-linux-multimachine-vagrant` directory and do a:

```
vagrant up
```

Now we´re ready to play. And nevermind, if you want to have a break or your notebook is running hot - just type a `vagrant halt`. And the whole zoo of machines will be stopped for you :)



##### Ping all

As Ansible is a really nice tool, that let´s you use the same host in multiple groups - and merges the group_vars from all of those according to that one host - it isn´t a good idea to use a structure like that in your inventory file:

```
[masterwindows]
127.0.0.1

[masterlinux]
127.0.0.1

[workerwindows]
127.0.0.1
```

And try to use different corresponding group_vars entries... Because, you don´t know, which variables will be present!

See https://github.com/ansible/ansible/issues/9065

But what if we were able to change the /etc/hosts on our Host machine with every `vagrant up`? (https://stackoverflow.com/questions/16624905/adding-etc-hosts-entry-to-host-machine-on-vagrant-up) That´s possible with the https://github.com/cogitatio/vagrant-hostsupdater, install it with:

#### Different hostnames

Current workaround: configure ~/hosts

```
127.0.0.1 masterlinux01
127.0.0.1 workerlinux01
127.0.0.1 masterwindows01
127.0.0.1 workerwindows01
```


tbd
```
vagrant plugin install vagrant-hostsupdater
```

#### working Ansible SSH config

cd into `masterlinux` and (you´ll maybe need to install sshpass (e.g. via `brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb` (as `brew install sshpass` won´t work, see https://stackoverflow.com/questions/32255660/how-to-install-sshpass-on-mac):

Before (see https://stackoverflow.com/questions/34718079/add-host-to-known-hosts-file-without-prompt/34721229)

```
export ANSIBLE_HOST_KEY_CHECKING=False
```

```
ansible-playbook -i hostsfile prepare-docker-nodes.yml
```

```
unset ANSIBLE_HOST_KEY_CHECKING
```

As you may noticed, there´s an extra for Windows Server 2016. Because we want our machines to be accessible from each other, we have to allow the very basic command everybody start´s with: the ping. That one is blocked by the Windows firewall ad a default and we have to open that up with the following [Powershell command](https://technet.microsoft.com/de-de/library/dd734783(v=ws.10).aspx#BKMK_3_add) - obviously wrapped inside a Ansible task:

```
  - name: Allow Ping requests on Windows nodes (which is by default disabled in Windows Server 2016)
    win_shell: "netsh advfirewall firewall add rule name='ICMP Allow incoming V4 echo request' protocol=icmpv4:8,any dir=in action=allow"
    when: inventory_hostname in groups['workerwindows']
```





# Links

#### General comparison of Docker Container Orchestrators

mindshare: https://platform9.com/blog/kubernetes-docker-swarm-compared/

marketshare: https://blog.netsil.com/kubernetes-vs-docker-swarm-vs-dc-os-may-2017-orchestrator-shootout-fdc59c28ec16

https://www.loomsystems.com/blog/single-post/2017/06/19/kubernetes-vs-docker-swarm-vs-apache-mesos-container-orchestration-comparison

#### Windows Server

https://blogs.technet.microsoft.com/hybridcloud/

https://blogs.technet.microsoft.com/hybridcloud/2017/05/10/windows-server-for-developers-news-from-microsoft-build-2017/

Windows Server Pre-Release (Insider): https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewserver

Current state discription: https://blogs.windows.com/windowsexperience/2017/07/13/announcing-windows-server-insider-preview-build-16237/#tx4mFJzTSMIjl2gX.97 --> coming version 1709 of Windows Server 2016 will have better Kubernetes support with no more manual tinkering with routing tables (better HNS)

#### Docker Swarm

Docker Swarm Windows Docs: https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/swarm-mode

Windows Server 2016 Overlay Networking Support (Windows & Linux mixed mode): https://blogs.technet.microsoft.com/virtualization/2017/04/18/ws2016-overlay-network-driver/

Windows & Linux mixed Video: https://www.youtube.com/watch?v=ZfMV5JmkWCY

#### Kubernetes

Docker Windows Containers & Kubernetes: https://blogs.technet.microsoft.com/networking/2017/04/04/windows-networking-for-kubernetes/

Kubernetes Networking on Windows: https://www.youtube.com/watch?v=P-D8x2DndIA&t=6s&list=PL69nYSiGNLP2OH9InCcNkWNu2bl-gmIU4&index=1

http://www.serverwatch.com/server-news/why-kubernetes-sucks-and-how-to-fix-it.html

http://blog.kubernetes.io/2016/12/windows-server-support-kubernetes.html

https://www.youtube.com/watch?v=Tbrckccvxwg

https://kubernetes.io/docs/getting-started-guides/windows/

https://github.com/kubernetes/features/issues/116

minikube howto: http://www.sqlservercentral.com/blogs/the-database-avenger/2017/06/13/orchestrating-sql-server-with-kubernetes/

https://groups.google.com/forum/#!forum/kubernetes-sig-windows

http://blog.kubernetes.io/2017/08/kompose-helps-developers-move-docker.html?m=1

