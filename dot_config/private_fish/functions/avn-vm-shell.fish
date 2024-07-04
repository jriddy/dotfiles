function avn-vm-shell
    if not set -q VMCTLDIR
        echo >&2 "VMCTLDIR unset"
        return 1
    end

    set -l release 39
    set -l container_prefix 'aiven-fedora'

    set -l vm "$container_prefix-$release"

    vmctl list | grep -q "stopped.*$vm\$"
    and vmctl start "$vm"

    set -l ip_file "$VMCTLDIR/$vm/0.ipaddr"
    set -l vm_ip
    if test "$ip_file" -nt "$VMCTLDIR/$vm/screen/*"
        echo "reading ip file $ip_file"
        set vm_ip (cat $ip_file)
    else
        echo 'using vmctl to find ip'
        set vm_ip (vmctl ip $vm)
    end
    echo IP: $vm_ip

    set -l ssh_conf "$VMCTLDIR/$vm/ssh_config"
    if test -f "$ssh_conf"
        sed -i '' -e "s/Hostname .*/Hostname $vm_ip/" "$ssh_conf"
    else
        echo > $ssh_conf "Host $vm
  ControlMaster auto
  ControlPath $TMPDIR/ssh-%r-%h-%p
  ForwardAgent yes
  LocalForward 8250 localhost:8250
  RemoteForward /home/%u/.gnupg/S.gpg-agent %d/.gnupg/S.gpg-agent.extra
  Hostname $vm_ip" 
    end

    ssh -F $ssh_conf $vm $argv
end
