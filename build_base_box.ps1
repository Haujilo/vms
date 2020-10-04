$box_name="local/debian"
$box_path=(Split-Path -Parent $MyInvocation.MyCommand.Definition) + '\base.box'
$env:BUILD_BASE_BOX=1
$vm_name=( vagrant status | findstr base- ) | Out-String | ForEach-Object {
    $_.split(" ")[0]
}
vagrant up $vm_name
$env:USE_LOCAL_KEY=1
vagrant reload $vm_name
vagrant provision $vm_name --provision-with clean-for-dump
vagrant halt $vm_name
vagrant package --output $box_path $vm_name
vagrant package $vm_name
vagrant box add --force $box_name $box_path
vagrant destroy -f $vm_name
Remove-Item $box_path
&cmd.exe /c rd /s /q ".vagrant"
vagrant box list