ansible-windows-docker-springboot
======================================================================================
[![Build Status](https://travis-ci.org/jonashackt/ansible-windows-docker-springboot.svg?branch=master)](https://travis-ci.org/jonashackt/ansible-windows-docker-springboot)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-jonashackt-660198.svg)](https://galaxy.ansible.com/jonashackt)

## Example project showing how to provision, deploy and run a Spring Boot app with Docker Native on Windows using Ansible &amp; chocolatey

This is a follow-up to the repository [ansible-windows-springboot](https://github.com/jonashackt/ansible-windows-springboot) and the blog post [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/).

Because [Microsoft &amp; Docker Inc. developed a native Docker implementation on Windows](https://blog.docker.com/2016/09/dockerforws2016/) using Hyper-V (or even a thinner layer) which let´s you run tiny little Windows containers inside your Windows box, which are accessible through the Docker API, I wanted to get my hands on them as soon as I heard of it. A list of [example Windows Docker Images is provided here](https://hub.docker.com/r/microsoft/).

Firing up Spring Boot apps with Ansible on Windows using Docker sound´s like the next step after [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/).


> Before we start: The most important point here is to start with a __correct Build Number__ of Windows 10 (1607, Anniversary Update)/Windows Server 2016. It took me days to figure that out, but it won´t work with for example 10.0.14393.67 - but will with 10.0.14393.206! I ran over [the advice on this howto](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10) to fast, because I thought "Windows 10 Anniversary should be enough, don´t bother me with build numbers". But take care! The final `docker run` won´t work (but all the other steps before, which made it so hard to understand)... Here are two examples of the output of a `(Get-ItemProperty -Path c:\windows\system32\hal.dll).VersionInfo.FileVersion` on a Powershell:

__Good build number:__

![Windows_build_number_Docker_working](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/Windows_build_number_Docker_working.png)

__Bad build number:__

![Windows_build_number_Docker_failing](https://github.com/jonashackt/ansible-windows-docker-springboot/blob/master/Windows_build_number_Docker_failing.png)

Because of the minimal required build of Windows 10 or Server 2016, we sadly can´t use the easy to download and easy to handle [Vagrant box with Windows 10 from the Microsoft Edge developer site](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/#downloads). So we have to look after an alternative box to start from. My goal was to start from a original Microsoft Image and show a 100% replicable way how to get to a running Vagrant box. Because besides the Microsoft Edge boxes (which have don´t have the correct build number for now) there aren´t any official from Microsoft around in [Vagrant Atlas](https://atlas.hashicorp.com/boxes/search?utf8=%E2%9C%93&sort=&provider=&q=windows+10). And hey - we´re dealing with Windows! I don´t want to have someone installing things on a VM I don´t know... 


##### Another Base - the Windows 2016 Evalutation ISO

After a bit of research, you´ll find another way to evaluate a current Windows 10 Version: The [Windows Server 2016 Evalutation ISO](https://www.microsoft.com/de-de/evalcenter/evaluate-windows-server-2016). But how do we get from ISO to our easy-to-use Vagrant box? Well, we can  packer tbd




The Windows 2016 Server ISO with 180 Days Evaluation licence (you have to register a live-ID for that): https://www.microsoft.com/de-de/evalcenter/evaluate-windows-server-2016

Download the __14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO__ and place it into the __/packer__ folder.

The problem with an ISO - it´s not a nice Vagrant box we can fireup easily for development. But hey! There´s something for us: [packer.io](https://packer.io/). This smart tool is able to produce machine images in every flavour - also as a Vagrant box ;) And [from the docs](https://www.packer.io/docs/post-processors/vagrant.html):

> "[Packer] ... is in fact how the official boxes distributed by Vagrant are created."

We also install Windows Server 2016 in an [unattended mode](https://social.technet.microsoft.com/wiki/contents/articles/36609.windows-server-2016-unattended-installation.aspx).


On a Mac you can install it with:

`brew install packer` 


Now start packer with this command:

```
packer build --only=virtualbox-iso -var iso_url=14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO -var iso_checksum=70721288bbcdfe3239d8f8c0fae55f1f windows_server_2016_docker.json
```

After you clicked "Evaluation Licence ok", you can get yourself a coffee. This will take some time ;)

After successful packer build, you can add the box to your Vagrant installation:
```
vagrant box add windows_2016_docker windows_2016_docker_virtualbox.box
```


###### Install Container feature:

```
Enable-WindowsOptionalFeature -Online -FeatureName containers -All
```

Only needed, because Ansible doesn´t support installation of Windows features in Windows 10 non-Server edition, although it is possible with the [Anniversary Edition](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10). Your Box will restart after that command...

Therefor try this:

```
- win_shell: Enable-WindowsOptionalFeature -Online -FeatureName containers -All
```

####### Install Hyper-V

```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```



###### Testdrive Docker Windows Container on Windows

Try this:

```
docker run microsoft/dotnet-samples:dotnetapp-nanoserver
```

If everything went well, you should see something like this:

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

###### Testdrive your App

```
docker run -it -P --name containername1 imagename:1
```


## Craft a Windows-ready ansible playbook

###### Downlaod Java

[Download Server JRE 8](http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html) `.tar.gz` file and drop into the projects dir.



I did that step already for you :) So let´s run our the playbook restexample-windows.yml:

```
ansible-playbook -i hostsfile restexample-windows.yml --extra-vars "spring_boot_app_jar=../restexamples/target/restexamples-0.0.1-SNAPSHOT.jar spring_boot_app_name=restexample-springboot host=restexample-windows-dev"
```

Although the [chocolatey package Docker](https://chocolatey.org/packages/docker) claims to only install the client, it also provides the Docker Server (which means this is 100% identical with the [step 2. Install Docker in Microsoft´s tutorial](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10)).


#####



## Best practices

tbd


## Resources

Really good examples: https://github.com/StefanScherer/dockerfiles-windows & https://github.com/StefanScherer/docker-windows-box

https://blog.docker.com/2016/09/build-your-first-docker-windows-server-container/

https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-server

[Configure Docker on Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon)

Worth a look: [Powershell tools for docker](https://github.com/artisticcheese/artisticcheesecontainer/wiki) - didn´t try, but maybe interesting for some scenarios



https://docs.docker.com/docker-for-windows/troubleshoot/

https://docs.docker.com/docker-for-windows/#docker-settings

https://www.docker.com/microsoft


https://alexandrnikitin.github.io/blog/running-java-inside-windows-container-on-windows-server/


