# Install Hashistack

We are now going to install Consul, Vault, and Nomad on the Hashistack
nodes. The are the main components that will make the Hashistack work.

> [!NOTE]  
> **_Ansible Script:_** [10_hashistack_install.yaml](../10_hashistack_install.yaml)

#### Most noticable / important variables

| Variable                    | Default value          | Description                            |
| --------------------------- | ---------------------- | -------------------------------------- |
| hashicorp_product_selection | `consul, nomad, vault` | The HashiCorp products we will install |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/hashi_nodes.yaml
-   vars/hashicorp/main.yaml

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

> [!IMPORTANT]  
> You will need to run each of these steps on each of the Hashistack
> nodes unless otherwise mentioned.

## Step 1: Add the HashiCorp GPG key

First thing we need to do is add the official HashiCorp GPG key.

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

## Step 2: Add the HashiCorp repository to Apt sources

Next, we need to add the HashiCorp repository to the Apt sources, so
that we can install the software.

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

## Step 3: Install the HashiCorp products

Finally, we can install Consul, Vault, and Nomad.

```bash
sudo apt update && sudo apt install consul vault nomad
```

## Step 4: Setup Autocomplete

Since we may be interacting with these tools via the CLI, we will want
to install the autocomplete to make our lives easier. We will also want
to install the autocomplete as both root and our regular user so it is
avaiable in both cases.

```bash
sudo consul -autocomplete-install
sudo vault -autocomplete-install
sudo nomad -autocomplete-install
consul -autocomplete-install
vault -autocomplete-install
nomad -autocomplete-install
```

## Next Step

[Install DNSMasq](11_dnsmasq_install.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
-   https://developer.hashicorp.com/consul/install
-   https://developer.hashicorp.com/vault/install
-   https://developer.hashicorp.com/nomad/install
-   https://developer.hashicorp.com/consul/commands#autocompletion
-   https://developer.hashicorp.com/vault/docs/commands#enable-autocomplete
-   https://developer.hashicorp.com/nomad/docs/commands#autocomplete
