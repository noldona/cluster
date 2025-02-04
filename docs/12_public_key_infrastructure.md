# Setup PKI

We will now create some key pairs that we will need for not only the
servers and clients, but one which will get used for the demo web app
that we will use later.

> [!NOTE]  
> **_Ansible Script:_** [12_public_key_infrastructure.yaml](../12_public_key_infrastructure.yaml)

#### Most noticable / important variables

| Variable          | Default value     | Description                                    |
| ----------------- | ----------------- | ---------------------------------------------- |
| demo_fqdn         | `homelab.cluster` | The domain name used for the demo application  |
| ssl_ca_passphrase | ``                | This is the password for your CA Authority key |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/hashi_nodes.yaml
-   vars/hashicorp/main.yaml
-   vars/general/ssl.yaml
-   vars/general/secrets.yaml
-   vars/hashicorp/ssl.yaml

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

## Step 1: Install EasyRSA

Our manual steps will depart from the Ansible scripts slightly here as
we will be using EasyRSA for key creating instead of OpenSSL directly
like the Ansible script does. EasyRSA is a wrapper around OpenSSL that
makes it easier to generate keys and certificates.

First, we will need to install the tool

```bash
sudo apt install easy-rsa
```

We will also be using a different directory to store our keys and
certificates in. The Ansible script uses the default `/etc/ssl/private`
and `/etc/ssl/certs` directories, but for ease, we will be creating
a directory in our home directory.

```bash
mkdir ~/easy-rsa
```

Next, we need to create a symbolic link pointing to the easy-rsa package
files. Those are located in the `/usr/share/easy-rsa` directory.

```bash
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
```

We also want to restrict access to this directory to ensure only our
user can access it.

```bash
chmod 700 /home/{{ username }}/easy-rsa
```

We need to initialize the PKI inside of the `easy-rsa` directory.

```bash
cd ~/easy-rsa
./easyrsa init-pki
```

Finally, we want to configure EasyRSA using a `vars` file.

```bash
cd ~/easy-rsa
cat << EOF > vars
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"
set_var EASYRSA_CURVE          "secp256r1"
EOF
```

## Step 2: Create the web app key and certificate

For this step, we will only run this on the server1 node. We will add
this key and certificate to Vault in a later step for the web app to use.

### Step 2.1: Create the private key and certificate signing request (CSR)

First, we will generate the private key and certificate signing request
for our web app.

```bash
cd ~/easy-rsa
./easyrsa gen-req --subject-alt-name="DNS:homelab.cluster" homelab.cluster nopass
```

Just hit Enter when asked to confirm the Common Name.

### Step 2.2: Copy the CSR to the head node

As our CA server is on the head node, we need to copy the CSR to the head
node to be able to sign it. On the head node, run the following to copy
the CSR over.

```bash
scp server1:/home/pi/easy-rsa/pki/reqs/homelab.cluster.req /tmp
```

### Step 2.3: Sign the CSR using our CA key

The certificate signing request (CSR) needs to be signed by our CA key.
To do this we need to import it into EasyRSA on the head node before we
can sign it.

On the head node, run the following.

```bash
cd ~/easy-rsa
./easyrsa import-req /tmp/homelab.cluster.req server
./easyrsa sign-req server homelab.cluster
```

When prompted to verify that the request comes from a trusted source,
type `yes` and press `Enter`.

You will also be prompted to enter the passphrase you used to create the
CA key.

This will import the CSR and then sign it. It will generate the certificate
at `~/easy-rsa/pki/issued/homelab.cluster.crt`.

### Step 2.4: Copy the signed certificate back to server1

We need to copy this signed certificate back to server1 for use later.
On the head node, run the following to copy the certificate back to
server1.

```bash
scp ~/easy-rsa/pki/issued/homelab.cluster.crt server1:/tmp
```

Then on the server1 node, move the certificate file from `/tmp` to our
`~/easy-rsa/pki/issued` directory.

```bash
mv /tmp/homelab.cluster.crt ~/easy-rsa/pki/issued/
```

## Step 3: Copy the CA certificate to each of the nodes

Each of the nodes will also need a copy of the CA certificate file. On
the head node, run the following to copy the file to each of the
Hashistack nodes.

```bash
scp ~/easy-rsa/pki/ca.crt server1:/tmp
scp ~/easy-rsa/pki/ca.crt server2:/tmp
scp ~/easy-rsa/pki/ca.crt server3:/tmp
scp ~/easy-rsa/pki/ca.crt client1:/tmp
scp ~/easy-rsa/pki/ca.crt client2:/tmp
scp ~/easy-rsa/pki/ca.crt client3:/tmp
scp ~/easy-rsa/pki/ca.crt client4:/tmp
scp ~/easy-rsa/pki/ca.crt client5:/tmp
scp ~/easy-rsa/pki/ca.crt client6:/tmp
scp ~/easy-rsa/pki/ca.crt client7:/tmp
scp ~/easy-rsa/pki/ca.crt client8:/tmp
```

The on each of the Hashistack nodes, copy the CA certificate into the local
cert directory. And then update the certificate index so it picks up the
new certificate.

```bash
sudo mv /tmp/ca.crt /usr/local-share/ca-certificates
sudo /usr/sbin/update-ca-certificates -f
```

## Next Step

[Deploy Consul](13_consul_deploy.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
-   https://easy-rsa.readthedocs.io/en/latest/intro-to-PKI/
