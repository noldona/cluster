# Setup OpenVPN

Due to the fact that the Hashistack nodes are setup on a sub-network from
our home network, we need to setup and configure OpenVPN so that we will
be able to reach the Consul, Vault, and Nomad pages that will be running
on the Hashistack nodes. It will also be useful for accessing any other
sites you might want to run internal to the cluster and not exposed
outside of it.

> [!WARNING]  
> On a production environment, your OpenVPN server should be separate
> from your CA server. It is also recommended that your VPN server be
> on a separate machine from your other servers for security purposes.
> As this is for a home lab setup with a limited number of machines, we
> will be running this on our head node.

> [!NOTE]  
> **_Ansible Script:_** [06_setup_openvpn.yaml](../06_setup_openvpn.yaml)

#### Most noticable / important variables

| Variable          | Default value | Description                                    |
| ----------------- | ------------- | ---------------------------------------------- |
| openvpn_port      | `1194`        | The port OpenVPN will listen on                |
| openvpn_proto     | `udp`         | The protocol OpenVPN will listen on            |
| ssl_ca_passphrase | ``            | This is the password for your CA Authority key |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/ssl.yaml
-   vars/general/secrets.yaml
-   vars/general/openvpn.yaml

> [!IMPORTANT]  
> The ansible script expects a `vars/general/secrets.yaml` file to exist.
> As this file will contain things like passwords and should not be commited
> to your repository, you will need to create this file and add the
> `ssl_ca_passphrase` variable to it. The file is listed in the .gitignore
> to prevent it from being added to the repository.

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

## Step 1: Install OpenVPN

As we will be using OpenVPN, we need to install it

```bash
sudo apt install openvpn
```

> [!TIP]  
> We will also be using EasyRSA to generate our keys for OpenVPN. If you
> have not completed the steps in [Setup CA Authority](05_setup_ca_authority.md),
> do that now before continuing with this. It is recommended that if you
> ran the Ansible script for setting up the CA Authority, that you run
> the Ansible script for this as well due to the location of the keys and
> certificates being different between Ansible scripts and the manual steps.

## Step 2: Create key pair for OpenVPN

As you have completed setting up the `easy-rsa` directory in the previous
set of steps, we will not repeat setting up this folder.

### Step 2.1: Create the private key and certificate signing request (CSR)

First, we will generate the private key and certificate signing request
for our OpenVPN server.

```bash
cd ~/easy-rsa
./easyrsa gen-req openvpn-server nopass
```

Just hit Enter when asked to confirm the Common Name.

### Step 2.2: Copy the private key to the OpenVPN server

The private key, `~/easy-rsa/pki/private/openvpn-server.key`, needs to be
copied over to the OpenVPN server.

```bash
sudo cp ~/easy-rsa/pki/private/openvpn-server.key /etc/openvpn/server
```

### Step 2.3: Sign the CSR using our CA key

The certificate signing request (CSR) needs to be signed by our CA key.
This can be done using the following command.

```bash
./easyrsa sign-req server openvpn-server
```

You will be prompted for the CA key passphrase. Use the passphrase you
entered when you created the CA key here.

### Step 2.4: Copy the public certificate to the OpenVPN server

The previous step will create the certificate file,
`~/easy-rsa/pki/issued/openvpn-server.crt`. This file needs to be copied
to the OpenVPN server directory as well.

```bash
sudo cp ~/easy-rsa/pki/issued/openvpn-server.ct /etc/openvpn/server
```

### Step 2.5: Copy the CA certificate to the OpenVPN server

We also need to provide the OpenVPN server with a copy the CA certificate.
This can be copied by running the following:

```bash
sudo cp ~/easy-rsa/pki/ca.crt /etc/openvpn/server
```

## Step 3: Create a Pre-Shared Key

For added security, we will be adding an extra shared secret key to the
server and all clients using OpenVPN's tls-crypt directive. To generate
the `tls-crypt` preshare key, run the following commands.

