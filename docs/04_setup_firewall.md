# Setup the Firewall

For security purposes, we will be adding a firewall to our head node. For
this, we will be use UFW.

> [!NOTE]  
> **_Ansible Script:_** [04_setup_firewall.yaml](../04_setup_firewall.yaml)

#### Most noticable / important variables

| Variable | Default value             | Description                                    |
| -------- | ------------------------- | ---------------------------------------------- |
| apps     | `SSH, NFS, WWW Full, DNS` | The list of apps that ports will be opened for |
| ports    | `67, 68, 69, 123`         | The list of ports that will be opened          |

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

## Step 1:

## Next Step

[Setup CA Authority](05_setup_ca_authority.md)

## Reference Links

https://github.com/imthenachoman/How-To-Secure-A-Linux-Server?tab=readme-ov-file#the-network
