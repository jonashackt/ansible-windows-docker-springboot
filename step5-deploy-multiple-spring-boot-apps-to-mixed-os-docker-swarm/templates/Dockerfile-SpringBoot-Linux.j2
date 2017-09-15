FROM openjdk:8-jdk-alpine

MAINTAINER Jonas Hecht

VOLUME /tmp

ENV REGISTRY_HOST {{spring_boot_app.registry_name}}
ENV SPRINGBOOT_APP_NAME {{spring_boot_app.name}}

# Add Spring Boot app.jar to Container
ADD {{spring_boot_app.name}}.jar app.jar

ENV JAVA_OPTS=""

# Fire up our Spring Boot app by default
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar --server.port={{spring_boot_app.port}}" ]