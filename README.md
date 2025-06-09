# Servlet DevContainer

A template project for setting up a Servlet development environment using DevContainer.

## Overview

Instead of installing the development environment directly on your local Windows machine, this project sets up a containerized development environment.  
VSCode is installed on the Windows side, while development is done inside containers.

Using Docker for your development environment offers several advantages:

- No need to install Java for each project
- No need to install build tools like Maven
- Updating the environment is relatively simple  
  (Just update the image or Dockerfile)
- Once someone creates the project with devcontainer settings, others can reuse it easily

This project is composed of the following containers:

- **javadev**  
  Java build environment. Includes Java and Maven.
- **mariadb**  
  Uses MariaDB as the database.
- **tomcat**  
  Tomcat container.

The workflow is as follows:  
Build the `.war` file inside the `javadev` container,  
mount the generated `.war` file into the `tomcat` container,  
and the application connects to the database.

You can also connect to the Tomcat debug port from VSCode and perform interactive debugging.

---

## Environment

Tested and built in the following environment:

- Windows 11
- VSCode
- WSL2 (Ubuntu)
- Docker / docker-compose  
  Docker is installed via `apt` (not using Docker Desktop)

### VSCode Extentions

Please add the following VSCode extensions:

- **Extension Pack for Java**  
  This pack includes:

  - Language Support for Java(TM) by Red Hat
  - Debugger for Java
  - Test Runner for Java
  - Maven for Java
  - Project Manager for Java
  - IntelliCode

- **Remote Development**  
  This pack includes:

  - Remote - SSH
  - Remote - Tunnels
  - Dev Containers
  - WSL

---

## Limitations

The project directory **must reside on the WSL (Ubuntu) side**.  
If the directory is on the Windows side and mounted in WSL (e.g., accessed via `/mnt/c/...`), you'll encounter errors when trying to use DevContainer (i.e., "Reopen in Container" won't work correctly).

---

## Steps

### Open the Project

1. Launch WSL2 (Ubuntu).
2. Navigate to the project directory:

```sh
cd project-root
```

3. Open VSCode from the WSL side:

```sh
code .
```

### Configuration Changes

For detailed specifications, please refer to the official DevContainer and Docker documentation.

#### `.devcontainer`

DevContainer-related settings are stored in the `.devcontainer` directory.  
Edit the files there as needed.

If you're not changing the project name or port numbers, you likely don't need to modify anything.

- **compose.yml**  
  Docker Compose configuration.  
  You can adjust port settings, but make sure to keep them consistent with scripts like `rebuild.sh`.

- **devcontainer.json**  
  Main DevContainer configuration.  
  Most of the settings should be self-explanatory with a bit of research.  
  The `"mounts"` section sets up DOOD (Docker-outside-of-Docker), allowing the `javadev` container to use Docker via the mounted socket.  
  The Docker CLI is installed in the container via the Dockerfile.

- **Dockerfile**  
  Used to build the `javadev` container.  
  Based on a DevContainer-provided image, and installs build tools like Maven or Gradle and the Docker CLI.

- **.env**  
  Environment variable settings.  
  Sets `PROJECT_NAME`.  
  Variables from this file are usable in `devcontainer.json`.  
  `PROJECT_NAME` should match the `artifactId` in `pom.xml`, as it determines the name of the generated `.war` file.  
  A script uses this variable to identify the `.war` directory for redeployment.

#### Others

- **rebuild.sh**  
  A shell script in the project root.  
  Rebuilds the `.war` file and restarts the Tomcat container.
  While DevContainer provides a rebuild option, it's relatively resource-intensive, so this script only restarts the Tomcat container.  
  If you change `PROJECT_NAME`, make sure to update this script accordingly.

### Run the Project

Once you're done reviewing the config files, it's time to test the build and run process.

### Start Dev Container

To start and connect to the Dev Container:

1. Click `>< WSL:Ubuntu` at the bottom-left corner of VSCode
2. Select `Reopen in Container` from the menu

If there are no issues with your config files, the Dev Container should start and VSCode will connect to it.

### Run `postCreateCommand`

Once the container is successfully created, the `postCreateCommand` defined in `devcontainer.json` will run.

The output will appear in the TERMINAL window. If everything works, you should see:

```sh
Running the postCreateCommand from devcontainer.json...

[6985 ms] Start: Run in container: /bin/sh -c cd /workspaces/servlet-devcontainer && echo 'Dev Container 起動 OK !'
Dev Container 起動 OK !
Done. Press any key to close the terminal.
```

Go ahead and "press any key".
You should now see a terminal like:

```
root ➜ /workspaces/servlet-devcontainer $
```

This means you’re inside the `javadev` container.

### Generate `.war` File

The `javadev` container is ready to build with Maven.

First, check what files are present:

```sh
ls -la
```

You should see your project files, since the WSL-side project is mounted into the container.

Then, build the project:

```sh
mvn clean package
```

If the project has no issues, the build will succeed and a `.war` file will be generated under the `target` directory.

### Mount the `.war` File

In `compose.yml`, the `target` directory is mounted into the Tomcat container, so the `.war` file should appear in Tomcat’s `webapps` directory.

To confirm:

```sh
docker exec -it tomcat ls -la /usr/local/tomcat/webapps
```

However, you may see:

```sh
docker exec -it tomcat ls -la /usr/local/tomcat/webapps
total 0
```

That’s because the `.war` file was generated **after** the Tomcat container started, so it hasn’t picked it up yet.

To apply the new `.war`, restart the Tomcat container.

Rather than restarting it manually (and deleting deployed app directories), you can use the `rebuild.sh` script to handle all of this.

Although the above `docker exec ...` is shown to demonstrate the issue, normally you'd just run:

```sh
chmod +x rebuild.sh
./rebuild.sh
```

#### `tasks.json`

The `rebuild.sh` script is configured in `tasks.json`, so you can also trigger it like this:

1. In VSCode: `Terminal` > `Run Task...`
2. Select `Rebuild WAR` (label name)

Alternatively, since it’s grouped under `"build"`, you can:

1. Press `Ctrl + Shift + B`
2. Select `Rebuild WAR` from the task list

### Verify Operation

Let’s confirm it’s working. When deployed, the `.war` filename becomes the context path.

If unchanged, the generated file will be `servlet-devcontainer-0.1.war`, so your base URL will be:

[http://localhost:8080/servlet-devcontainer-0.1/](http://localhost:8080/servlet-devcontainer-0.1/)

To access the sample servlet (`HelloServlet.java`):

[http://localhost:8080/servlet-devcontainer-0.1/hello](http://localhost:8080/servlet-devcontainer-0.1/hello)

Check that it's working properly.

### Debugging

Once the app is running, go to `Run` > `Start Debugging` in the VSCode menu.

Set a breakpoint and confirm that you can hit it.

---

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

© 2025 mosaos. All rights reserved.
