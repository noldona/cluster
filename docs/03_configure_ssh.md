# Configure SSH

Due to the nature of the network structure, you can only access the
Hashistack nodes via the head node. While we have already setup the
SSH config on our localhost to proxy through the head node during the
[Initial Setup](01_initial_setup.md#step-1-setup-ssh-config-on-your-local-machine),
it is also useful to be able to SSH from the head node into the various
Hashistack nodes. So, we will be creating an SSH key and adding that to
the authorized keys on the Hashistack nodes.

> [!NOTE]  
> **_Ansible Script:_** [03_configure_ssh.yaml](../03_configure_ssh.yaml)

#### Most noticable / important variables

| Variable         | Default value | Description                                |
| ---------------- | ------------- | ------------------------------------------ |
| username         | `pi`          | The username used on the cluster           |
| ssh_key_filename | `id_ed25519`  | The filename for the keypair being created |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/ssh.yaml

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

## Step 1: Generate the SSH Key

Generate the SSH key on the head node

```bash
ssh-keygen -t ed25519
```

## Step 2: Setup the SSH Config

```bash
cat >> ~/.ssh/config << EOF
Host {{ server1.hostname }}
	HostName {{ server1.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ server2.hostname }}
	HostName {{ server2.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ server3.hostname }}
	HostName {{ server3.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ client1.hostname }}
	HostName {{ client1.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ client2.hostname }}
	HostName {{ client2.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ client3.hostname }}
	HostName {{ client3.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ client4.hostname }}
	HostName {{ client4.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ client5.hostname }}
	HostName {{ client5.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ client6.hostname }}
	HostName {{ client6.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ client7.hostname }}
	HostName {{ client7.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ client8.hostname }}
	HostName {{ client8.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
EOF
```

## Step 3: Add key to the Hashistack nodes

Finally, we need to add the key to the authorized keys on the Hashistack
nodes. We will take advantage of the network booting nature of the cluster
to add these values easily.

On the head node, run the following command for each of the Hashistack nodes.

```bash
cat ~/.ssh/id_rsa.pub | tee -a /nfs/{{ item.hostname }}/home/{{ username }}/.ssh/authorized_keys > /dev/null
```

## Next Step

[Setup the Firewall](04_setup_firewall.md)

## Reference Links
