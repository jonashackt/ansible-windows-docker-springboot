# Prepare Docker on all Cluster nodes
ansible-playbook -i hostsfile prepare-docker-nodes.yml

# Initialize Docker Swarm
ansible-playbook -i hostsfile initialize-docker-swarm.yml

