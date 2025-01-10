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

## Step 1: Install UFW

We will be using UFW as our firewall, so we need to install it.

```bash
sudo apt install ufw
```

## Step 2: Configure UFW

To configure UFW, we will need to set the various permissions for traffic.

### Step 2.1: Allow outgoing traffic

To make life easier, we are going to allow all outgoing traffic by default.
We will assume that any outgoing traffic is legitimate. This is the choice
the Ansible script uses.

```bash
sudo ufw default allow outgoing comment 'Allow all outgoing traffic'
```

If you wish for more security and only allowing specific outgoing traffic,
you can deny all outgoing traffic by default.

```bash
sudo ufw default deny outgoing comment'Deny all outgoing traffic'
```

### Step 2.2: Deny incoming traffic

Next, we want to deny all incoming traffic by default for security purposes.

```bash
sudo ufw default deny incoming comment ' Deny all incoming traffiic'
```

### Step 2.3: Open ports for specific apps

Next, we will want to specifically open the ports for the traffic for
the apps that we are going to use. These will include SSH since we will
want to be able to SSH into the machine, NFS as the Hashistack nodes will
use this to load their files, DNS for both in and out as we will want to
be able to do domain name resolution, and WWW Full since we will be serving
HTTP/HTTPS content from the Hashistack nodes.

```bash
sudo ufw allow in SSH comment 'Allow SSH connections in'
sudo ufw allow in NFS comment 'Allow NFS connections in'
sudo ufw allow 'WWW Full' comment ' Allow HTTP/HTTPS traffic'
sudo ufw allow in on eth0 DNS comment 'Allow DNS calls in on eth0'
sudo ufw allow out on eth1 DNS comment 'Allow DNS calls out on eth1'
```

### Step 2.4: Open specific ports

Next, we will need to open additional ports for the traffic that we will
be expecting that UFW does not have apps specifically created for. These
will be ports 67 and 68 for DHCP, 69 for TFTP, and 123 for NTP.

```bash
sudo ufw allow on eth0 67 comment 'Allow DHCP calls on eth0'
sudo ufw allow on eth0 68 comment 'Allow DHCP calls on eth0'
sudo ufw allow on eth0 69 comment 'Allow TFTP calls on eth0'
sudo ufw allow out 67 comment 'Allow DHCP calls on eth0'
```

## Step 3: Configure NAT rules

Next, we need to configure the NAT translation rules. These will allow
the Hashistack nodes to be able to reach the outside world through the
head node.

### Step 3.1: Enable packet forwarding

In `/etc/sysctl.conf` we need to uncomment the `net.ipv4.ip_forward` line.

```bash
sudo sed -i 's/^#net.ipv4.ip_forward=1$/net.ipv4.ip_forward=1/' /etc/sysctl.conf
```

### Step 3.2: Enable NAT Translation

To enable the NAT translation, we will need to edit `/etc/ufw/before.rules`
and add the following lines just before the filter rules.

```
# NAT table rules
*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# Forward traffic through eth1
-A POSTROUTING -o eth1 -j MASQUERADE

# don't delete the 'COMMIT' line or these nat table rules won't be processed
COMMIT
```

### Step 3.3: Configure UFW to forward packets

We also need to set UFW to forward packets, so it doesn't try to block
the packets being forwarded. To do this, we need to change the
`DEFAULT_FORWARD_POLICY` setting in `/etc/default/ufw` from `DROP` to
`ACCEPT`.

```bash
sudo sed -i 's/^DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
```

## Step 4: Enable the firewall

Finally, now that we have everything configured, we can enable the firewall.

```bash
sudo ufw enable
```

You can then see the status of the firewall by running

```bash
sudo ufw status
```

## Next Step

[Setup CA Authority](05_setup_ca_authority.md)

## Reference Links

https://github.com/imthenachoman/How-To-Secure-A-Linux-Server?tab=readme-ov-file#the-network

https://unix.stackexchange.com/questions/575178/sharing-wifi-internet-through-ethernet-interface
