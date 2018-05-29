
# Run Spring Boot App on Docker Windows
ansible-playbook -i hostsfile ansible-windows-docker-springboot.yml --extra-vars "host=ansible-windows-docker-springboot-dev app_name=weatherbackend jar_input_path=../../cxf-spring-cloud-netflix-docker/weatherbackend/target/weatherbackend-0.0.1-SNAPSHOT.jar"

