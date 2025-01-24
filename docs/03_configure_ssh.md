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
Host server1
	HostName 10.0.0.2
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host server2
	HostName 10.0.0.3
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host server3
	HostName 10.0.0.4
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host client1
	HostName 10.0.0.5
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host client2
	HostName 10.0.0.6
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host client3
	HostName 10.0.0.7
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host client4
	HostName 10.0.0.8
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host client5
	HostName 10.0.0.9
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host client6
	HostName 10.0.0.10
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host client7
	HostName 10.0.0.11
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host client8
	HostName 10.0.0.12
	User pi
	Port 22
	IdentityFile ~/.ssh/id_ed25519
EOF
```

## Step 3: Add key to the Hashistack nodes

Finally, we need to add the key to the authorized keys on the Hashistack
nodes. We will take advantage of the network booting nature of the cluster
to add these values easily.

On the head node, run the following command to add the SSH key to each of
the Hashistack nodes.

```bash
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/server1/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/serevr2/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/server3/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/client1/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/client2/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/client3/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/client4/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/client5/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/client6/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/client7/home/pi/.ssh/authorized_keys > /dev/null
cat ~/.ssh/id_ed25519.pub | tee -a /nfs/client8/home/pi/.ssh/authorized_keys > /dev/null
```

## Next Step

[Setup the Firewall](04_setup_firewall.md)

## Reference Links
