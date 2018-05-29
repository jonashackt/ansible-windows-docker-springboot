
# Check if Connection works
ansible windows-dev -i hostsfile -m win_ping

# Prepare Docker on Windows
ansible-playbook -i hostsfile prepare-docker-windows.yml --extra-vars "host=ansible-windows-docker-springboot-dev"
