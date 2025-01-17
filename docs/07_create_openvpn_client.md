# Create OpenVPN Client

We will now create a client configuration for OpenVPN. This configuration
will be used to setup the OpenVPN client on your localhost.

> [!NOTE]  
> **_Ansible Script:_** [07_create_openvpn_client.yaml](../07_create_openvpn_client.yaml)

#### Most noticable / important variables

| Variable                  | Default value | Description                                    |
| ------------------------- | ------------- | ---------------------------------------------- |
| client_config_client_name | `pi`          | The username to create the OpenVPN config for  |
| ssl_ca_passphrase         | ``            | This is the password for your CA Authority key |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/ssl.yaml
-   vars/general/secrets.yaml
-   vars/general/openvpn.yaml

> [!IMPORTANT]  
> The ansible script expects a `vars/genera/secrets.yaml` file to exist.
> As this file will contain things like passwords and should not be commited
> to your repository, you will need to create this file and add the
> `ssl_ca_passphrase` variable to it. The file is listed in the .gitignore
> to prevent it from being added to the repository.

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

> [!TIP]  
> You can change the `client_config_client_name` variable and rerun this
> script to generate configs for additional clients if needed.

If you want to run the steps manually, continue here.

## Step 1: Create the client config directory

First, we need a directory to store the client config, keys, and certificates
in. We will create the `~/client-configs` directory to serve this purposes.

```bash
mkdir -p ~/client_configs/private
mkdir -p ~/client_configs/certs
mkdir -p ~/client_configs/files
chmod -R 0700 ~/client_configs
```

## Step 2: Create the client key pair

> [!TIP]  
> We will also be using EasyRSA to generate our keys for the OpenVPN
> client. If you have not completed the steps in
> [Setup CA Authority](05_setup_ca_authority.md), do that now before
> continuing with this. It is recommended that if you ran the Ansible
> script for setting up the CA Authority, that you run the Ansible script
> for this as well due to the location of the keys and certificates being
> different between Ansible scripts and the manual steps.

As you have completed setting up the `easy-rsa` directory in the previously,
we will not repeat setting up this folder.

Next, we need to create the key pair that the client will use to connect
to the VPN.

### Step 2.1: Create the private key and certificate signing request (CSR)

To create the private key and certificate signing request for the client
run the following.

```bash
cd ~/easy-rsa
./easyrsa gen-req {{ client_config_client_name }} nopass
```

### Step 2.2: Copy the private key to the client config private directory

The private key, `~/easy-rsa/pki/private/{{ client_config_client_name}}.key`,
needs to be copied over to the client configs private directory.

```bash
sudo cp ~/easy-rsa/pki/private/{{ client_config_client_name }}.key ~/client_configs/private
```

### Step 2.3: Sign the CSR using our CA key

The certificate signing request (CSR) needs to be signed by our CA key.
This can be done using the following command.

```bash
./easyrsa sign-req client {{ client_config_client_name }}
```

You will be prompted for the CA key passphrase. Use the passphrase you
entered when you created the CA key here.

### Step 2.4: Copy the public certificate to the client config certs directory

The previous will create the certificate file, `~/easy-rsa/pki/issued/{{ client_config_client_name }}.crt`.
This file needs to be copied to the client configs certs directory.

```bash
sudo cp ~/easy-rsa/pki/issued/{{ client_config_client_name }}.ct ~/client-configs/certs
```

## Step 3: Create client config creation script

To make our life easier, instead of just creating a single client config,
we will create a script that can be used to create a config for any clients
we might need.

### Step 3.1: Copy the base config

To get started, we need to copy over the sample config to the client configs
directory which we will modify to use as a base config.

```bash
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
```

### Step 3.2: Modify the base connfig

Next, open this file with a text editor of your choice. We will be making
several changes to ths file.

```bash
sudo nano ~/client-configs/base.conf
```

Find the line startingg with `remote` and update the IP address to be
{{ head_node_ip }}. If you chose a different port when you setup OpenVPN,
change this line to match that port number as well.

```
# The hostname/IP and port of the server.
# You can have multiple remote entries
# to load balance between the servers.
remote {{ head_node_ip }} 1194
```

If you changed the protocol, find the line that starts with `proto` and
update it as well.

```
proto udp
```

Next, uncomment the lines with `user` and `group` by removing the `;`
character at the beginning of the lines.

```
# Downgrade privileges after initialization (non-Windows only)
user nobody
group nogroup
```

