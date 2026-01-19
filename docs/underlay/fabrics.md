# Fabrics

<script type="text/javascript" src="https://viewer.diagrams.net/js/viewer-static.min.js" async></script>

|                       |                                                                                                                      |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Short Description** | Creating underlay connectivity and overlay control plane using the fabric resource                                                     |
| **Difficulty**        | Beginner                                                                                                             |
| **Topology Nodes**    | :material-router: spine1, :material-router: spine2, :material-router: leaf1, :material-router: leaf2, :material-router: leaf3, :material-router: borderleaf1, :material-router: borderleaf2           |

## Objective

In this exercise, we enable IP connectivity between the switches in our lab topology. This underlay network is the basis of our fabric. It provides connectivity and allows EVPN routes to be exchanged to build services.

## Technology explanation

As discussed on the [intro page](./index.md), we will need to establish eBGP sessions between leafs and spines, and a full mesh of iBGP sessions to setup the underlay and overlay networks in our fabric. EDA will abstract the concept of a "fabric" and translate the user's input into node configuration. When building a fabric, you need to be weary of many different things, ISL IP addresses, ASNs, routing policies, loopback IP addresses, etc. EDA will automatically allocate these parameters from a pool. However, if you want more control over these choices, this is still possible.

EDA is built on apps, the `Fabrics` app allows you to create a fabric, which on its turn will create multiple resources in other apps, which in its turn are translated into node configuration.
![alt text](../images/fabrics.png)

## Tasks

### Validate that no IP connectivity is present
In SR Linux, the underlay routing protocol is specified in the default network-instance. Therefore, the absolute minimum configuration required to build a fabric, is the default network-instance.

Login into one of the nodes and verify whether the default network-instance is configured.

/// details | Solution
    type: success
/// tab | command

```srl
admin@leaf1# info network-instance default

```

///
/// tab | expected output

```srl
*EMPTY*
```

///

///
### Create a Fabric

Navigate to the fabrics app and create a new fabric resource.

![navigate to fabrics](../images/nav-to-fabrics.png)

Go through the form and build your fabric.

/// details | Hint
    type: tip
Make sure, when filling out the form, that you are using the appropriate **labels** to build your fabric resource efficiently.
-{{ diagram_file(path='../images/eda.drawio', title='Node role labels', page=3, zoom=1.5) }}-
```yaml
# <SNIP>
  interSwitchLinks:
    linkSelector:
      - eda.nokia.com/role=interSwitch
    unnumbered: IPV6
# <SNIP>
```
///

/// details | Hint
    type: tip
When selecting your inter-switch links (ISLs), you can allocate them to an address pool, or skip this entirely by using IPv6 unnumbered interfaces. This also saves you some IP addressing space.
```yaml
# <SNIP>
  borderLeafs:
    borderLeafNodeSelector:
      - eda.nokia.com/role=borderleaf
  leafs:
    leafNodeSelector:
      - eda.nokia.com/role=leaf
  spines:
    spineNodeSelector:
      - eda.nokia.com/role=spine
# <SNIP>
```
///

/// details | Solution
    type: success

It might be tricky to solve this challenge if you see EDA for the first time, so here is a solution:
```yaml
apiVersion: fabrics.eda.nokia.com/v1alpha1
kind: Fabric
metadata:
  name: my-fabric
  namespace: eda
spec:
  borderLeafs:
    borderLeafNodeSelector:
      - eda.nokia.com/role=borderleaf
  interSwitchLinks:
    linkSelector:
      - eda.nokia.com/role=interSwitch
    unnumbered: IPV6
  leafs:
    leafNodeSelector:
      - eda.nokia.com/role=leaf
  overlayProtocol:
    bfd:
      desiredMinTransmitInt: 1000000
      detectionMultiplier: 3
      enabled: true
      minEchoReceiveInterval: 1000000
      requiredMinReceive: 1000000
    bgp:
      autonomousSystem: 65000
      clusterID: '1'
      rrClientNodeSelector:
        - eda.nokia.com/role=leaf
        - eda.nokia.com/role=borderleaf
      rrNodeSelector:
        - eda.nokia.com/role=spine
    protocol: IBGP
  spines:
    spineNodeSelector:
      - eda.nokia.com/role=spine
  systemPoolIPV4: systemipv4-pool
  underlayProtocol:
    bfd:
      desiredMinTransmitInt: 1000000
      detectionMultiplier: 3
      enabled: true
      minEchoReceiveInterval: 1000000
      requiredMinReceive: 1000000
    bgp:
      asnPool: asn-pool
    protocol:
      - EBGP

```
///

/// details | Other fabric types
    type: info
You may have noticed that eBGP underlay / iBGP overlay is not the only option in our fabric abstraction. EDA allows you to build fabrics using eBGP, OSPFv2 and OSPFv3 on the underlay, and iBGP or eBGP on the overlay.
/// details | example: OSPFv2 underlay, iBGP overlay
    type: example
``` yaml
apiVersion: fabrics.eda.nokia.com/v1alpha1
kind: Fabric
metadata:
  name: my-fabric
  namespace: eda
spec:
  borderLeafs:
    borderLeafNodeSelector:
      - eda.nokia.com/role = borderleaf
  interSwitchLinks:
    linkSelector:
      - eda.nokia.com/role = interSwitch
    poolIPV4: ipv4-pool
  leafs:
    leafNodeSelector:
      - eda.nokia.com/role = leaf
  overlayProtocol:
    bfd:
      desiredMinTransmitInt: 1000000
      detectionMultiplier: 3
      enabled: true
      minEchoReceiveInterval: 1000000
      requiredMinReceive: 1000000
    bgp:
      autonomousSystem: 65000
      clusterID: '1'
      rrClientNodeSelector:
        - eda.nokia.com/role=leaf
        - eda.nokia.com/role=borderleaf
      rrNodeSelector:
        - eda.nokia.com/role=spine
    protocol: IBGP
  spines:
    spineNodeSelector:
      - eda.nokia.com/role = spine
  systemPoolIPV4: systemipv4-pool
  underlayProtocol:
    bfd:
      desiredMinTransmitInt: 1000000
      detectionMultiplier: 3
      enabled: true
      minEchoReceiveInterval: 1000000
      requiredMinReceive: 1000000
    protocol:
      - OSPFv2
```
///
/// details | example: eBGP underlay, eBGP overlay
    type: example
``` yaml
apiVersion: fabrics.eda.nokia.com/v1alpha1
kind: Fabric
metadata:
  name: my-fabric
  namespace: eda
spec:
  borderLeafs:
    borderLeafNodeSelector:
      - eda.nokia.com/role = borderleaf
  interSwitchLinks:
    linkSelector:
      - eda.nokia.com/role = interSwitch
    unnumbered: IPV6
  leafs:
    leafNodeSelector:
      - eda.nokia.com/role = leaf
  overlayProtocol:
    bgp: {}
    protocol: EBGP
  spines:
    spineNodeSelector:
      - eda.nokia.com/role = spine
  systemPoolIPV4: systemipv4-pool
  underlayProtocol:
    bfd:
      desiredMinTransmitInt: 1000000
      detectionMultiplier: 3
      enabled: true
      minEchoReceiveInterval: 1000000
      requiredMinReceive: 1000000
    protocol:
      - EBGP
    bgp:
      asnPool: asn-pool
```
///
///

### Validate underlay connectivity
#### Fabric summary dashboard
#### Using EDA Workflows
#### Transaction details
#### SR Linux CLI

## Summary
