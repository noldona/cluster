# Install DNSMasq

We will be configuring Consul to look to it's own localhost for DNS
resolution. This will allow us to setup each node talking to each other
easier. To do this, we need to install DNSMasq on each of the Hashistack
nodes to act as your DNS server. These will be configured with the DNSMasq
running on the head node as it's upstream DNS server.

> [!NOTE]  
> **_Ansible Script:_** [11_dnsmaqs_install.yaml](../11_dnsmasq_install.yaml)

If you are using Ansible, run the script now. Once it is done, go to
[Next Step](#next-step).

If you want to run the steps manually, continue here.

> [!IMPORTANT]  
> You will need to run each of these steps on each of the Hashistack
> nodes unless otherwise mentioned.

## Step 1: Ensure hosts file has correct entry

This should have been setup all the way back in the [Initial Setup](01_initial_setup.md),
but we can double check it here to make sure it is correct.

Check the `/etc/hosts` file and ensure that the correct hostname is
pointing to `127.0.0.1`.

```
127.0.0.1 {{ node.hostname }}
```

## Step 2: Install DNSMasq

We will now install DNSMasq onto the Hashistack nodes.

```bash
sudo apt update && sudo apt install dnsmasq
```

## Step 3: Configure DNSMasq

We only need some basic settings for the DNSMasq config.

On the server nodes, update `/etc/dnsmasq.conf` with the following.

```bash
cat << EOF > /etc/dnsmasq.conf
# DNS configuration
port=53

domain-needed
bogus-priv

strict-order
expand-hosts
EOF
```

On the client nodes, update `/etc/dnsmasq.conf` with the following.

```bash
cat << EOF > /etc/dnsmasq.conf
# DNS configuration
port=53

domain-needed
bogus-priv

strict-order
expand-hosts

listen-address=127.0.0.1
interface=lo
bind-interfaces
EOF
```

## Step 4: Add DNSMasq config for Consul

We need to add some configs specifically for Consul. We will add these
to `/etc/dnsmasq.d/10-consul`. On all of the nodes, run the following to
add the config settings.

```bash
cat << EOF > /etc/dnsmasq.d/10-consul
# Enable forward lookup of the 'consul' domain:
server=/consul/127.0.0.1#8600

# Uncomment and modify as appropriate to enable reverse DNS lookups for
# common netblocks found in RFC 1918, 5735, and 6598:
rev-server=0.0.0.0/8,127.0.0.1#8600
rev-server=10.0.0.0/8,127.0.0.1#8600
#rev-server=127.0.0.1/8,127.0.0.1#8600
rev-server=172.16.0.0/16,127.0.0.1#8600
rev-server=192.168.0.0/16,127.0.0.1#8600
EOF
```

## Step 5: Update resolv.conf

We also want to update `/etc/resolv.conf` to use the localhost for DNS
resolution first before going to the head node.

```bash
cat << EOF > /etc/resolv.conf
nameserver 127.0.0.1
nameserver 10.0.0.1
EOF
```

## Step 6: Enable and start DNSMasq

We need to then enable and start DNSMasq.

```bash
sudo systemctl enable dnsmasq.service
sudo systemctl start dnsmasq.service
```

## Next Step

[Setup PKI](12_public_key_infrastructure.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
-   https://netbeez.net/blog/how-to-set-up-dns-server-dnsmasq/
