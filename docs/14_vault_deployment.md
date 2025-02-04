# Deploy Vault

We are now going to install Consul, Vault, and Nomad on the Hashistack
nodes. The are the main components that will make the Hashistack work.

> [!NOTE]  
> **_Ansible Script:_** [14_vault_deployment.yaml](../14_vault_deployment.yaml)

#### Most noticable / important variables

| Variable                     | Default value           | Description                                    |
| ---------------------------- | ----------------------- | ---------------------------------------------- |
| hashicorp_datacenter_name    | `homelab`               | The name for our datacenter                    |
| vault_admin_username         | `pi`                    | The username for the Vault admin               |
| vault_ssl_server_common_name | `vault.homelab.cluster` | The Common Name for the Vault cluster key      |
| ssl_ca_passphrase            | ``                      | This is the password for your CA Authority key |

#### Variable Files

-   vars/general/hashi_nodes.yaml
-   vars/hashicorp/main.yaml
-   vars/hashicorp/consul.yaml
-   vars/hashicorp/vault.yaml
-   vars/hashicorp/ssl.yaml
-   vars/general/ssl.yaml
-   vars/general/secrets.yaml

> [!IMPORTANT]  
> The ansible script expects a `vars/general/secrets.yaml` file to exist.
> As this file will contain things like passwords and should not be commited
> to your repository, you will need to create this file and add the
> `ssl_ca_passphrase` variable to it. The file is listed in the .gitignore
> to prevent it from being added to the repository.

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

> [!IMPORTANT]  
> You will need to run each of these steps on each of the Hashistack
> nodes unless otherwise mentioned.

## Step 1: Create required directories

First, we need to create some directories which will be needed for our
Vault installs.

### Step 1.1: Create etc and log directories

These directories are `/etc/vault.d` and `/var/log/vault`. Run the
following to create them and set the correct permissions for these
directories.

```bash
# Ensure etc directory is present
sudo mkdir -p /etc/vault.d
sudo chown vault:vault /etc/vault.d
sudo chmod 0755 /etc/vault.d

# Ensure log directory is present
sudo mkdir -p /var/log/vault
sudo chown vault:vault /var/log/vault
sudo chmod 0755 /var/log/vault
```

### Step 1.2: Create the data and TLS directories

We also need to create the `/opt/vault/data` and `/opt/vault/tls` directories
on the server nodes only. Create these by running the following.

```bash
# Ensure data directory is present
sudo mkdir -p /opt/vault/data
sudo chown vault:vault /opt/vault/data
sudo chmod 0755 /opt/vault/data

# Ensurue TLS directory is present
sudo mkdir -p /opt/vault/tls
```

## Step 2: Ensure Vault is excluded from the unattended upgrades

We want to prevent Vault from being upgraded automatically to prevent
any issues that might arise from version differences.

Open `/usr/share/unattended-upgrades/50unattended-upgrades` and add
`vault` to the file after the `Unattended-Upgrade::Pacage-Blacklist` line.

## Step 3: Create PKI

Our manual steps will depart from the Ansible scripts slightly here as
we will be using EasyRSA for key creating instead of OpenSSL directly
like the Ansible script does. EasyRSA is a wrapper around OpenSSL that
makes it easier to generate keys and certificates.

We are going to assume that you already have EasyRSA install from previous
steps. Run the following steps on the server nodes.

### Step 3.1: Create the Vault server private key and certificate signing request (CSR)

First, we will generate the private key and CSR for the vault servers.

```bash
cd ~/easy-rsa
./easyrsa --batch --req-cn="vault.homelab.cluster" --subject-alt-name="DNS:vault.homelab.cluster,DNS:vault.service.consul,DNS:active.vault.service.consul,DNS:standby.vault.service.consul,DNS:*.vault.service.consul,DNS:vault.service.homelab.consul,DNS:active.vault.service.homelab.consul,DNS:standby.vault.service.homelab.consul,DNS:*.vault.service.homelab.consul,IP:127.0.0.1,IP:10.0.0.2,IP:10.0.0.3,IP:10.0.0.4" gen-req vault nopass
```

### Step 3.2: Copy the CSR to the head node

As our CA server is on the head node, we need to copy the CSR to the head
node to be able to sign it. On the head node, run the following to copy
the CSR over.

