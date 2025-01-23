# Setup CA Authority

We will be needing many different key pairs for our various tools. For
these, we will be creating our own self-signed CA Authority key that we
will use to sign all of the other keys.

As Public Key Infrastructure or PKI is a complext topic, I will not attempt
to explain it here. Instead, I will suggest you start by ready the
[Introduction to PKI](https://easy-rsa.readthedocs.io/en/latest/intro-to-PKI/)
on the Easy RSA website as they provide a good overview of the topic.

> [!WARNING]  
> On a production environment, you should have your CA Authority certificate
> signed by a trusted CA Authority instead of using a self-signed certificate.
> As this setup is intended for a home lab and learning purposes, a
> self-signed certificate will serve our purposes fine.

> [!WARNING]  
> Your CA Authority server should be on a separate machine for security
> purposes in a production environment. We are using the head node here
> to limit the number of machines we need to run.

> [!NOTE]  
> **_Ansible Script:_** [05_setup_ca_authority.yaml](../05_setup_ca_authority.yaml)

#### Most noticable / important variables

| Variable            | Default value | Description                                            |
| ------------------- | ------------- | ------------------------------------------------------ |
| common_name         | `Home Lab CA` | The common name for the CA Authority certificate       |
| ssl_local_dir_user  | `pi`          | The username on your localhost                         |
| ssl_local_dir_group | `pi`          | The group on your localhost                            |
| ssl_ca_filename     | `Home-Lab-CA` | The filename for your CA Authority key and certficiate |
| ssl_ca_passphrase   | ``            | This is the password for your CA Authority key         |

#### Variable Files

-   vars/general/main.yaml
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

## Step 1: Create the PKI

Here is where our steps will depart from what the Ansible scripts are
doing slightly. The Ansible scripts are using the various OpenSSL modules
to handle the creation of the keys and signed certificates. However,
for doing these steps manually, we are going to use the EasyRSA tool.
This tool is a wrapper around OpenSSL which makes it easier to generate
the keys needed.

### Step 1.1: Install EasyRSA

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

Finally, we need to initialize the PKI inside of the `easy-rsa` directory.

```bash
cd ~/easy-rsa
./easyrsa init-pki
```

### Step 1.2: Create a CA key and certificate

Now that our directory is all setup, we can configure EasyRSA using a
`vars` file.

```bash
cd ~/easy-rsa
nano vars
```

When this file is opened, past teh following lines and edit each of the REQ
values to reflect your own organization info. The ALGO, DIGEST, and CURVE
values should stay the same to match what the Ansible scripts are using.

```
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "NewYork"
set_var EASYRSA_REQ_CITY       "New York City"
set_var EASYRSA_REQ_ORG        "Home Lab"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community"
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"
set_var EASYRSA_CURVE          "secp256r1"
```

The, you will create a root public and private key pair for your
Certificate Authority.

```bash
./easyrsa build-ca
```

This command will ask you to enter a passphrase for the key pair. Use
a strong passphrase and be sure to save it somewhere. This would be the
passphrase that would be stored in the `ssl_ca_passphrase` variable in
the [Secrets](../vars/general/secrets.yaml) variable file for using the
Ansible scripts. Even if you don't store it in the the variable file,
you need to be sure to store it somewhere as you will need it for anytime
you interact with the CA like signing or revoking certificates.

You will also be asked to confirm the Common Name (CN) for your CA.

> [!NOTE]  
> If you don't want to be prompted for a password everytime you use the
> CA, you can pass the `nopass` option to the command
>
> ```bash
> ./easyrsa build-ca nopass
> ```

This will generate two files, `~/easy-rsa/pki/ca.crt` and
`~/easy-rsa/pki/private/ca.key`, which make up the public and private
components of your CA.

`ca.crt` is your public certificate file. Users, servers, and clients
will use this certificate to verify that they are part of the same web
of trust. You will distribute this your localhost and each of the
Hashistack nodes in later steps.

`ca.key` is your private key that the CA uses to sign certificates. This
file should stay on your CA and never be distributed. A bad actor with
access to this file can cause all sorts of harm.

## Step 2: Copy the CA public key to your localhost

We will now copy the CA public certificate to our localhost so we can
use it to verify traffic coming from our cluster. On your localhost, run
the following commands to create a directory where you will store the
certificate for use later, and then copy the certificate to your localhost.

```bash
mkdir -p ~/ssl/certs
scp head:/home/{{ username }}/easy-rsa/pki/ca.crt ~/ssl/certs
```

## Next Step

[Setup OpenVPN](06_setup_openvpn.md)

## Reference Links

-   https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04
-   https://easy-rsa.readthedocs.io/en/latest/intro-to-PKI/
