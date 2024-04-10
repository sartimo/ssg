---
title: A deep dive into the Docker Socket and using Docker from within containers
date: 2022-05-01
author: Michael Zeevi
description: asasasasassa
keywords:
- docker
- containers
- dockerfile
- advanced
- socket
- permissions
- linux
- groups
- jenkins
lang: en-us
---
## Intro and use case
Sometimes one may want to be able to use Docker from **within** another Docker container. This could be useful in various cases such as:

- For test running a containerized application as part of a continuous integration (CI) pipeline - where the CI server (such as _Jenkins_) itself is containerized (this is what we'll setup in the final demonstration).
- To be weaponized as an escape/escalation/pivot method in a security/penetration testing scenario.
- When developing a Docker related utility.
- Or simply when just learning and hacking around. (:

By the end of this article we'll understand how this can be achieved through an example setup that deploys Jenkins in a container and grants it the appropriate permissions to properly run Docker commands from inside!

> _Note: This could be considered a slightly advanced topic, so I assume basic familiarity with Linux permissions, Docker and Docker-compose._


## Docker architecture review
Before getting started, let's refresh ourselves on some of Docker's architecture (you can find <a target="_blank" href="https://docs.docker.com/get-started/overview/#docker-architecture">a nice diagram in the official documentation</a>) and some terminology...

- The _Docker client_ (commonly our `docker` CLI program) is the standard way we interact with Docker's engine. Docker itself runs as a _daemon_ (server) on the _Docker host_ (this host is often the same machine the client runs on, but in theory can be a remote machine too).
- The _Docker host_ exposes the _Docker daemon_'s [REST API](https://docs.docker.com/engine/api/latest/).
- The way the _Docker client_ communicates with the _Docker host_ is via the _Docker socket_.


## The Docker socket
A <a target="_blank" href="https://en.wikipedia.org/wiki/Unix_domain_socket">_Socket_</a>, on a Unix system, acts as an endpoint allowing communication between two processes on a host.

The Docker socket is located in `/var/run/docker.sock`. It enables a Docker client to communicate with the Docker daemon on the Docker host via its API.


### Communicating with the socket
Let's briefly dive one layer deeper and try reach the API server directly. Instead of using the standard CLI and running `docker container ls`, let's use `curl`:

```
curl --unix-socket /var/run/docker.sock http://api/containers/json | jq
```

> _Note: I piped `curl`'s output into `jq` to prettify the output. You can <a target="_blank" href="https://stedolan.github.io/jq/">get jq here</a>._

The Docker daemon should return some JSON similar to this (output truncated):
```
[
  {
    "Id": "3c70064d5b8b85688fef7b0eb4d8573967faa5a349b8c9e94d9a175aaf85a59f",
    "Names": [
      "/pensive_lewin"
    ],
    "Image": "nginx:alpine",
    "ImageID": "sha256:51696c87e77e4ff7a53af9be837f35d4eacdb47b4ca83ba5fd5e4b5101d98502",
    "Command": "/docker-entrypoint.sh nginx -g 'daemon off;'",
    "Created": 1650493607,
    "Ports": [
      {
        "PrivatePort": 80,
        "Type": "tcp"
      }
    ],
    "Labels": {
      ...

```
Here we can see I have an _Nginx Alpine_ container (named _pensive_lewin_) running. Cool!


### The socket's permissions
Running `ls -l /var/run/docker.sock` will allow us to see its permissions, owner and group:
```
srw-rw---- 1 root docker 0 Apr 18 17:17 /var/run/docker.sock
```
We can see that:

- The file type is `s` - it's a Unix socket.
- Its permissions are `rw-` (_read & write_) for the **owner** (_root_)
- Its permissions are `rw-` (_read & write_) for the **group** (_docker_)

A common practice when setting up Docker is to grant our local user permissions to run `docker` without `sudo`, this is achieved by adding our local user to the group _docker_ (`sudo usermod -a -G docker $USER`)... Now that we're familiar with the Docker socket and the group it belongs to, the `usermod` command above should make more sense to you. ;)

We'll revisit these permissions when we discuss hardening of the Docker image we'll create.


## Using Docker from within a container
To use Docker from _within_ a container we need two things:

- A _Docker client_ - such as the standard `docker` CLI - which can be installed normally.
- A way to reach the Docker host... Normally this is done via the _Docker socket_ (as described above). However, since the container is already running _in_ our Docker host we perform a little "hack" in which we mount the Docker socket (via a Docker volume) into our container.


### Proof of concept
Let's put this all together and give it a quick test:

1. Run a container locally, mounted with the Docker socket:
   ```
   docker run --rm -itv /var/run/docker.sock:/var/run/docker.sock --name docker-sock-test debian
   ```
2. Install the Docker client (inside the container):
   ```
   apt update && apt install -y curl
   curl -fsSL https://get.docker.com | sh
   ```
3. Try listing containers using the Docker client (from inside the container):
   ```
   docker ps
   ```
   In the output, our container (named _docker-sock-test_) should be able to see _itself_:
   ```
   CONTAINER ID   IMAGE    COMMAND   CREATED              STATUS              PORTS   NAMES
   09094c778449   debian   "bash"    About a minute ago   Up About a minute           docker-sock-test
   ```


### Visual explanation
This configuration and example described above can be visualized with the following diagram:

![](res/docker-socket/diagram.png)

Legend:

- The _Docker client_ (<span style="color:#d7f">pink</span>) is the `docker` CLI which you should be familiar with. It was installed separately both on the _Localhost_ (<span style="color:#888">grey</span>) and in the _Container_ (<span style="color:#38f">blue</span>).
- The Localhost's _Docker socket_ (<span style="color:#1ab">teal</span>) is mounted into the _container_. This links the container to the _Docker host_ and exposes its _daemon_.
- The _Container_ was created using the _Localhost_'s _Docker client_, via the `docker run...` command (<span style="color:#e55">red</span>).
- The _Container_ can see itself using the _Container_'s _Docker client_ via the `docker ps` command (<span style="color:#d71">orange</span>).


### Building the Docker image
A classic example (from the DevOps field) would be to deploy a Jenkins container which has Docker capabilities. Let's start by creating its `Dockerfile`...

1. We'll base our image on the <a target="_blank" href="https://hub.docker.com/r/jenkins/jenkins">official Jenkins Docker image</a>.
2. This image runs by default with user _jenkins_ - a **non**-root user (and **not** in the _sudo_ group), so in order to install the Docker client we'll escalate to user _root_.
3. We append the user _jenkins_ to the group _docker_, in order for them to have permissions to access the Docker socket (as discussed earlier).
4. This step has a subtle concept to do with Linux permissions, which is worth emphasizing...

   The Docker socket on/from our host is associated with the _docker_ group, however there is no guarantee that this is the same _docker_ group in the image (the group that gets created by _step 2_'s script, and used in _step 3_, above). Linux groups are defined by IDs - so in order to align the group we set in the image with the group that exist on the host, they must both have the **same** group ID!

   The group ID on the host can be looked up with the command `getent group docker` (mine was `998`, yours could differ). We'll pass it to the Docker build via <a target="_blank" href="https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg">an argument</a> and then <a target="_blank" href="https://docs.docker.com/engine/reference/builder/#arg">use that</a> to modify the _docker_ group ID in the image.
5. Finally, to re-harden the image, we'll switch back to the user _jenkins_.

Here is the actual `Dockerfile` (with each of the above steps indicated by a comment):

```
# step 1:
FROM jenkins/jenkins:lts
# step 2:
USER root
RUN  curl -fsSL https://get.docker.com | sh
# step 3:
RUN  usermod -aG docker jenkins
# step 4:
ARG  HOST_DOCKER_GID
RUN  groupmod -g $HOST_DOCKER_GID docker
# step 5:
USER jenkins
```


### Running the container
Due to the nature of the configuration and the dynamic nature of group IDs (differing per each device) I find it simplest to deploy (and build) using Docker-compose.

Here is the `docker-compose.yaml` file:

```
version: "3.6"

services:
  jenkins:
    hostname: jenkins
    build:
      context: .
      args:
        HOST_DOCKER_GID: 998  # check *your* docker group id with: `getent group docker`
    ports:
    - 8080:8080
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - jenkins_home:/var/jenkins_home

volumes:
  jenkins_home:
```

> _Notes:_
>
> - _Make sure to check (and set) **your** host's docker group ID_.
> - _This Docker-compose file additionally:_
>
>   - _Maps Jenkins' port to host port `8080`._
>   - _Creates/uses the named volume `jenkins_home` to persist any Jenkins data._


### Testing
In order to test the setup, one can:

1. Spin up the Jenkins service with:
   ```
   docker-compose up -d --build
   ```
2. Login to a shell in the Jenkins container:
   ```
   docker-compose exec jenkins bash
   ```
3. In the container, let's make sure we:

   - Are **not** running as _root_ - by looking at the CLI prompt, or by running `whoami`.
   - Have access to the Docker socket - by running any Docker command (such as `docker container ls`) with the Docker client.

> _Note: In case of any permission issues, troubleshoot with the `getent group docker` command on both the host and in the container..._


## Conclusion
Hopefully this article managed to clarify a thing or two about the Docker socket and how it fits into Docker's architecture, how its permissions are setup and how it is utilized by a Docker client.

Equipped with said knowledge, we created a Dockerfile for a _Jenkins-with-Docker_ image and saw how to deploy it with the appropriate permissions configuration for _our_ host.