```bash
scp server1:/home/pi/easy-rsa/pki/reqs/vault.req /tmp/vault-server1.req
scp server2:/home/pi/easy-rsa/pki/reqs/vault.req /tmp/vault-server2.req
scp server3:/home/pi/easy-rsa/pki/reqs/vault.req /tmp/vault-server3.req
```

### Step 3.3: Sign the CSR using our CA key

The certificate signing requests (CSRs) need to be siggned by our CA key.
To do this we need to import them into EasyRSA on the head node before we
can sign them.

On the head node, run the following.

```bash
cd ~/easy-rsa
./easyrsa import-req /tmp/vault-server1.req server
./easyrsa sign-req server vault-server1
./easyrsa import-req /tmp/vault-server2.req server
./easyrsa sign-req server vault-server2
./easyrsa import-req /tmp/vault-server3.req server
./easyrsa sign-req server vault-server3
```

When prompted to verify that the reqeust ccomes from a trusted source,
type `yes` and press `Enter`.

You will be prompted to enter the passphrase you used to create the CA
key.

This will import the CSRs and sign them. It will generate the certificates
at `~/easy-rsa/pki/issued/vault-server1.crt`, `~/easy-rsa/pki/issued/vault-server2.crt`, and `~/easy-rsa/pki/issued/vault-server3.crt`.

### Step 3.4: Copy the signed certificates back to the servers

We need to copy these signed certificates back to the servers for use
later. On the head node, run the following to copy thhe certificates back
to the servers.

```bash
scp ~/easy-rsa/pki/issued/vault-server1.crt server1:/tmp/vault.crt
scp ~/easy-rsa/pki/issued/vault-server2.crt server2:/tmp/vault.crt
scp ~/easy-rsa/pki/issued/vault-server3.crt server3:/tmp/vault.crt
```

Then on each of the server nodes, move the certificate files from `/tmp`
to our `~/easy-rsa/pki/issued` directories.

```bash
mv /tmp/vault.crt ~/easy-rsa/pki/issued/
```

## Step 4: Copy the CA certificiate into the Vault servers

We also need a copy of the CA certificate available for Vault to access.
As we have already copied this to each of the Hashistack nodes previously,
we will just pull it from this location to make life easier.

```bash
sudo cp /usr/local-share/ca-certificates/ca.crt /opt/vault/tls/vault-ca.crt
sudo chown root:root /opt/vault/tls/vault-ca.crt
sudo chmod 0644 /opt/vault/tls/vault-ca.crt
```

## Step 5: Vault Configuration

We are now going to setup the configuration for Vault. We only need to
run these configurations on the server nodes as Vault will only be started
for the servers.

First, we need to make sure the config file exists.

```bash
cd /etc/vault.d
sudo cat << EOF > vault.hcl
# Enable UI for demo purposes
ui = true

# Cluster addresses
cluster_addr = "https://$(ifconfig | grep -Eo 'inet (addr:)?10\.([0-9]*\.){2}[0-9]*' | grep -Eo '10\.([0-9]*\.){2}[0-9]*'):8201"
api_addr     = "https://$(ifconfig | grep -Eo 'inet (addr:)?10\.([0-9]*\.){2}[0-9]*' | grep -Eo '10\.([0-9]*\.){2}[0-9]*'):8200"

# Consul storage backend
storage "consul" {
  address = "http://localhost:8500"
  path    = "vault/"
  # token   = "<VAULT_SERVICE_TOKEN_WILL_BE_FILLED_LATER>"
}

# TLS Listener
listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_cert_file      = "/opt/vault/tls/vault.crt"
  tls_key_file       = "/opt/vault/tls/vault.key"
  tls_client_ca_file = "/opt/vault/tls/vault-ca.crt"
}
EOF
sudo chown vault:vault /etc/vault.d/vault.hcl
sudo chmod 0644 /etc/vault.d/vault.hcl
```

Next, we need to make sure the service file exists.

```bash
sudo cat << EOF > /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets" Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target ConditionFileNotEmpty=/etc/vault.d/vault.hcl StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF
```

And then we want to restart Vault to ensure it picks up the new config.

```bash
sudo service vault restart
```

## Step 6: ACL Setup

We are going to setup the Access Control List (ACL) for Vault. This
will give us finer grain control of the access to Vault so that we can
limit what secrets different apps and users can access. This requires
having ACL setup in Consul to work since we will be using Consul for our
secrets backend.

