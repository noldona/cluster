# Setup OpenVPN

Due to the fact that the Hashistack nodes are setup on a sub-network from
our home network, we need to setup and configure OpenVPN so that we will
be able to reach the Consul, Vault, and Nomad pages running on the Hashistack
nodes. it will also be useful for accessing any other sites you might want
to run internal to the cluster and not expose outside of it.

> [!NOTE]  
> **_Ansible Script:_** [06_setup_openvpn.yaml](../06_setup_openvpn.yaml)

#### Most noticable / important variables

| Variable      | Default value | Description                         |
| ------------- | ------------- | ----------------------------------- |
| openvpn_port  | `1194`        | The port OpenVPN will listen on     |
| openvpn_proto | `udp`         | The protocol OpenVPN will listen on |

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

## Step 1:

## Next Step

[Create OpenVPN Client](07_create_openvpn_client.md)

## Reference Links

https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04
