ansible-windows-springboot
======================================================================================
[![Build Status](https://travis-ci.org/jonashackt/ansible-windows-springboot.svg?branch=master)](https://travis-ci.org/jonashackt/ansible-windows-springboot)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-jonashackt-660198.svg)](https://galaxy.ansible.com/jonashackt)

## Example ansible playbook - showing how to provision, deploy and run a Spring Boot app as a Windows Service using Ansible, chocolatey &amp; nssm

There´s a blog post with more background information here: [Running Spring Boot Apps on Windows with Ansible (codecentric.de)](https://blog.codecentric.de/en/2017/01/ansible-windows-spring-boot/)

> Isn´t Ansible SSH-only?

From Version 1.7 on, Ansible also supports managing Windows machines. This is done with native PowerShell remoting (and Windows Remote Management [WinRM](https://technet.microsoft.com/en-us/library/ff700227.aspx)) instead of SSH, as you can [read in the docs](http://docs.ansible.com/ansible/intro_windows.html).


## Prerequisites

Go to https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/#downloads and download an Vagrant image with Windows 10 (e.g. for VirtualBox - be sure to have the VM-Provider installed). You should get something like a MSEdge.Win10_RS1.Vagrant.zip - extract it (Mac: with the [Unarchiver](http://wakaba.c3.cx/s/apps/unarchiver.html)) and there you are: The Windows Vagrant box __dev-msedge.box__ is ready :)

Because Microsoft doesn´t seem to ship metadata for the box, add it to Vagrant via:

```
vagrant box add dev-msedge.box --name "windows10"
```

I added a Vagrantfile to this repository, so you can start right away by (if you have Vagrant installed ;) )
```
vagrant up
```

Because we use Windows, SSH for example will not work and we need to tweak some Vagrant Configuration Options described here: https://www.vagrantup.com/docs/vagrantfile/winrm_settings.html


## Prepare the Windows Box for Ansible Communication

Doku: http://docs.ansible.com/ansible/intro_windows.html#windows-system-prep

### prepare the Windows box

> If you have Windows >= v10, just skip the follwing steps & proceed with [Configure remote access for ansible](https://github.com/jonashackt/ansible-windows-springboot#configure-remote-access-for-ansible)

#### Allow execution of scripts on Powershell:
```
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
```

#### Upgrade to Powershell 3.0

If __get-host__ shows something < 3.0, you should upgrade with https://github.com/cchurch/ansible/blob/devel/examples/scripts/upgrade_to_ps3.ps1 (this will [reboot your Windows box!](http://serverfault.com/questions/539229/possible-to-upgrade-powershell-2-0-to-3-0-without-a-reboot) )

#### Configure remote access for ansible

On a Powershell with Admin rights, run:
```
iwr https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -UseBasicParsing | iex
```

(or if that doesn´t work (e.g., if your Powershell Version does not know __iwr__), download the Script https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 and run it manually from Powershell).


#### Testdrive Ansible connectivity
```
ansible restexample-windows-dev -i hostsfile -m win_ping
```

If this brings you something like the following output, __your Windows Box is ready for Ansible!__:
```
127.0.0.1 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

If you have something like
```
127.0.0.1 | UNREACHABLE! => {
    "changed": false, 
    "msg": "ssl: the specified credentials were rejected by the server", 
    "unreachable": true
}
```
then your UserName or Password is not correct - and trust me, double or tripple check this before moving to the next point :)

If you get a read time out, your Windows Box is most likely not configured correctly:
```
127.0.0.1 | UNREACHABLE! => {
    "changed": false, 
    "msg": "ssl: HTTPSConnectionPool(host='127.0.0.1', port=55986): Read timed out. (read timeout=30)", 
    "unreachable": true
}
```
check, if you already successfully ran [Configure remote access for ansible](https://github.com/jonashackt/ansible-windows-springboot#configure-remote-access-for-ansible)




## Choose an Spring Boot app to deploy

Just take the simple project here: https://github.com/jonashackt/restexamples

Either way you choose: Be sure to have a working Build in Place, so that you have a runnable Spring Boot jar-File in place (e.g. restexamples-0.0.1-SNAPSHOT.jar). For the example project [restexamples](https://github.com/jonashackt/restexamples) you get this by running:
```
mvn clean package
```


## Craft a Windows-ready ansible playbook

I did that step already for you :) So let´s run our the playbook restexample-windows.yml:

```
ansible-playbook -i hostsfile restexample-windows.yml --extra-vars "spring_boot_app_jar=../restexamples/target/restexamples-0.0.1-SNAPSHOT.jar spring_boot_app_name=restexample-springboot host=restexample-windows-dev"
```



## Best practices

* __ALWAYS__: escape \ in paths with "\" --> e.g. C:\\\temp
* don´t assume that a path with C:\ProgamFiles (x86)\XYZ will work (e.g. for Java better use "C:\\\ProgramData\\\Oracle\\\Java\\\javapath\\\java.exe")
* if chocolatey doesn´t want to work, you have to install it once manually on your Windows box
```
iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
```