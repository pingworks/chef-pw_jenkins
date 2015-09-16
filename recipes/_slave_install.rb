# jenkins slave:
swarm_jar = node['ws-jenkins']['slave']['swarm_jar']
swarm_url = "#{node['ws-jenkins']['slave']['swarm_base_url']}/#{node['ws-jenkins']['slave']['swarm_jar']}"
slave_home = node['ws-jenkins']['slave']['home']
slave_shell = node['ws-jenkins']['slave']['shell']
username = 'ws-jenkins'

# setup jenkins user and home
user username do
  home slave_home
  shell slave_shell
  manage_home true
end

directory slave_home do
  owner username
end

# install swarm jar
remote_file "#{slave_home}/#{swarm_jar}" do
  source swarm_url
  headers 'Host' => URI.parse(source.first).host
  action :create_if_missing
  notifies :restart, 'service[jenkins-swarm-slave]', :delayed
end

link "#{slave_home}/swarm-slave.jar" do
  to "#{slave_home}/#{swarm_jar}"
end

# install init.d and defaults file
template '/etc/init.d/jenkins-swarm-slave' do
  source 'slave_init_script.erb'
  mode '755'
  notifies :restart, 'service[jenkins-swarm-slave]', :delayed
end

template '/etc/default/jenkins-swarm-slave' do
  if node['ws-jenkins']['slave']['name'] == '' && node['base']['cname'] != ''
    node.default['ws-jenkins']['slave']['name'] = node['base']['cname']
  end
  source 'slave_default_file.erb'
  mode '0644'
  notifies :restart, 'service[jenkins-swarm-slave]', :delayed
end

# configure log dir
directory '/var/log/jenkins' do
  owner username
end