Comment out the lines that begin with `ca`, `cert`, and `key` by addinng
a `;` to the beginning of the line. We will add the keys to the config
directly with the script we will create in the next step.

```
# SSL/TLS parms.
# See the server config file for more
# description. It's best to use
# a separate .crt/.key file pair
# for each client. A single ca
# file can be used for all clients.
;ca ca.crt
;cert client.crt
;key client.key
```

Similarly, we will add the pre-shared key to the config via the script,
so find the line that reads `tls-auth ta.key 1` and comment it out.

```
# If a tls-auth key is used on the server
# then every client must also have the key.
;tls-auth ta.key 1
```

We need to matc the `cipher` and `auth` settings we set in the OpenVPN
server configs.

```
cipher AES-256-GCM
auth SHA256
```

We need to set the `key-direction` directive to `1` somewhere in the file so that
it will functiion correctly on the client's machine.

```
key-direction 1
```

Finally, we will add some commented out lines. These will handle various
DNS resolution methods that may be sed by Linux based clients.

We will add two similar, but separate sets. The first is for clients that
use the resolvconf utilit to update DNS information instead of using
systemd-resolved.

```
; script-security 2
; up /etc/openvpn/update-resolv-conf
; down /etc/openvpn/update-resolv-conf
```

The second set is ffor clients that do use systemd-resolved for DNS resolution.

```
; script-security 2
; up /etc/openvpn/update-systemd-resolved
; down /etc/openvpn/update-systemd-resolved
; down-pre
; dhcp-option DOMAIN-ROUTE .
```

Save and close this file.

In Step 5, under the Linux client setup, we wll determine which DNS resolution
the client uses and uncomment the correct one for them.

### Step 3.3: Create client config creation script

Next, we will create a script that will compile the base config with the
key, certificate,, and encryption files and place them in the generated
config file in the `~/client-configs/files` directory.

Open a new file called `make_config.sh` within the `~/client-configs` directory.

```bash
nano ~/client-configs/make_config.sh
```

Add the following contents to the file, then save and close the file.

```
#!/bin/bash

# First argument: Client identifier

KEY_DIR=~/client-configs/private
CERT_DIR=~/client-configs/certs
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/base.conf
CA_KEY_DIR=~/easy-rsa/pki/
TA_KEY_DIR=~/easy-rsa/

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${CA_KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${CERT_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-crypt>') \
    ${TA_KEY_DIR}/ta.key \
    <(echo -e '</tls-crypt>') \
    > ${OUTPUT_DIR}/${1}.ovpn
```

We need to make this file executable so we can run it. Do this my using
the following command.

```bash
chmod 700 ~/client-configs/make_config.sh
```

This script will generate a new config for the specified client by making
a copy of the `base.config` file we just created, and add the contents of
the required keys and certificates to it before storing it as a config
for the client. The benefit of adding the keys and certificates to the
config is that it is all in one place instead of needing to manage the
keys and certificates seperately.

This script can be run to generate config files for any new clients you
might need in the future. You will need to generate keys and certificates
for these new clients before ou can run the script to create the config
for them though.

## Step 4: Generate the config for the client

Now, we can create the client config. Run the script we just created.

```bash
cd ~/client-configs
./make_config.sh {{ client_config_client_name }}
```

This will create a file named `{{ client_config_client_name }}.ovpn` in
the `~/client-configs/files` directory. Transfer thiis file to the client
machine, such as your localhost.

On your localhost, run the following to transfer the file.

```bash
scp head:/home/{{ username }}/client-configs/files/{{ client_config_client_name }}.ovpn /home/{{ username }}
```

If you are setting up a client for a different machine, such as a mobile
device, you may need to use a different transfer method.

## Step 5: Setup the OpenVPN client on your locahost

How you setup the OpenVPN client will vary based upon what OS the client
machine is running. Follow the steps below for the appropriate OS.

### Windows Host

### Linux Host

### Mac Host

### Android Host

### iOS Host

## Next Step

From here, we have a working network that we can do whatever we want with.
However, it does not do much by itself. To make it actually useful, we
will install the Hashistack (Consul, Vault, and Nomad) on the cluster which
we can then use to run whatever projects we might need.

[Hashistack General Setup](08_general_setup.md)

There are also additional steps you might want to do to secure your server,
especially if you are going to expose it to the internet. You can follow
the steps listed in the following guide for this.

[Secure your servers](https://github.com/imthenachoman/How-To-Secure-A-Linux-Server?tab=readme-ov-file#the-network)

## Reference Links

-   https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04
