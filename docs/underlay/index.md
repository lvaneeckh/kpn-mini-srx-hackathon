# Underlay and Overlay Networks

Typically in a Data Center Fabric network, **BGP** is used as the de-facto routing protocol. The control plane is split into two functions, the underlay and the overlay network. 

## Underlay Network
The **underlay network** provides IP connectivity between the data center's servers and routers. Typically, **eBGP** is being used as routing protocol for its dependability and scalability.

-{{ diagram_file(path='../images/eda.drawio', title='Underlay Network', page=1, zoom=1.5) }}-

## Overlay Network
An **overlay network** is established using tunneling techniques to carry traffic over the underlay network. This makes an overlay network logically separate and independent from the addressing and protocols used in the underlay network. It also keeps the overlay networks logically separate from each other. Workloads that are connected to the same overlay network can send Ethernet or IP packets to each other, but not to workloads in other overlay networks. Typically, **iBGP** is used to distribute reachability information for the workload endpoints.

-{{ diagram_file(path='../images/eda.drawio', title='Overlay Network', page=2, zoom=1.5) }}-

We will deploy the underlay and overlay network in our Data Center Fabric using EDA's `Fabrics` resource. More on this on the [next page](./fabrics.md).
