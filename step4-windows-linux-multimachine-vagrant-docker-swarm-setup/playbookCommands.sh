# Prepare Docker on all Cluster nodes
ansible-playbook -i hostsfile prepare-docker-nodes.yml

# Only prepare base image springboot-oraclejre-nanoserver
ansible-playbook -i hostsfile prepare-docker-nodes.yml --tags "baseimage"

# Initialize Docker Swarm
ansible-playbook -i hostsfile initialize-docker-swarm.yml

