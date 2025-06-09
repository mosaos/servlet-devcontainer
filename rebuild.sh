#/bin/bash

readonly PROJECT_NAME="servlet-devcontainer"

# package rebuild
docker exec -it javadev mvn clean package -f /workspaces/$PROJECT_NAME/pom.xml
.
# list webapps dir
docker exec -it tomcat ls -la /usr/local/tomcat/webapps
# rm webapp dir
docker exec -it tomcat rm /usr/local/tomcat/webapps/$PROJECT_NAME -rf

# verify delete
docker exec -it tomcat ls -la /usr/local/tomcat/webapps

# docker compose --project-name java-web-devcontainer_devcontainer restart tomcat
docker compose --project-name ${PROJECT_NAME}_devcontainer restart tomcat

# verify remount
docker exec -it tomcat ls -la /usr/local/tomcat/webapps
