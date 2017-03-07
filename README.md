ansible-windows-docker-springboot
======================================================================================
[![Build Status](https://travis-ci.org/jonashackt/ansible-windows-docker-springboot.svg?branch=master)](https://travis-ci.org/jonashackt/ansible-windows-docker-springboot)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-jonashackt-660198.svg)](https://galaxy.ansible.com/jonashackt)

## Example project showing how to provision, deploy and run Spring Boot apps inside Windows Docker Containers on Windows using Packer, Powershell, Vagrant & Ansible

This is a follow-up to the repository [ansible-windows-springboot](https://github.com/jonashackt/ansible-windows-springboot) and the blog post [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/).

Because [Microsoft &amp; Docker Inc. developed a native Docker implementation on Windows](https://blog.docker.com/2016/09/dockerforws2016/) using Hyper-V (or even a thinner layer) which let´s you run tiny little Windows containers inside your Windows box, which are accessible through the Docker API, I wanted to get my hands on them as soon as I heard of it. A list of [example Windows Docker Images is provided here](https://hub.docker.com/r/microsoft/).

Firing up Spring Boot apps with Ansible on Windows using Docker sound´s like the next step after [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/).


> Before we start: The most important point here is to start with a __correct Build Number__ of Windows 10 (1607, Anniversary Update)/Windows Server 2016. It took me days to figure that out, but it won´t work with for example 10.0.14393.67 - but will with 10.0.14393.206! I ran over [the advice on this howto](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10) to fast, because I thought "Windows 10 Anniversary should be enough, don´t bother me with build numbers". But take care! The final `docker run` won´t work (but all the other steps before, which made it so hard to understand)... Here are two examples of the output of a `(Get-ItemProperty -Path c:\windows\system32\hal.dll).VersionInfo.FileVersion` on a Powershell:

__Good build number:__

![Windows_build_number_Docker_working](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/Windows_build_number_Docker_working.png)

__Bad build number:__

![Windows_build_number_Docker_failing](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/Windows_build_number_Docker_failing.png)

Because of the minimal required build of Windows 10 or Server 2016, we sadly can´t use the easy to download and easy to handle [Vagrant box with Windows 10 from the Microsoft Edge developer site](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/#downloads). So we have to look after an alternative box to start from. My goal was to start from a original Microsoft Image and show a 100% replicable way how to get to a running Vagrant box. Because besides the Microsoft Edge boxes (which have don´t have the correct build number for now) there aren´t any official from Microsoft around in [Vagrant Atlas](https://atlas.hashicorp.com/boxes/search?utf8=%E2%9C%93&sort=&provider=&q=windows+10). And hey - we´re dealing with Windows! I don´t want to have someone installing things on a VM I don´t know... 


## Finding a Windows Box - the Evalutation ISOs

After a bit of research, you´ll find another way to evaluate a current Windows 10 Version: The [Windows 10 Enterprise Evalutation ISO](https://www.microsoft.com/de-de/evalcenter/evaluate-windows-10-enterprise) or the [Windows Server 2016 Evalutation ISO](https://www.microsoft.com/de-de/evalcenter/evaluate-windows-server-2016). But how do we get from ISO to our easy-to-use Vagrant box? Well, we can  packer tbd

Both the Windows 2016 Server and the 10 Enterprise come with a 180 Days Evaluation licence (you have to register a live-ID for that)

Here we´ll use the 2016 Server ISO, but you can switch to 10 Enterprise with no problem (use __14393.0.160715-1616.RS1_RELEASE_CLIENTENTERPRISE_S_EVAL_X64FRE_EN-US.ISO__ instead). Download the __14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO__ and place it into the __/packer__ folder.

The problem with an ISO - it´s not a nice Vagrant box we can fireup easily for development. But hey! There´s something for us: [packer.io](https://packer.io/). This smart tool is able to produce machine images in every flavour - also as a Vagrant box ;) And [from the docs](https://www.packer.io/docs/post-processors/vagrant.html):

> "[Packer] ... is in fact how the official boxes distributed by Vagrant are created."

We also install Windows completely [unattended](https://social.technet.microsoft.com/wiki/contents/articles/36609.windows-server-2016-unattended-installation.aspx) - which means, we don´t have to click on a single installation screen ;)


On a Mac you can install it with:

`brew install packer` 


Now start packer with this command:

```
packer build -var iso_url=14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO -var iso_checksum=70721288bbcdfe3239d8f8c0fae55f1f windows_server_2016_docker.json
```

Now get yourself a coffee. This will take some time ;)

After successful packer build, you can add the box to your Vagrant installation:
```
vagrant box add windows_2016_docker windows_2016_docker_virtualbox.box
```

If everything went fine, fire up your Windows 10/Server 2016 box:

```
vagrant up
```


## Prepare your Windows Box to run Docker Windows Containers with Ansible

If you don´t want to go with the dicribed way of using packer to build your own Vagrant box and start with your own custom Windows 10 machine right away - no problem! Just be sure to [prepare your machine correctly for Ansible](https://github.com/jonashackt/ansible-windows-springboot#prepare-the-windows-box-for-ansible-communication).

Now let´s check the Ansible connectivity:

```
ansible ansible-windows-docker-springboot-dev -i hostsfile -m win_ping
```

Getting a __SUCCESS__ responde, we can start to prepare our Windows box to run Windows Docker Containers. Let´s run the preparation playbook: 

```
ansible-playbook -i hostsfile prepare-docker-windows.yml --extra-vars "host=ansible-windows-docker-springboot-dev"
```

This do everything for you: 

* Checking, if you have the correct minimum build version of Windows
* Install the necessary Windows Features `containers` and `Hyper-V` (this is done Windows Version agnostic - so it will work with Windows 10 AND Server 2016 - which is quite unique, becaue Microsoft itself always distinquishes between these versions)
* Reboot your Windows Box, if necessary
* Install the current Docker version (via [chocolatey docker package](https://chocolatey.org/packages/docker). And although the package claims to only install the client, it also provides the Docker Server (which means this is 100% identical with the [step 2. Install Docker in Microsoft´s tutorial](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10)).)
* Register and Start the Docker Windows service

If you want to, you can run your first Windows container inside your Windows box within a priviledged Powershell:

```
docker run microsoft/dotnet-samples:dotnetapp-nanoserver
```

If Docker on Windows with Windows Docker Containers is fully configured, you should see something like this:

```
         Dotnet-bot: Welcome to using .NET Core!
    __________________
                      \
                       \
                          ....
                          ....'
                           ....
                        ..........
                    .............'..'..
                 ................'..'.....
               .......'..........'..'..'....
              ........'..........'..'..'.....
             .'....'..'..........'..'.......'.
             .'..................'...   ......
             .  ......'.........         .....
             .                           ......
            ..    .            ..        ......
           ....       .                 .......
           ......  .......          ............
            ................  ......................
            ........................'................
           ......................'..'......    .......
        .........................'..'.....       .......
     ........    ..'.............'..'....      ..........
   ..'..'...      ...............'.......      ..........
  ...'......     ...... ..........  ......         .......
 ...........   .......              ........        ......
.......        '...'.'.              '.'.'.'         ....
.......       .....'..               ..'.....
   ..       ..........               ..'........
          ............               ..............
         .............               '..............
        ...........'..              .'.'............
       ...............              .'.'.............
      .............'..               ..'..'...........
      ...............                 .'..............
       .........                        ..............
        .....


**Environment**
Platform: .NET Core 1.0
OS: Microsoft Windows 10.0.14393
```

If something doesnt work as expected, see this guide here https://docs.microsoft.com/en-us/virtualization/windowscontainers/troubleshooting

## Craft a Windows-ready ansible playbook


As usual, I did that step already for you :) So let´s run our main playbook now:

```
ansible-playbook -i hostsfile ansible-windows-docker-springboot.yml --extra-vars "spring_boot_app_jar=../restexamples/target/restexamples-0.0.1-SNAPSHOT.jar spring_boot_app_name=restexample-springboot host=ansible-windows-docker-springboot-dev"
```



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

##### localhost to forward to Windows Containers isn´t working as expected

[On Windows it isn´t possible to do what you know from Linux](https://blog.sixeyed.com/published-ports-on-windows-containers-dont-do-loopback/): Run a `docker run -d -p 80:80 microsoft/iis` and go to `http://localhost` won´t work sadly! But before I hear you scream: "Hey, why is that `-p 80:80` thingy for - if that simple thing isn´t working?!" Well, if you come from outside the Windows Docker Host Maschine and try this IP, it will work - so everything will work, except of your localhost-Tests :D

> But this is only temporarily --> The Windows Docker team is on it and the fix will be released soon as a Windows Update - see [github Issue 458](https://github.com/docker/for-win/issues/458)



## Resources

##### Microsoft & Docker Inc docs

[Windows Containers Documentation](https://docs.microsoft.com/en-us/virtualization/windowscontainers/index)

[Configure Docker on Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon)

https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-server

https://docs.docker.com/docker-for-windows/troubleshoot/

https://docs.docker.com/docker-for-windows/#docker-settings

https://www.docker.com/microsoft


##### Good resources

https://blog.docker.com/2016/09/build-your-first-docker-windows-server-container/

[Walktrough Windows Docker Containers](https://github.com/artisticcheese/artisticcheesecontainer/wiki)

[Video: John Starks’ black belt session about Windows Server & Docker at DockerCon ‘16](https://www.youtube.com/watch?v=85nCF5S8Qok)

https://blog.sixeyed.com/windows-containers-and-docker-5-things-you-need-to-know/

https://github.com/StefanScherer/dockerfiles-windows

https://github.com/joefitzgerald/packer-windows

https://github.com/StefanScherer/docker-windows-box

