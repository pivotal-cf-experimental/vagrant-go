# -*- mode: ruby -*-
# vi: set ft=ruby :

INSTALL_DEV_TOOLS = true
CONFIGURE_GO_EXAMPLES = true

GO_SERVER_RPM = 'http://download01.thoughtworks.com/go/13.4.1/ga/go-server-13.4.1-18342.noarch.rpm'
GO_AGENT_RPM = 'http://download01.thoughtworks.com/go/13.4.1/ga/go-agent-13.4.1-18342.noarch.rpm'

GO_SERVER_IP = '10.42.42.101'
GO_SERVER_URL = 'http://127.0.0.1:8153'

ADJUST_SYSTEM = <<-HERE
sysctl -w vm.overcommit_memory=1
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf

cat >> /etc/security/limits.conf <<LIMITS
go      soft    nofile  8192
go      hard    npofile 8192
go      soft    nproc   8192
go      hard    nproc   8192
LIMITS

yum install -y java-1.6.0-openjdk-devel
export JAVA_HOME=/etc/alternatives/java_sdk_1.6.0/
echo 'export JAVA_HOME=/etc/alternatives/java_sdk_1.6.0/' > /etc/profile.d/java.sh
HERE

GO_SERVER_SETUP = <<-HERE
  set -e
  yum install -y #{ GO_SERVER_RPM }

  #{ ADJUST_SYSTEM }
  echo 'export JAVA_HOME=/etc/alternatives/java_sdk_1.6.0/' >> /etc/default/go-server

  chkconfig go-server on
  service go-server start
HERE
GO_AGENT_SETUP = <<-HERE
  set -e
  yum install -y #{ GO_AGENT_RPM }

  #{ ADJUST_SYSTEM }
  echo 'export JAVA_HOME=/etc/alternatives/java_sdk_1.6.0/' >> /etc/default/go-agent

  sed -i.bak 's/GO_SERVER=127.0.0.1/GO_SERVER=#{ GO_SERVER_IP }/g' /etc/default/go-agent

  chkconfig go-agent on
  service go-agent start 2> /dev/null  # expected exception while the server is not running
HERE

SERVER = { vm_name: :server, hostname: 'go-server', ip: GO_SERVER_IP, forward_port: 8153, go_setup: GO_SERVER_SETUP }
NODES = [
  { vm_name: :agent1, hostname: 'go-agent-1', ip: '10.42.42.201', go_setup: GO_AGENT_SETUP },
  { vm_name: :agent2, hostname: 'go-agent-2', ip: '10.42.42.202', go_setup: GO_AGENT_SETUP },
  SERVER,
]
UPGRADE_GIT = <<-HERE
  set -e
  yum install -y zlib-devel openssl-devel
  yum install -y curl-devel

  yum erase -y git

  yum install -y perl-ExtUtils-MakeMaker

  cd /tmp
  curl -O https://git-core.googlecode.com/files/git-1.9.0.tar.gz
  tar xvzf git-1.9.0.tar.gz
  cd git-1.9.0
  ./configure
  make prefix=/usr all
  make prefix=/usr install 
HERE

INSTALL_GOLANG = -<<HERE
  yum install -y golang
HERE

INSTALL_CHEF = <<-HERE
  cd /tmp
  curl -O http://pyyaml.org/download/libyaml/yaml-0.1.5.tar.gz
  tar xzvf yaml-0.1.5.tar.gz
  cd yaml-0.1.5
  ./configure --prefix=/usr
  make
  make install

  cd /tmp
  curl -O http://cache.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p484.tar.gz
  tar xzvf ruby-1.9.3-p484.tar.gz
  cd ruby-1.9.3-p484
  ./configure --prefix=/usr --enable-shared --disable-install-doc
  make
  make install

  gem install bundler --no-rdoc --no-ri
  gem install chef --no-rdoc --no-ri
HERE

GO_XML_PATH = '/etc/go/cruise-config.xml'
GO_XML_EXAMPLES_TEMPLATE = open('go_examples_template.xml').read()
GO_EXAMPLE_TEST_REPO = '/vagrant/test-repo'

GO_CONFIG_EXAMPLES = <<-HERE
set -e

mkdir -p /vagrant/results

mkdir -p #{ GO_EXAMPLE_TEST_REPO }
cd #{ GO_EXAMPLE_TEST_REPO }
git init --bare

go_ids=$( python /vagrant/update_go_config.py )

server_id=$( echo $go_ids | awk '{ print $1 }' )
agent1_uuid=$( echo $go_ids | awk '{ print $2 }' )
agent2_uuid=$( echo $go_ids | awk '{ print $3 }' )

cat > #{ GO_XML_PATH } <<XMLCONF
#{ GO_XML_EXAMPLES_TEMPLATE  }
XMLCONF

service go-server restart
HERE

Vagrant.configure('2') do |config|
  centos_version = '6.5.3'
  vagrant_centos_version = '20140116'
  config.vm.box = "centos-#{centos_version}-#{vagrant_centos_version}"
  config.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v#{centos_version}/centos65-x86_64-#{vagrant_centos_version}.box"

  config.vm.provider :virtualbox do |vb|
    vb.customize [ 'modifyvm', :id, '--memory', '2048' ]
  end

  config.cache.auto_detect = true
  config.cache.scope = :machine

  config.vm.synced_folder '.', '/vagrant', mount_options: ['dmode=777', 'fmode=777']

  NODES.each do |node|
    config.vm.define node[:vm_name] do |node_config|
      node_config.vm.provider(:virtualbox) { |vb| vb.name = node[:vm_name].to_s }

      node_config.vm.hostname = node[:hostname]
      node_config.vm.network :private_network, ip: node[:ip]
      if node[:forward_port]
        node_config.vm.network "forwarded_port", guest: node[:forward_port], host: node[:forward_port]
      end

      node_config.vm.provision :shell, inline: node[:go_setup]
    end
  end

  if CONFIGURE_GO_EXAMPLES
    config.vm.define SERVER[:vm_name] do |server_config|
      server_config.vm.provision :shell, inline: GO_CONFIG_EXAMPLES
    end
  end

  if INSTALL_DEV_TOOLS
    config.vm.provision :shell, inline: UPGRADE_GIT 
    config.vm.provision :shell, inline: INSTALL_CHEF
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = ['.', './cookbooks']
      chef.add_recipe 'vagrant-go-wrapper-cookbook'
    end
  end
end