```bash
cd ~/easy-rsa
openvpn --genkey --secret ta.key
```

This will generate the `ta.key` file which needs to be copied to the
OpenVPN server.

```bash
sudo cp ta.key /etc/openvpn/server
```

## Step 4: Configure OpenVPN

To configure the OpenVPN server, we are going to copy the sample `server.conf`
file as a starting point.

```bash
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/server/
sudo gunzip /etc/openvpn/server/server.conf.gz
```

Open the new file with a text editor of your choice. We will be making
several changes to this file.

```bash
sudo nano /etc/openvpn/server/server.conf
```

First, find the line that starts with `tls-auth` and comment it out using
a `;` at the beginning of the line. Then add a new line containing
`tls-crypt ta.key`.

```
; tls-auth ta.key 0 # This file is secret
tls-crypt ta.key
```

Next, we will be updating the ciphers. The default value is set to
`AES-256-CBC`, but the `AES-256-GCM` cipher offers a better level of
encryption, performance, and is supported by up-to-date OpenVPN clients.
Find the line with `cipher AES-256-CBC` and comment it out by putting a
`;` at the beginning of the line. Then add a new line containing
`cipher AES-256-GCM` And then immediately after, add a line with
`auth SHA256` to set our message digest algorithm.

```
; cipher AES-256-CBC
cipher AES-256-GCM
auth SHA256
```

Since we configured EasyRSA to use the EC (Elliptic Curve) Cryptography,
there is no need for the Diffie-Hellman seed file. Comment out the line
that looks like `dh dh2048.pem` or `dh dh.pem` and add a new line that
says `dh none`.

```
; dh dh2048.pem
dh none
```

We also want OpenVPN to run with no privileges once it has started, so
we will configure it to run with user `nobody` and group `nogroup`.
Find the lines with the commented out `user openvpn` and `group openvpn`
and add lines below them with `user nobody` and `group nogroup`.

```
; user openvpn
; group openvpn
user nobody
group nogroup
```

We also want to make all clients redirect their traffic through the VPN.
We will do this by uncommenting the `push "redirect-gateway def1 bypass-dhcp"`
line.

```
push "redirect-gateway def1 bypass-dhcp"
```

Just below this, find the `dhcp-options` section and uncomment both lines.
Update the IP addresses to be `10.0.0.1` and `192.168.1.1` or whatever the
gateway IP is for your home network. These will cause your traffic to
go through the DNSMasq server on the head node before going to the normal
route. This allows you to reach sites configured in the sub-network.

```
push "dhcp-option DNS 10.0.0.1"
push "dhcp-option DNS 192.168.1.1"
```

Finally, fine the `cert` and `key` lines and update them to use the
correct names for the key and certifice files.

```
cert openvpn-server.crt
key openvpn-server.key
```

### Optional

Optionally, you can change which port and protocol OpenVPN uses. By default
it uses port `1194` and the `udp` protocol. If you wish to change these,
find the line with `port` and `proto` and update them appropriately.

If you do end up changing the protocol to `tcp`, you will need to change
the `explicit-exit-notify` directive's value from 1 to 0 as this directive
is only used by UDP.

```
explicit-exit-notify 0
```

## Step 5: Configure UFW

We also need to open the port in our firewall to allow traffic to access
the VPN server.

```bash
sudo ufw allow 1194 / udp
```

If you did the optional update of the port and protocol in the previous
step, use the port and protocol you set the OpenVPN config to use here
instead.

## Step 6: Start OpenVPN

OpenVPN runs as a `systemd` service, so we will use `systemctl` to manage
it. We want this service to run as soon as the head node boots up, so
we will enable this service.

```bash
sudo systemctl -f enable openvpn-server@server.service
```

Now, we can start the service.

```bash
sudo systemctl start openvpn-server@server.service
```

We can double check that the service is running by using the following
command.

```bash
sudo systemctl status openvpn-server@server.service
```

## Next Step

[Create OpenVPN Client](07_create_openvpn_client.md)

## Reference Links

-   https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04
