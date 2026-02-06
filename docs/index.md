---
hide:
  - navigation
---
<script type="text/javascript" src="https://viewer.diagrams.net/js/viewer-static.min.js" async></script>

# Welcome to the EDA Hackathon at KPN Mini SReXperts 2026

Welcome to this Hackathon event focusing on Nokia's Data Center Fabric product portfolio. We hope this set of activities will be challenging and informative no matter what experience level you are.

## Open to all and something for everyone

Whether you're a relative novice to Nokia's products, or a seasoned expert, there is something in this event for you!  All you will need is your trusty laptop,
an afternoon of focus and possibly some coffee (supplied!) and you should find something to benefit both you and your organizations.

## Getting started

This page is your starting point into the event, it should get you familiar with the lab environment provided by Nokia, and provide an overview of the suggested sample activities.

**Please read this page all the way through before attempting any of the activities.**

During this session you will work in groups (or alone if you prefer) on any projects that you are inspired to tackle or on one of the pre-provided activities of varying difficulty.

As long as you have a laptop with the ability to SSH and a web browser, we have example activities and a datacenter fabric lab topology to help you progress if you don’t have something specific already in mind.

Need help, not a problem, pop your hand in the air and an eager expert will be there to guide you.

## Lab Environment

For this event each (group of) participant(s) will receive their own dedicated cloud instance (VM) running a copy of the datacenter fabric lab topology.  You will see this called "your VM",
"your group's hackathon VM", "your group's event VM", "your instance", "your server" and other similar phrases in the activities.  They all mean the same thing, your own dedicated cloud instance.

If everything went according to plan, you should have received:

- The public IP address of your VM.
- SSH credentials to a public cloud instance dedicated to you.
- HTTPS URL's for this repository and access to a web based IDE in case you don't have one installed on your operating system.

/// warning
The public cloud compute instances will be destroyed once the event is concluded.</p>
Please make sure to backup any code, config, etc. <u>offline</u> (e.g. onto your laptop) if you'd like to keep it after the hackathon.
///


### SSH

The simplest way to get going is to use your SSH client to connect to your group's event VM instance and work from there.  All tools and applications are pre-installed and you will have direct access to your entire network.

SSH is also important if you want to directly access your network from your laptop but more on that later.

|     |     |
| --- | --- |
| hostname | `refer to the paper provided or the slide presented` |
| username | `refer to the paper provided or the slide presented` |
| password | `refer to the paper provided or the slide presented` |

### WiFi

WiFi is important here.  Without it your event experience is going to be rather dull.  To connect to the hackathon event's WiFi, refer to the paper provided or the slide presented.

### Topology

When accessing your event VM instance you'll find that the [Hackathon GitHub repository](https://github.com/lvaneeckh/kpn-mini-srx-hackathon) contains all of the documentation, examples, solutions and loads of other great stuff, has already been cloned for you.

In this event, every group has their own complete data center fabric network at their disposal.  Your network comprises an 3 leafs, 2 spines, 2 borderleafs, and 5 linux hosts.  This network is already deployed and provisioned and is ready to go!

*Don't worry: This is your personal group network, you cannot impact any other groups.*

-{{ diagram_file(path='./images/eda.drawio', title='Network Topology', page=0, zoom=1) }}-

### Accessing Topology nodes

#### From your group's event instance VM

