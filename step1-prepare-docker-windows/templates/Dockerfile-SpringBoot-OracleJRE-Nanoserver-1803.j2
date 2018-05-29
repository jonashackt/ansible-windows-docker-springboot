#jinja2: newline_sequence:'\r\n'
# We need to use the powershell image from 1709 on, because standard nanoserver has no Powershell installed...
# FROM microsoft/powershell:6.0.2-nanoserver-1803
# using windowsservercore instead of nanoserver, its the only working solution right now
FROM microsoft/windowsservercore:1803

# This is a base-Image for running Spring Boot Apps on Docker Windows Containers
MAINTAINER Jonas Hecht

# Extract Server-JRE into C:\\jdk1.8.0_xyz in the Container
ADD {{server_jre_name}} /

# Configure Path for easy Java usage (1709er style)
ENV JAVA_HOME=C:\\jdk1.8.0_{{java8_update_version}}
RUN setx PATH "%JAVA_HOME%\\bin;%PATH%"

# Create logging default path for Spring Boot
VOLUME C:\\tmp