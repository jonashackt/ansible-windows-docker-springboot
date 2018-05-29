# Build all Applications docker images and deploy to Swarm
ansible-playbook -i hostsfile build-and-deploy-apps-2-swarm.yml

# Just deploy all Applications to Swarm (they have to been build once before that will work out)
ansible-playbook -i hostsfile build-and-deploy-apps-2-swarm.yml --skip-tags "buildapps"

# Only open Firewall ports for Apps
ansible-playbook -i hostsfile build-and-deploy-apps-2-swarm.yml --skip-tags="deploy,buildapps"

