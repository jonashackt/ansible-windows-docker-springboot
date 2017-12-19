# Prepare Docker on all Cluster nodes
ansible-playbook -i hostsfile prepare-docker-nodes.yml

# Only prepare base image springboot-oraclejre-nanoserver
ansible-playbook -i hostsfile prepare-docker-nodes.yml --tags "baseimage"

# Leave out newer Docker installation
ansible-playbook -i hostsfile prepare-docker-nodes.yml --skip-tags "dockerinstall"

# Initialize Docker Swarm
ansible-playbook -i hostsfile initialize-docker-swarm.yml

