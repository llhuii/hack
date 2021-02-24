# just to use docker official script
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
exit 0

# helper for install docker
# ubuntu https://docs.docker.com/install/linux/docker-ce/ubuntu/
# centos https://docs.docker.com/install/linux/docker-ce/centos/
get_release()
{
  eval "$(sed 's/^[A-Za-z]/OS_&/' /etc/os-release)"
  if test $OS_ID = rhel; then
    # translate redhat into centos
    OS_ID=centos
    # get the major number of OS_VERSION_ID
    OS_VERSION_ID=$(echo $OS_VERSION_ID | cut -d. -f1)
  fi
}

centos()
{
  # https://docs.docker.com/engine/install/centos/
  yum install -y yum-utils \
    device-mapper-persistent-data \
    lvm2

  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install docker-ce docker-ce-cli containerd.io -y
}

ubuntu()
{
  # https://docs.docker.com/engine/install/ubuntu/
  apt-get update
  apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  apt-key fingerprint 0EBFCD88
  add-apt-repository \
    "deb [arch=$(uname -m|sed '
         s/x86_64/amd64/
         s/aarch64/arm64/
         s/armv7.*/armhf/
         s/armv8.*/arm64/
       ')] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs)  stable"
  apt-get update -y
  apt-get install docker-ce docker-ce-cli containerd.io -y

}

set_nonroot() {
	[[ $(id -u) = 0 ]] && return

	usermod -aG docker $USER; newgrp docker
}

OS_ID=""
get_release
$OS_ID

set_nonroot

systemctl enable docker
systemctl start docker

docker run hello-world
