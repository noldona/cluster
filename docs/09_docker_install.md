# Install Docker

As we will be using Docker containers for running our various jobs inside
of Nomad, we need to install Docker.

> [!NOTE]  
> **_Ansible Script:_** [09_docker_install.yaml](../09_docker_install.yaml)

#### Most noticable / important variables

| Variable | Default value | Description                    |
| -------- | ------------- | ------------------------------ |
| release  | `noble`       | The name of the Ubuntu release |

#### Variable Files

-   vars/general/main.yaml

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

> [!IMPORTANT]  
> You will need to run each of these steps on each of the Hashistack
> nodes unless otherwise mentioned.

## Step 1: Add the Docker GPG key

First, we need to install the official Docker GPG key.

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

## Step 2: Add the Docker repository to Apt sources

Next, we need to add the Docker repository to the Apt sources, so that
we can install the software.

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

## Step 3: Install Docker

Finally, we can install Docker and related packages.

```bash
sudo apt-get install docker-ce docker-ce-cli docker-ce-rootless-extras containerd.io docker-buildx-plugin docker-compose-plugin python3-docker
```

## Next Step

[Install Hashistack](10_hashistack_install.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
-   https://docs.docker.com/engine/install/ubuntu/
-   https://docs.docker.com/engine/security/rootless/
