# Hashistack

## Docker

The latest steps for installation can be found [here](https://docs.docker.com/engine/install/debian/)  
And follow the post-installation steps [here](https://docs.docker.com/engine/install/linux-postinstall/)
to allow you to manage docker as a non-root user

### Install

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker
sudo usermod -aG docker $USER
```

## Git

### Install

```bash
sudo apt -y install git
```

## Terraform

The latest steps for installation can be found [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Install

Find the URL for the recent arm64 version of Terrafrom from
[Terraform Releases](https://releases.hashicorp.com/terraform)

```bash
cd /tmp
mkdir terraform
cd terraform
wget https://releases.hashicorp.com/terraform/1.8.4/terraform_1.8.4_linux_arm64.zip
unzip terraform_1.8.4_linux_arm64.zip
sudo mv /tmp/terraform/terraform /usr/local/bin
```

### Verify Installation

```bash
cd ~
terraform -help
```

### Enable tab completion

```bash
touch ~/.bashrc
terraform -install-autocomplete
```

## Consul

## Nomad

## Vault

## Packer

The latest steps for installation can be found [here](https://developer.hashicorp.com/packer/install)

### Install

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer
```

## Reference Links

https://docs.docker.com/engine/install/ubuntu/
