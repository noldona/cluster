# Hashistack General Setup

After the previous set of steps, we have a working network of computers.
These computers are useful for all sorts of purposes, but most of them
will require additional setup to make them actually useful. For our purposes,
we will be installing the Hashistack onto our nodes.

The Hashistack consists of a group of software made by HashiCorp. Mainly
Consul, Vault, and Nomad. While HashiCorp does make some other very useful
software than can also be used on this stack, we will be focusing on these
three pieces.

Consul is service mesh manager. It allows different services to be able
to communicate with each other easily and safely.

Vault is a secure key/value store perfect for storing tokens, passwords,
and encryption keys needed for various services. This helps prevent
these items from being stored in unsafe places like repos and environment
files. It also makes it easier to regularly update passwords as needed for
security puproses.

Nomad is a container orchastration tool similar to Kubernetes. It allows
for running jobs like various Docker containers.

While we have setup the head node previously, we still need to setup the
Hashistack nodes with some various software to make them usable for our
purposes.

> [!NOTE]  
> **_Ansible Script:_** [08_general_setup.yaml](../08_general_setup.yaml)

#### Most noticable / important variables

| Variable             | Default value                                                                                                                                                                      | Description                                               |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| basic_apt_packages   | `atop, curl, jq, lynx, tree, unattended-upgrades, vim, apt-transport-https, ca-certificates, curl, software-properties-common, python3-pip, virtualenv, python3-setuptools, gnupg` | The basic software needed to be installed                 |
| pip_install_packages | `cryptography, docker, hvac, jmespath, python-nomad`                                                                                                                               | The Python packages that need to be installed             |
| venv                 | `/opt/hashistack-venv`                                                                                                                                                             | The location for the virtual environment for Python       |
| token_directory      | `~/hashi-tokens`                                                                                                                                                                   | The location where the tokens will be stored on localhost |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/hashi_nodes.yaml
-   vars/hashicorp/main.yaml

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

> [!TIP]  
> You can change the `client_config_client_name` variable and rerun this
> script to generate configs for additional clients if needed.

If you want to run the steps manually, continue here.

> [!IMPORTANT]  
> You will need to run each of these steps on each of the Hashistack
> nodes unless otherwise mentioned.

## Step 1: Install the required software

First, we will need to install some basic software that we will need in
the following steps.

```bash
sudo apt install atop curl jq lynx tree unattended-upgrades vim apt-transport-https ca-certificates curl software-properties-common python3-pip virtualenv python3-setuptools gnupg
```

## Step 2: Install the required Python packages

Next, we need to install some required Python packages. However, in the
most recent versions of Linux, they have added a feature to prevent
installing Python packages globally. While this can be bypassed, it is
probably best to just install our packages in a virtual environment as
recommended. We will be creating this virtual environment at
`/opt/hashistack-venv`.

```bash
sudo cd /opt
sudo python3 -m venv hashistack-venv
```

Then, we need to make sure we source the virtual environment that we just
made.

```bash
source /opt/hashistack-venv/bin/activate
```

Finally, we can install the required Python packages.

```bash
pip install cryptography docker hvac jmespath python-nomad
```

## Step 3: Create a token directory

Run this step on your localhost.

As each of the HashiCorp software uses tokens for authentication, we will
need a place to store our tokens for future reference. The easiest place
to do this is to create a directory on your localhost. You could store
these in somewhere like a password manager or other secure encrypted
system, but for the sake of this tutorial, we will just store these as
files in the `~/hashi-tokens` directory on localhost.

We need to create this directory if it doesn't already exist. So, on your
localhost, run the following.

```bash
cd ~
mkdir hashi-tokens
```

## Next Step

[Install Docker](09_docker_install.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
-   https://developer.hashicorp.com/consul
-   https://developer.hashicorp.com/vault
-   https://developer.hashicorp.com/vault
