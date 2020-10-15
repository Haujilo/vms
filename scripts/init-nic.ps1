Remove-VMNetworkAdapter -VMName $args[0]
Add-VMNetworkAdapter -VMName $args[0] -SwitchName vvmsnet0 -StaticMacAddress $args[1]
Add-VMNetworkAdapter -VMName $args[0] -SwitchName vvmsnet1 -StaticMacAddress $args[2]