To access the lab nodes from within the VM, users should identify the names of the deployed nodes using the `sudo containerlab inspect -a` command.  You will notice they all start with `clab-kpn-hackathon-`.  Your entire network is [powered by ContainerLab](https://containerlab.dev).

If you'd like to see the full list of devices, their hostnames and IP addresses in your network use the following command.

/// tab | cmd

``` bash
sudo containerlab inspect -a
```

///
/// tab | output

``` bash
╭──────────────────────────────────────────┬───────────────┬─────────────┬────────────────────────────────────┬─────────┬────────────────╮
│                 Topology                 │    Lab Name   │     Name    │             Kind/Image             │  State  │ IPv4/6 Address │
├──────────────────────────────────────────┼───────────────┼─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│ kpn-mini-srx-hackathon/clab/kpn.clab.yml │ kpn-hackathon │ borderleaf1 │ nokia_srlinux                      │ running │ 10.128.1.36    │
│                                          │               │             │ ghcr.io/nokia/srlinux:25.10.1      │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ borderleaf2 │ nokia_srlinux                      │ running │ 10.128.1.37    │
│                                          │               │             │ ghcr.io/nokia/srlinux:25.10.1      │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ client1     │ linux                              │ running │ 10.128.1.38    │
│                                          │               │             │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ client2     │ linux                              │ running │ 10.128.1.39    │
│                                          │               │             │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ client3     │ linux                              │ running │ 10.128.1.40    │
│                                          │               │             │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ client4     │ linux                              │ running │ 10.128.1.41    │
│                                          │               │             │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ client5     │ linux                              │ running │ 10.128.1.42    │
│                                          │               │             │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ leaf1       │ nokia_srlinux                      │ running │ 10.128.1.33    │
│                                          │               │             │ ghcr.io/nokia/srlinux:25.10.1      │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ leaf2       │ nokia_srlinux                      │ running │ 10.128.1.34    │
│                                          │               │             │ ghcr.io/nokia/srlinux:25.10.1      │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ leaf3       │ nokia_srlinux                      │ running │ 10.128.1.35    │
│                                          │               │             │ ghcr.io/nokia/srlinux:25.10.1      │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ spine1      │ nokia_srlinux                      │ running │ 10.128.1.31    │
│                                          │               │             │ ghcr.io/nokia/srlinux:25.10.1      │         │ N/A            │
│                                          │               ├─────────────┼────────────────────────────────────┼─────────┼────────────────┤
│                                          │               │ spine2      │ nokia_srlinux                      │ running │ 10.128.1.32    │
│                                          │               │             │ ghcr.io/nokia/srlinux:25.10.1      │         │ N/A            │
╰──────────────────────────────────────────┴───────────────┴─────────────┴────────────────────────────────────┴─────────┴────────────────╯
```

///

Using the names from the above output, we can login to a node using the following command:

For example, to access the `clab-kpn-hackathon-leaf1` node via ssh simply type:

``` bash
ssh admin@clab-kpn-hackathon-leaf1
```

### Accessing Tools

EDA, Grafana and Prometheus are accessible through the browser. You can find them at:

- **EDA** `https://<your-IP>:9443` 
- **Grafana** `https://<your-IP>:9443/core/httpproxy/v1/grafana/dashboards` 
- **Prometheus** `https://<your-IP>:9443/core/httpproxy/v1/prometheus/query` 

## Proposed workflow
You are free to explore and execute the activity at your own will, but for an EDA beginner, we suggest the following order of activities:

1. **Intro.** This page will give you a high level introduction to the concepts used in EDA and get you familiar with the UI.
2. **SR Linux CLI.** While this hackathon mainly focusses on EDA, we think it can still be useful to get introduced with SR Linux CLI. This activity teaches you the basics of our CLI.
3. **Declarative Intents.** This activity dives deeper in the concept of declarative intents, an ideal way to start configuring things in EDA.
4. **EDA Query Language.** Next to deploying intents and configurations on your network, it is very import to be able to verify the Network's state. EDA Query Language allows you to fetch network wide state information.
5. **Underlay/Overlay Networks.** In this activity, you will deploy the underlay network in your fabric using the Fabrics resource.
6. **Telco-Cloud use-case.** Here you will deploy a L3 EVPN service on which you will enable weighted ECMP to achieve equal load balancing on the edge links.
7. **References.** Off course we want to keep the party going. If time allows, you can continue your learning with the `Reference` activities. Explore EDA concepts further, deploy more complicated service architectures or try out some more advanced use-cases.
## FAQ

### My employer/security department locked down my laptop

No worries, we have got you covered! Each instance is running a web-based VSCode code server, when accessing it at `https://<my-IP>:8000` should prompt you for a password (which is documented on the slide provided), and you should be able to access the topology through the terminal there.

### Cloning this repository

If you would like to work locally on your personal device you should clone this repository. This can be done using one of the following commands.

HTTPS:

```bash
git clone https://github.com/lvaneeckh/kpn-mini-srx-hackathon.git
```

SSH:

```bash
git clone git@github.com:lvaneeckh/kpn-mini-srx-hackathon.git
```

GitHub CLI:

```bash
gh repo clone lvaneeckh/kpn-mini-srx-hackathon
```

## Useful links

- [Network Developer Portal](https://network.developer.nokia.com/)
- [containerlab](https://containerlab.dev/)

### SR Linux

- [Learn SR Linux](https://learn.srlinux.dev/)
- [YANG Browser](https://yang.srlinux.dev/)
- [gNxI Browser](https://gnxi.srlinux.dev/)

### Misc Tools/Software

#### Windows

- [WSL environment](https://learn.microsoft.com/en-us/windows/wsl/install)
- [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701)
- [MobaXterm](https://mobaxterm.mobatek.net/download.html)
- [PuTTY Installer](https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.78-installer.msi)
- [PuTTY Binary](https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe)

#### MacOS

- [Ghostty](https://ghostty.org/)
- [iTerm2](https://iterm2.com/downloads/stable/iTerm2-3_4_19.zip)
- [Warp](https://app.warp.dev/get_warp)
- [Hyper](https://hyper.is/)
- [Terminal](https://support.apple.com/en-gb/guide/terminal/apd5265185d-f365-44cb-8b09-71a064a42125/mac)

#### Linux

- [Ghostty](https://ghostty.org/)
- [Gnome Console](https://apps.gnome.org/en/app/org.gnome.Console/)
- [Gnome Terminal](https://help.gnome.org/users/gnome-terminal/stable/)

#### IDEs

- [VS Code](https://code.visualstudio.com/Download)
- [VS Code Web](https://vscode.dev/)
- [Sublime Text](https://www.sublimetext.com/download)
- [IntelliJ IDEA](https://www.jetbrains.com/idea/download/)
- [Eclipse](https://www.eclipse.org/downloads/)
- [PyCharm](https://www.jetbrains.com/pycharm/download)

<script type="text/javascript" src="https://viewer.diagrams.net/js/viewer-static.min.js" async></script>

## Thanks and contributions

The event team would like to thank the following team members (in alphabetical order) for their contributions: Asad Arafat, Bhavish Khatri, Diogo Pinheiro, Gordon Gidofalvy, Guilherme Cale, Hans Thienpondt, James Cumming, Joao Machado, Kaelem Chandra, Korhan Kayhan, Laleh Kiani, Louis Van Eeckhoudt, Maged Makramalla, Miguel Redondo Ferrero, Roman Dodin, Saju Salahudeen, Samier Barguil, Shafkat Waheed, Shashi Sharma, Simon Tibbitts, Siva Sivakumar, Subba Konda, Sven Wisotzky, Thomas Hendriks, Tiago Amado. Zeno Dhaene, Tim Raphael and Vasileios Tekidis
