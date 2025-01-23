# Create OpenVPN Client

We will now create a client configuration for OpenVPN. This configuration
will be used to setup the OpenVPN client on your localhost.

> [!NOTE]  
> **_Ansible Script:_** [##\_name.yaml](../##_name.yaml)

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

## Step 1:

## Next Step

[Name](##_name.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
