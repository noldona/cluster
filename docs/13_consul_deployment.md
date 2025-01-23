# Deploy Consul

We are now going to setup Consul. After these steps, you should be able
to reach the Consul by connecting to the VPN we setup in [Setup OpenVPN](06_setup_openvpn.md)
and going to `http://homelab.consul:8500` from your local machine.

> [!NOTE]  
> **_Ansible Script:_** [13_consul_deployment.yaml](../13_consul_deployment.yaml)

#### Most noticable / important variables

| Variable                           | Default value | Description                                 |
| ---------------------------------- | ------------- | ------------------------------------------- |
| hashicorp_datacenter_name          | `homelab`     | The name for our datacenter                 |
| consul_tls_ca_certificate_days     | `3650`        | How long the CA certificate is good for     |
| consul_tls_server_certificate_days | `1827`        | How long the server certificate is good for |
| consul_tls_client_certiticate_days | `1827`        | How long the client certificate is good for |

#### Variable Files

-   vars/general/hashi_nodes.yaml
-   vars/hashicorp/main.yaml
-   vars/hashicorp/consul.yaml

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

> [!IMPORTANT]  
> You will need to run each of these steps on each of the Hashistack
> nodes unless otherwise mentioned.

## Step 1: Create required directories

First, we need to create some directories which will be needed for our
Consul set. These directories are `/etc/consul.d`, `/opt/consul`, and
`/var/log/consul`. Run the following to create them and set the correct
permissions for these directories.

```bash
# Ensure data directory is present
sudo mkdir -p /opt/consu
sudo chown consul:consul /opt/consul
sudo chmod 0755 /opt/consul

# Ensure etc directory is present
sudo mkdir -p /etc/consul.d
sudo chown consul:consul /etc/consul.d
sudo chmod 0755 /etc/consul.d

# Ensure log directory is present
sudo mkdir -p /var/log/consul
sudo chown consul:consul /var/log/consul
sudo chmod 0755 /var/log/consul
```

## Step 2: Setup encryption

One of the benefits of Consul is it allows encrypted communication
between the different nodes. To do this, we need to setup some key pairs.

### Step 2.1: Create CA Certificate

To setup these key pairs, we need to create a CA key and certificate
using Consul. So on server1, run the following.

```bash
cd /etc/consul.d
sudo consul tls ca create -days 3650
```

This should output the following showing that it create a key and
certificate file in the current directory.

```
==> Saved consul-agent-ca.pem
==> Saved consul-agent-ca-key.pem
```

### Step 2.2: Copy these files to the other nodes

We need to copy these files over to the other nodes so all the Consul
instance use the same CA files. As we have not setup direct SSH connection
between the different nodes, we will have to pass these through the head
node. On the head node, run the following to copy the files to each of the
Hashistack nodes.

```bash
# Copy the files to the head node
scp server1:/etc/consul.d/consul-agent-ca.pem /tmp
scp server1:/etc/consul.d/consul-agent-ca-key.pem /tmp

# Copy the files to the Hashistack nodes
scp /tmp/consul-agent-ca.pem server2:/tmp
scp /tmp/consul-agent-ca-key.pem server2:/tmp
scp /tmp/consul-agent-ca.pem server3:/tmp
scp /tmp/consul-agent-ca-key.pem server3:/tmp
scp /tmp/consul-agent-ca.pem client1:/tmp
scp /tmp/consul-agent-ca-key.pem client1:/tmp
scp /tmp/consul-agent-ca.pem client2:/tmp
scp /tmp/consul-agent-ca-key.pem client2:/tmp
scp /tmp/consul-agent-ca.pem client3:/tmp
scp /tmp/consul-agent-ca-key.pem client3:/tmp
scp /tmp/consul-agent-ca.pem client4:/tmp
scp /tmp/consul-agent-ca-key.pem client4:/tmp
scp /tmp/consul-agent-ca.pem client5:/tmp
scp /tmp/consul-agent-ca-key.pem client5:/tmp
scp /tmp/consul-agent-ca.pem client6:/tmp
scp /tmp/consul-agent-ca-key.pem client6:/tmp
scp /tmp/consul-agent-ca.pem client7:/tmp
scp /tmp/consul-agent-ca-key.pem client7:/tmp
scp /tmp/consul-agent-ca.pem client8:/tmp
scp /tmp/consul-agent-ca-key.pem client8:/tmp
```

On each of the Hashistack nodes except server1, run the following to
copy the files to the correct directory and set their permissions
appropriately.

```bash
sudo cp /tmp/consul-agent-ca.pem /etc/consul.d
sudo chown consul:consul /etc/consul.d/consul-agent-ca.pem
sudo chmod 0644 /etc/consul.d/consul-agent-ca.pem
sudo cp /tmp/consul-agent-ca-key.pem /etc/consul.d
sudo chown consul:consul /etc/consul.d/consul-agent-ca-key.pem
sudo chmod 060 /etc/consul.d/consul-agent-ca-key.pem
```

### Step 2.3: Create the server key pairs

Next, we need to create key pairs for each of the servers. Run the following
to create them on the server nodes (server1, server2, and server3).

```bash
cd /etc/consul.d
sudo consul tls cert create -server -dc {{ hashicorp_datacenter_name }} -days 1827
```

This should create a `{{ hashicorp_datacenter_name }}-server-consul-0.pem` file.

### Step 2.4: Create the client key pairs

Similarly, we need to create key pairs for each of the clients. Run the
following to create them on each of the client nodes.

```bash
cd /etc/consul.d
sudo consul tls cert create -client -dc {{ hashicorp_datacenter_name }} -days 1827
```

This should create a `{{ hashicorp_datacenter_name }}-client-consul-0.pem` file.

### Step 2.5: Create an encryption key

This only needs to be run once. It can be run on any of the Hashistack
nodes.

```bash
sudo consul keygen
```

Make note of the encryption key that is outputted from the command.

## Next Step

[Deploy Vault](14_vault_deployment.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo

```

```

```

```
