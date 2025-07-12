# Docker Source Vault

A Docker container to self-host all of your own precious repositories in a safe
place without requiring bloated web applications such as Gitea or GitLab.

## Setup

In order to setup this container you'll need to create a couple of auxiliary
files to get everything up and running. The first file to be created should be
a `docker-compose.yml` to automate the deployment and management of the
container. Here's an example of how it should look like:

```yaml
---
services:
  servers:
    build: .
    restart: unless-stopped
    ports:
      - '2222:22'
      - '8080:80'
    hostname: vault
    volumes:
      - ./git:/var/git
      - ./ssh/authorized_keys:/etc/ssh/authorized_keys
      - ./logs:/logs
```

The second file that is required for this container to run properly is the one
where you define all the users that will be created and will have access to your
repositories via SSH. The file should be named `credentials.sh` and should have
its contents more or less like this:

```bash
#!/bin/sh

# Only run this script if we are inside the vault container and prevent
# accidents on the host system.
if [[ -z "$SOURCE_VAULT_CONTAINER" ]]; then
	echo "Not running inside the source vault container."
	exit 1
fi

# Change root password.
echo 'root:changeme' | chpasswd

# Add regular users.
/sbin/useradd -m -G sudo,users,dialout -s /bin/bash 'username'
echo 'username:changeme' | chpasswd
```

Any changes to `credentials.sh` **requires a rebuild of the container image**,
since it only gets called during the container's build process.

The last step in the setup process is the creation of the SSH keys. This can be
done by executing the following commands:

```bash
mkdir ssh
cd ssh
touch authorized_keys
ssh-keygen -t rsa -f ./ssh_host_rsa_key -C 'source-vault'
ssh-keygen -t ed25519 -f ./ssh_host_ed25519_key -C 'source-vault'
ssh-keygen -t ecdsa -f ./ssh_host_ecdsa_key -C 'source-vault'
```

Now you can build and run the container image with the following commands:

```bash
docker compose build
docker compose up -d
```

### Network Interfaces

Given the fact that your Docker host most likely already exposes an `sshd` on
port 22, and that you don't want to have to specify a non-standard port when
using Git, it's advisable that you create a virtual NIC and assign it to this
container.

## License

This library is free software; you may redistribute and/or modify it under the
terms of the [Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/2.0/).
