##### Configuration inspection
Log into one of the nodes and inspect the running configuration using the `info <YANG PATH>` command.


=== "Command"
    ```srl
    admin@leaf1# info with-context network-instance default
    ```

=== "Expected Output"
    //// collapse-code
    ``` srl
        network-instance default {
            !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
            type default !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
            admin-state enable !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
            description "fabric: my-fabric role: leaf" !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
            router-id 11.0.0.3 !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
            ip-forwarding {
                !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                receive-ipv4-check false
            }
            interface ethernet-1/31.0 {
                !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
            }
            interface ethernet-1/32.0 {
                !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
            }
            interface system0.0 {
                !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
            }
            protocols {
                bgp {
                    admin-state enable !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                    autonomous-system 101 !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                    router-id 11.0.0.3 !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                    dynamic-neighbors {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        interface ethernet-1/31.0 {
                            peer-group bgpgroup-ebgp-my-fabric
                            allowed-peer-as [
                                100
                            ]
                        }
                        interface ethernet-1/32.0 {
                            !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                            peer-group bgpgroup-ebgp-my-fabric
                            allowed-peer-as [
                                100
                            ]
                        }
                    }
                    ebgp-default-policy {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        import-reject-all true
                        export-reject-all true
                    }
                    afi-safi evpn {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        admin-state enable
                        multipath {
                            allow-multiple-as true
                            ebgp {
                                maximum-paths 64
                            }
                            ibgp {
                                maximum-paths 64
                            }
                        }
                        evpn {
                            rapid-update true
                        }
                    }
                    afi-safi ipv4-unicast {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        admin-state enable
                        multipath {
                            allow-multiple-as true
                            ebgp {
                                maximum-paths 32
                            }
                            ibgp {
                                maximum-paths 32
                            }
                        }
                        ipv4-unicast {
                            advertise-ipv6-next-hops true
                            receive-ipv6-next-hops true
                        }
                    }
                    afi-safi ipv6-unicast {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        admin-state enable
                        multipath {
                            allow-multiple-as true
                            ebgp {
                                maximum-paths 32
                            }
                            ibgp {
                                maximum-paths 32
                            }
                        }
                    }
                    preference {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        ebgp 170
                        ibgp 170
                    }
                    route-advertisement {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        rapid-withdrawal true
                        wait-for-fib-install false
                    }
                    group bgpgroup-ebgp-my-fabric {
                        admin-state enable
                        export-policy [
                            ebgp-isl-export-policy-my-fabric
                        ]
                        import-policy [
                            ebgp-isl-import-policy-my-fabric
                        ]
                        failure-detection {
                            enable-bfd true
                            fast-failover true
                        }
                        afi-safi evpn {
                            admin-state disable
                        }
                        afi-safi ipv4-unicast {
                            admin-state enable
                            ipv4-unicast {
                                advertise-ipv6-next-hops true
                                receive-ipv6-next-hops true
                            }
                        }
                        afi-safi ipv6-unicast {
                            admin-state enable
                        }
                    }
                    group bgpgroup-ibgp-rrclient-my-fabric {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        admin-state enable
                        export-policy [
                            ibgp-export-policy-my-fabric
                        ]
                        import-policy [
                            ibgp-import-policy-my-fabric
                        ]
                        failure-detection {
                            enable-bfd true
                            fast-failover true
                        }
                        afi-safi evpn {
                            admin-state enable
                        }
                        afi-safi ipv4-unicast {
                            admin-state disable
                        }
                        afi-safi ipv6-unicast {
                            admin-state disable
                        }
                    }
                    neighbor 11.0.0.4 {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        admin-state enable
                        description "Connected to system interface spine2-system0"
                        peer-as 65000
                        peer-group bgpgroup-ibgp-rrclient-my-fabric
                        afi-safi evpn {
                            admin-state enable
                        }
                        afi-safi ipv4-unicast {
                            admin-state disable
                        }
                        afi-safi ipv6-unicast {
                            admin-state disable
                        }
                        local-as {
                            as-number 65000
                        }
                        transport {
                            local-address 11.0.0.3
                        }
                    }
                    neighbor 11.0.0.5 {
                        !!! EDA Source CRs: fabrics.eda.nokia.com/v1alpha1/Fabric/my-fabric
                        admin-state enable
                        description "Connected to system interface spine1-system0"
                        peer-as 65000
                        peer-group bgpgroup-ibgp-rrclient-my-fabric
                        afi-safi evpn {
                            admin-state enable
                        }
                        afi-safi ipv4-unicast {
                            admin-state disable
                        }
                        afi-safi ipv6-unicast {
                            admin-state disable
                        }
                        local-as {
                            as-number 65000
                        }
                        transport {
                            local-address 11.0.0.3
                        }
                    }
                }
            }
        }
    ```
    ////

/// details | Transaction details
    type: info
Alternatively, you can also inspect the changes in EDA, by looking at the transaction details. This view will show all resources that were created when running your intent. Next to this, the actual translation to node config is also shown here.
///
##### State information
##### Show commands
##### Operational commands
## Summary
=== "C"

    ``` c
    #include <stdio.h>

    int main(void) {
      printf("Hello world!\n");
      return 0;
    }
    ```

=== "C++"

    ``` c++
    #include <iostream>

    int main(void) {
      std::cout << "Hello world!" << std::endl;
      return 0;
    }
    ```
