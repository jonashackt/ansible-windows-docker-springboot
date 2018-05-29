
# Run Packer build with Windows Server 2016
packer build -var iso_url=14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO -var iso_checksum=70721288bbcdfe3239d8f8c0fae55f1f windows_server_2016_docker.json

# add it to local Vagrant Boxes
vagrant box add --name windows_2016_multimachine windows_2016_docker_multimachine_virtualbox.box


# Run packer build with Windows Server 1709
packer build -var iso_url=en_windows_server_version_1709_x64_dvd_100090904.iso -var iso_checksum=7c73ce30c3975652262f794fc35127b5 -var template_url=vagrantfile-windows_1709-multimachine.template -var box_output_prefix=windows_1709_docker_multimachine windows_server_2016_docker.json

# add it to local Vagrant Boxes
vagrant box add --name windows_1709_docker_multimachine windows_1709_docker_multimachine_virtualbox.box


# Run packer build with Windows Server 1803
packer build -var iso_url=en_windows_server_version_1803_x64_dvd_12063476.iso -var iso_checksum=e34b375e0b9438d72e6305f36b125406 -var template_url=vagrantfile-windows_1803-multimachine.template -var box_output_prefix=windows_1803_docker_multimachine windows_server_2016_docker.json

# add it to local Vagrant Boxes
vagrant box add --name windows_1803_docker_multimachine windows_1803_docker_multimachine_virtualbox.box


