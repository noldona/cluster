# Deploy Consul

We are now going to setup Consul. After these steps, you should be able
to reach the Consul by connecting to the VPN we setup in [Setup OpenVPN](06_setup_openvpn.md)
and going to `http://homelab.consul:8500` from your local machine.

> [!NOTE]  
> **_Ansible Script:_** [13_consul_deployment.yaml](../13_consul_deployment.yaml)

#### Most noticable / important variables

| Variable                           | Default value    | Description                                         |
| ---------------------------------- | ---------------- | --------------------------------------------------- |
| hashicorp_datacenter_name          | `homelab`        | The name for our datacenter                         |
| consul_tls_ca_certificate_days     | `3650`           | How long the CA certificate is good for             |
| consul_tls_server_certificate_days | `1827`           | How long the server certificate is good for         |
| consul_tls_client_certiticate_days | `1827`           | How long the client certificate is good for         |
| token_directory                    | `~/hashi-tokens` | The localhost location where token files are stored |

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
Consul installs. These directories are `/etc/consul.d`, `/opt/consul`, and
`/var/log/consul`. Run the following to create them and set the correct
permissions for these directories.

```bash
# Ensure data directory is present
sudo mkdir -p /opt/consul
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

## Step 2: Ensure Consul is excluded from the unattended upgrades

We want to prevent Consul from being upgraded automatically to prevent
any issues that might arise from version differences.

Open `/usr/share/unattended-upgrades/50unattended-upgrades` and add
`consul` to the file after the `Unattended-Upgrade::Pacage-Blacklist` line.

## Step 3: Setup encryption

One of the benefits of Consul is it allows encrypted communication
between the different nodes. To do this, we need to setup some key pairs.

### Step 3.1: Create CA Certificate

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

### Step 3.2: Copy these files to the other nodes

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

### Step 3.3: Create the server key pairs

Next, we need to create key pairs for each of the servers. Run the following
to create them on the server nodes (server1, server2, and server3).

```bash
cd /etc/consul.d
sudo consul tls cert create -server -dc homelab -days 1827
```

This should create a `homelab-server-consul-0.pem` file.

### Step 3.4: Create the client key pairs

Similarly, we need to create key pairs for each of the clients. Run the
following to create them on each of the client nodes.

```bash
cd /etc/consul.d
sudo consul tls cert create -client -dc homelab -days 1827
```

This should create a `homelab-client-consul-0.pem` file.

### Step 3.5: Create an encryption key

This only needs to be run once. It can be run on any of the Hashistack
nodes.

```bash
sudo consul keygen
```

Make note of the encryption key that is outputted from the command. We
will need this to configure Consul. You will need to replace any
`{{ consul_encryption_key }}` with the value from this output.

### Step 3.6: Ensure correct file owner / group for all certificates

For each of the `.pem` files in the `/etc/consul.d` directory, we need
to set the correct file owner and groups values.

```bash
sudo chown consul:consul -R /etc/consul.d/*.pem
```

## Step 4: Configure Consul

Now, with the keys generated, we can setup the configuration we need to
be able to start the service.

### Step 4.1: Create config file

First, we will create a config file at `/etc/consul.d/consul.hcl`.

For the server nodes use the following.

```bash
sudo cat << EOF > /etc/consul.d/consul.hcl
datacenter = "homelab"
data_dir = "/opt/consul"
encrypt = "{{ consul_encryption_key }}"
ca_file = "/etc/consul.d/consul-agent-ca.pem"
cert_file = "/etc/consul.d/homelab-server-consul-0.pem"
key_file = "/etc/consul.d/homelab-server-consul-0-key.pem"
verify_incoming = false
verify_outgoing = false
verify_server_hostname = false
retry_join = ["10.0.0.2", "10.0.0.3", "10.0.0.3"]
bind_addr = "$(ifconfig | grep -Eo 'inet (addr:)?10\.([0-9]*\.){2}[0-9]*' | grep -Eo '10\.([0-9]*\.){2}[0-9]*')"
client_addr = "0.0.0.0"
ui = true

log_level = "info"
log_json = false
log_file = "/var/log/consul/"
log_rotate_duration = "86400s"
log_rotate_max_files = 7

acl = {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
  tokens = {
    #agent = "<WILL BE FILLED LATER>"
  }
}

performance {
  raft_multiplier = 1
}

server = true
bootstrap_expect = 3
rejoin_after_leave = true

ports {
  grpc_tls = 8502
}

connect {
  enabled = true
}

EOF
```

For the client nodes, use the following.

```bash
sudo cat << EOF > /etc/consul.d/consul.hcl
datacenter = "homelab"
data_dir = "/opt/consul"
encrypt = "{{ consul_encryption_key }}"
ca_file = "/etc/consul.d/consul-agent-ca.pem"
cert_file = "/etc/consul.d/homelab-client-consul-0.pem"
key_file = "/etc/consul.d/homelab-client-consul-0-key.pem"
verify_incoming = false
verify_outgoing = false
verify_server_hostname = false
retry_join = ["10.0.0.2", "10.0.0.3", "10.0.0.4"]
bind_addr = "$(ifconfig | grep -Eo 'inet (addr:)?10\.([0-9]*\.){2}[0-9]*' | grep -Eo '10\.([0-9]*\.){2}[0-9]*')"
check_update_interval = "0s"

log_level = "info"
log_json = false
log_file = "/var/log/consul/"
log_rotate_duration = "86400s"
log_rotate_max_files = 7

acl = {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
  tokens = {
    #agent = "<WILL BE FILLED LATER>"
  }
}

performance {
  raft_multiplier = 1
}

server = false
rejoin_after_leave = true

ports {
  grpc_tls = 8502
}

connect {
  enabled = true
}

EOF
```

### Step 4.2: Create service file and start the service

We also want to make a service file for starting the Consul service
easier.

```bash
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=exec
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

And now we can start the service.

```bash
sudo service consul start
```

### Step 4.4: Ensure all of the nodes have started

Once you have started the Consul service on all of the nodes, run the
following to verify that all of the nodes are up and communicating. You
can do this by running the following command.

```bash
sudo consul members
```

## Step 5: Bootstrap the ACL

We are going to setup the Access Control List (ACL) for Consul. This
will give us finer grain control of the access to Consul so that we can
limit what features different people and apps can use.

To start, we need to bootstrap the ACL system. Run this on the server1
node.

```bash
sudo consul acl bootstrap
```

Copy the output and store it on your localhost in your token directory
in a file named `management.consul.token` for safe keeping. We will need
this token for later steps. Specifically, we will need the SecretID value
from this output. We will refer to this value as the
`{{ consul_acl_bootstrap_secret_id }}` variable. If you see this variable
in further steps, replace it with this value. We will also export this
value as an environment variable so that we can use it to identify us
for further Consul commands.

```bash
sudo export CONSUL_HTTP_TOKEN={{ consul_acl_bootstrap_secret_id }}
```

## Step 6: Create agent policy and token

We need to create an agent that the Consul nodes will use talking to
each other. Run these steps only on the server1 node.

### Step 6.1: Create agent policy file

We are going to start by creating a file that contains the ACL policy
that our agent will use.

```bash
sudo cat << EOF > /opt/consul/consul-agent-policy.hcl
node_prefix "" {
  policy = "write"
}
service_prefix "" {
  policy = "read"
}
EOF
```

### Step 6.2: Create agent policy

We will now use the file we just created to create the agent policy in
Consul.

```bash
cd /opt/consul
sudo consul acl policy create -name consul-agent -rules @consul-agent-policy.hcl
```

### Step 6.3: Create the agent token

We will now create a token that will use this newly created policy.

```bash
sudo consul acl token create -description 'Token for Consul Agents' -policy-name consul-agent
```

Copy the output and store it on your localhost in your token directory
in a file named `agent.consul.tken` for safe keeping. We will also need
the SecretID value from this output. We will refer to this as the
`{{ consul_agent_token }}` variable. If you see this variable in further
steps, replace it with this value.

### Step 6.4: Update the config

For this step, we need to update the config we made in
[Step 3.1](#step-31-create-config-file) with the agent token. On each of
the Hashistack nodes, run the following.

```bash
sudo sed -i 's/#agent = "<WILL BE FILLED LATER>"/agent = "{{ consul_agent_token }}"/' /etc/consul.dd/consul.hcl
```

We will want to restart Consul so it starts to use the new token as well.
So on all of the Hashistack nodes, run the following.

```bash
sudo service consult restart
```

And now that we have the ACL properly setup, we will want to change the
default policy from allow to deny to make our system more secure.

```bash
sed -i 's/default_policy = "allow"/default_policy = "deny"/' /etc/consul.d/consul.hcl
```

And then we need to restart Consul again to have it pick up the new defaul
policy.

```bash
sudo service consult restart
```

## Step 7: Create DNS policy and token

We also need to setup a DNS token that the Consul agent will use. Run
these steps only on the server1 node.

### Step 7.1: Create DNS policy file

We need to create a file that will contain the ACL policy that will be
used for the DNS policy.

```bash
sudo cat << EOF > /opt/consul/dns-request-policy.hcl
node_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "read"
}
query_prefix "" {
  policy = "read"
}
EOF
```

### Step 7.2: Create DNS policy

We will now use the file we just created to create the DNS policy in Consul.

```bash
cd /opt/consul
sudo consul acl policy create -name dns-requests -rules @dns-request-policy.hcl
```

### Step 7.3: Create the DNS token

We will now create a token that will use this newly create policy.

```bash
sudo consul acl token create -description 'Token for DNS Requests' -policy-name dns-requests
```

Copy the output and store it on your localhost in your token directory
in a file named `dns-requests.consul.token` for sake keeping. We will also
need the SecretID value from this output. We will refer to this as the
`{{ consul_dns_token }}` variable. If you see this variable in futher
steps, replace it with this value.

### Step 7.4: Set the DNS token as the default

We will now use this DNS token we just made as the default for the agents.

```bash
sudo consul acl set-agent-token default '{{ consul_dns_token }}'
```

## Step 8: Install Service Mesh plugin

Finally, we need to install a service mesh plugin. These steps will need
to be run only on the client nodes.

### Step 8.1: Create CNI directory

We need a directory where we will store the plugin file.

```bash
sudo mkdir /opt/cni/bin
```

### Step 8.2: Download the service mesh plugin

Next, we need to download the service mesh plugin into the directory we
just created.

```bash
sudo wget -c https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-arm64-v1.5.1.tgz -O - | sudo tar -xz -C /opt/cni/bin
```

### Step 8.3: Set the kernel tunables

We need to set some settings to allow the containers to used bridged
network access so they can talk with each other.

```bash
sudo cat << EOF > /etc/sysctl.d/20-consul-service-mesh.conf
net.bridge.bridge-nf-call-arptables="1"
net.bridge.bridge-nf-call-ip6tables="1"
net.bridge.bridge-nf-call-iptables="1"
EOF
sudo sysctl -p /etc/sysctl.d/20-consul-service-mesh.conf

```

## Next Step

[Deploy Vault](14_vault_deployment.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
-   https://developer.hashicorp.com/consul/tutorials/get-started-vms/virtual-machine-gs-deploy
-   https://developer.hashicorp.com/consul/tutorials/get-started-vms/virtual-machine-gs-service-discovery
