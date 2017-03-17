Ansible ready & packer.io build Windows Server 2016 Vagrant box
======================================================================================
#### packer template and some Powershell scripts to build a Ansible-ready Windows Server 2016 Vagrant box (as alternative to the [Vagrant box with Windows 10 from the Microsoft Edge developer site](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/#downloads), which doesn´t work with Docker because of the wrong build number)

The box has Ansible-connectitity "turned on" (so WinRM, Firewall settings, Network settings and so on) and is a working basis for a Docker Windows Container installment.

It is somehow a fork of bits from https://github.com/StefanScherer/docker-windows-box and https://github.com/StefanScherer/packer-windows, which forks https://github.com/joefitzgerald/packer-windows itself. If you like to dig deeper into the myriads of configuration options, have a look into Stefan Scherers GitHub repositories. kudos go to [Stefan](https://github.com/StefanScherer) und [Joe](Joe Fitzgerald) - and not to forget the great [hashicorp tools](https://www.hashicorp.com/).