### Step 6.1: Get the Consul bootstrap token

To start, we need to retrieved the token we created for Consul in the
[Previous Step](13_consul_deployment.md#step-5-bootstrap-the-acl). We
stored this value in the `management.consul.token` file in the token
directory on our localhost. Grab the SecretID value from this file.
We will refer to thhis value as the `{{ consul_acl_bootstrap_secret_id }}`
variable. If you see this variale in further steps, replace it with this
value. We will also export thhis value as an environment variable so that
we can use it to identify us for further Consul commands.

We only need to run these commands on server1.

```bash
sudo export CONSUL_HTTP_TOKEN={{ consul_acl_bootstrap_secret_id }}
```

### Step 6.2: Create the Vault ACL policy

We also need to create a file containing the policy we will setup for
the Vault token.

```bash
sudo cat << EOF > /opt/vault/data/consul-vault-service-policy.hcl
service "vault" { policy = "write" }
key_prefix "vault/" { policy = "write" }
agent_prefix "" { policy = "read" }
session_prefix "" { policy = "write" }
EOF
```

Then we can create the policy inside of Consul

```bash
cd /opt/vauult/data
sudo consul acl policy create -name vault-service -rules @consul-vault-service-policy.hcl
```

### Step 6.3: Create and store the token

Now that we have the policy create, we will create a token that uses this
policy.

```bash
sudo consul acl token create -description 'Vault Service Token' -policy-name vault-service
```

Copy the output and store it on your localhost in your token directory
in a file named `vault-service.consul.token` for safe keeping. We will need
this token for later steps. Specifically, we will need the SecretID value
from this output. We will refer to this value as the
`{{ vault_acl_bootstrap_secret_id }}` variable. If you see this variable
in further steps, replace it with this value.

### Step 6.4: Set the token in the config file

Now that we have the token created, we need to update the Vault config
to use this token and then restart Vault to pickup the config changes.
This needs to be run on all of the server nodes.

```bash
sudo sed -i 's/# token   = "<VAULT_SERVICE_TOKEN_WILL_BE_FILLED_LATER>"/token   ="{{ vault_acl_bootstrap_secret_id }}"' /etc/vault.d/vault.hcl
sudo service vault restart
```

## Step 7: Unseal Vault

We need to initialize and then unseal Vault using the keys generated
during the initialization process to make it usable. These commands,
except for the initialize step, need to be run on all of the server nodes.

### Step 7.1: Setup environment

First we need to setup some environment variables which will be used by
the Vault commands.

```bash
sudo export VAULT_ADDR=https://127.0.0.1:8200
sudo export VAULT_CACERT=/opt/vault/tls/vault-ca.crt
sudo export VAULT_SKIP_VERIFY=true
```

### Step 7.2: Initialize Vault

With the environment variables setup, we will now initialize Vault. This
command only needs to be run on server1.

```bash
sudo vault operator init
```

Copy the output and store it on your localhost in your token directory
in a file named `vault.master.keys` for safe keeping. We will need
this token for later steps.

### Step 7.3: Check Vault status

First, we will want to check the status of Vault and verify that it is
sealed.

```bash
sudo vault status
```

Check the output and look for the line that says `Sealed` and confirm it
says `true`.

If so, we will need to unseal Vault. Choose any 3 of the `Unseal Keys`
from the `vault.master.keys` file you saved earlier and run the following
command 3 times each with one of the keys in place of the
`{{ unseal_key }}` variable.

```bash
sudo vault operator unseal {{ unseal_key }}
```

After you have run the command 3 times with different keys, Vault should
be unsealed. We will run the following command to config that it has been.

```bash
sudo vault status
```

Checkk the output and lookk for the line that says `Sealed` and config it
sayys `false`.

## Step 8: Create content

Now that Vault is unsealed, we can start creating content in it. We will
create an admin user that can login with a password and is limited by
an ACL policy. And then we will create a secrets engine. We will run these
commands on server1.

### Step 8.1: Retrieved Initial Root Token

To be able to create any of this, we must be root to start with. To do
this, we will need to get the `Initial Root Token` value from the
`vault.master.keys` in the token directory on our localhost. We will
refer to this as the `{{ vault_initial_root_token }}` variable. If you
see this variable in further steps, replace it with this value. We will
also export this value as an environment variable so that we can use it
to identify us for further Vault commands.

```bash
sudo export VAULT_TOKEN={{ vault_initial_root_token }}
```

### Step 8.2: Create admin policy

We need to create a file to define the policy for the admin user we will
be creating.

```bash
sudo cat << EOF > /opt/vault/data/admin-policy.hcl
path "*" {
	capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
```

Then we can define the policy in Vault.

```bash
sudo vault policy write admin-policy /opt/vault/data/admin-policy.hcl
```

### Step 8.3: Enable userpass auth engine

Since we are going to allow the admin user to login with a username and
password, we need to enable the userpass auth engine which is disabled
by default.

```bash
sudo vault auth enable userpass
```

### Step 8.4: Create admin user

We can now create our admin user.

#### Step 8.4.1: Create a password

We will need a password to use for the admin user. You are free to
create your own password if you would like using whatever method you
want. If you do not have a preferred method and want something secure,
you can create a password on the command line using the following.

```bash
admin_password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)
```

If you didn't use the previous commmand, you can either set the
`admin_password` variable manually using the following or replace
`$admin_password` in the following commands with your password.

```bash
admin_password={{ admin_password }}
```

#### Step 8.4.2: Create the admin user

Now, with the password create, we can create our user. This will create
a user under the userpass auth engine. It will contain the username and
password that our admin account will log in with it.

```bash
sudo vault write auth/userpass/users/pi password=$admin_password
```

#### Step 8.4.3: Retrieved the admin mount accessor

We then need to get the mount accessor for the created user.

```bash
sudo vault auth list -format=json | jq -r '["userpass/"].accessor'
```

The output of this will be referred to as the `{{ mount_accessor }}`
variable. If you see this variable in further steps, replace it with this
value.

#### Step 8.4.4: Create the admin user entity

We need to create the actual account entity that will be our admin account.
This is the thing that will be the record for the actual account.

```bash
sudo vault write -format=json identity/entity name=pi-entity | jq -r ".data.id"
```

The output of this is the id of the entity we just created. We will
refer to this as the `{{ entity_id }}` variable. If you see this variable
in further steps, replace it with this value.

#### Step 8.4.5: Create the admin user entity alias

We will now create an alias that will tie the entity we just created
with the record in the userpass auth engine we created earlier. This will
allow the admin account to log in using the username and password setup
earlier.

```bash
sudo vault write identity/entity-alias name=pi cannonical_id={{ entity_id }} mount_accessor={{ mount_accessor }}
```

#### Step 8.4.6: Create admin group

We will now create a group for our admin users and apply the admin policy
to that group so that any user in the group will have those permissions.

```bash
sudo vault write identity/group name=admin-group policies=admin-policy member_entity_ids={{ entity_id }}
```

### Step 8.5: Create the KV secret engine

We can now create the KV secret engine where we will store our
secrets.

```bash
sudo vault secrets enable -path=secret -version=2 kv
```

### Step 8.6: Login as the admin user

Now that the admin user is all setup, we will login as the admin user.

```bash
sudo vault login -method=userpass username=pi password=$admin_password -format=json | jq -r '["auth"].client_token'
```

The output of this is the token for our current login session. We will
refer to this token as the `{{ admin_token }}` variable. If you see this
variable in further steps, replace it with this value. We will also
export this value as an environment variable so that we can use it to
identify us for further Vault commands.

```bash
sudo export VAULT_TOKEN={{ admin_token }}
```

### Step 8.7: Revoke the initial root token

Finally, we want to revoke the initial root token for security reasons.

```bash
sudo vault token revoke {{ vault_initial_root_token }}
```

## Step 9: Setup logging

Next, we want to setup logging for Vault.

First, we want to setup the log rotation. Run this command on all of the
server nodes.

```bash
sudo cat << EOF > /etc/logrotate.d/vault
/var/log/vault/audit.log {
  rotate 7
  daily
  notifempty
  missingok
  compress
  delaycompress
  postrotate
    /usr/bin/systemctl reload vault 2> /dev/null || true
  endscript
  extension log
  dateext
  dateformat %Y-$m-$d.
}
EOF
```

Then, we want to enable the audit log. Run this command only on server1.

```bash
sudo vault audit enable file file_path=/var/log/vault/audit.log
```

## Next Step

[Deploy Nomad](15_nomad_deployment.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
-   https://developer.hashicorp.com/vault/tutorials/get-started
