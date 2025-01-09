# Setup CA Authority

We will be needing many different key pairs for our various tools. For
these, we will be creating our own self-signed CA Authority key that we
will use to sign all of the other keys.

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

The ansible script expects a `vars/genera/secrets.yaml` file to exist.
As this file will contain things like passwords and should not be commited
to your repository, you will need to create this file and add the
`ssl_ca_passphrase` variable to it. The file is listed in the .gitignore
to prevent it from being added to the repository.

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

## Step 1:

## Next Step

[Setup OpenVPN](06_setup_openvpn.md)

## Reference Links

https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04
