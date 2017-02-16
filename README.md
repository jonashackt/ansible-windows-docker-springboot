ansible-windows-docker-springboot
======================================================================================
[![Build Status](https://travis-ci.org/jonashackt/ansible-windows-docker-springboot.svg?branch=master)](https://travis-ci.org/jonashackt/ansible-windows-docker-springboot)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-jonashackt-660198.svg)](https://galaxy.ansible.com/jonashackt)

## Example project showing how to provision, deploy and run a Spring Boot app with Docker Native on Windows using Ansible &amp; chocolatey

This is a follow-up to the repository [ansible-windows-springboot](https://github.com/jonashackt/ansible-windows-springboot) and the blog post [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/).

Because [Microsoft &amp; Docker Inc. developed a native Docker implementation on Windows](https://blog.docker.com/2016/09/dockerforws2016/) using Hyper-V (or even a thinner layer) which let´s you run tiny little Windows containers inside your Windows box, which are accessible through the Docker API, I wanted to get my hands on them as soon as I heard of it. A list of [example Windows Docker Images is provided here](https://hub.docker.com/r/microsoft/).

Firing up Spring Boot apps with Ansible on Windows using Docker sound´s like the next step after [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/).

Every [Prerequisite](https://github.com/jonashackt/ansible-windows-springboot#prerequisites), [preparation step](https://github.com/jonashackt/ansible-windows-springboot#prepare-the-windows-box-for-ansible-communication) and the need to [choose a Spring Boot app](https://github.com/jonashackt/ansible-windows-springboot#choose-an-spring-boot-app-to-deploy) to run stays the same.

Bringing Docker to the table, we should start with the following step:

> Disclaimer for using a Mac or Linux Machine to Host a virtualized Windows 10 with Hyper-V to run Docker on
I´am not sure, but it could turn out, that this isn´t possible for now - see the [nested Virtualization docs](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/nested-virtualization)






### Additional Preparation Steps for Windows with native Docker

Thanks to the many insights from [StefanScherer](https://github.com/StefanScherer)!

###### Reload Plugin for Vagrant
```
vagrant plugin install vagrant-reload
```




##### Another Base - the Windows 2016 Evalutation ISO

I lost many hours on my way trying to run Windows 10 with Containers inside the easy to download Vagrant box or VMWare image from https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/#downloads. But this somehow didn´t work - either with Virtualbox nor with VMWare Fusion Pro. Therefore we have to take another way. Let´s switch to another base image: The Windows 2016 Server ISO with 180 Days Evaluation licence (you have to register a live-ID for that): https://www.microsoft.com/de-de/evalcenter/evaluate-windows-server-2016

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



###### VirtualBox is sadly not 100% compatible

I lost many hours on my way trying to run Windows 10 with Containers inside of VirtualBox - but because Microsoft & Docker Inc. don´t officially support Virtualized Windows Docker Installations and there´s a slight note, that maybe VMWare or Parallels will work, I changed my Vagrant Provider under the hood. Getting VMWare Fusion Pro to work on your machine, install it (e.g. via `brew cask install vmware-fusion`) and install the [official Vagrant VMWare plugin](https://www.vagrantup.com/docs/vmware/installation.html) via:

```
vagrant plugin install vagrant-vmware-fusion
```

I really wanted to stay with Vagrant and it´s nice Yaml like API, but I had to understand that the [official Vagrant VMWare plugin](https://www.vagrantup.com/docs/vmware/installation.html) is not free and you have to pay for it. You sadly need a licence here :( 

```
vagrant box add dev-msedge.box --name "windows10docker" --provider vmware_fusion
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


