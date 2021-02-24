shopt -s expand_aliases
alias iptables=echo

add_forward() {
  iptables -t filter -A FORWARD -o $bridge -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  iptables -t filter -A FORWARD -o $bridge -j DOCKER
  iptables -t filter -A FORWARD -i $bridge ! -o $bridge -j ACCEPT
  iptables -t filter -A FORWARD -i $bridge -o $bridge -j ACCEPT
  iptables -t filter -A DOCKER-ISOLATION-STAGE-1 -i $bridge ! -o $bridge -j DOCKER-ISOLATION-STAGE-2
  iptables -t filter -A DOCKER-ISOLATION-STAGE-2 -o $bridge -j DROP
}

add_nat() {
  iptables -t nat -A POSTROUTING -s $subnet ! -o $bridge -j MASQUERADE
  iptables -t nat -A DOCKER -i $bridge -j RETURN
}

kind_network_id=$(docker network ls |awk '$2=="kind"&&NF=1')
[ -z "$kind_network_id" ] && {
  echo "kind network id not exists"
  exit
}
bridge=br-$kind_network_id
subnet=$(docker network inspect $kind_network_id -f '{{range .IPAM.Config}}{{.Subnet}}
{{end}}' | 
  # skip ipv6
  grep -v :)
add_nat
add_forward
