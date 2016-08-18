

dedicated_search_head = true 
distributed search setup
dedicated_indexer = false
search_master = (node['splunk']['dedicated_search_master'] == node['ipaddress']) ? true : false

splunk_cmd = "#{node['splunk']['server_home']}/bin/splunk"
splunk_package_version = "splunk-#{node['splunk']['server_version']}-#{node['splunk']['server_build']}"

splunk_file = splunk_package_version + 
  case node['platform']
  when "centos","redhat","fedora"
    if node['kernel']['machine'] == "x86_64"
      "-linux-2.6-x86_64.rpm"
    else
      ".i386.rpm"
    end
  when "debian","ubuntu"
    if node['kernel']['machine'] == "x86_64"
      "-linux-2.6-amd64.deb"
    else
      "-linux-2.6-intel.deb"
    end
  end

remote_file "#{Chef::Config['file_cache_path']}/#{splunk_file}" do
  source "#{node['splunk']['server_root']}/#{node['splunk']['server_version']}/splunk/linux/#{splunk_file}"
  action :create_if_missing
end

package splunk_package_version do
  source "#{Chef::Config['file_cache_path']}/#{splunk_file}"
  case node['platform']
  when "centos","redhat","fedora"
    provider Chef::Provider::Package::Rpm
  when "debian","ubuntu"
    provider Chef::Provider::Package::Dpkg
  end
end

if node['splunk']['distributed_search'] == true

  node['splunk']['static_server_configs'] << "distsearch"
   
  if node.run_list.include?("role[#{node['splunk']['server_role']}]")
    search_indexers = search(:node, "role:#{node['splunk']['indexer_role']}")
    # Add an outputs.conf.  Search Heads should not be doing any indexing
    node['splunk']['static_server_configs'] << "outputs"
  else
    dedicated_search_head = false
  end


  if node.run_list.include?("role[#{node['splunk']['indexer_role']}]")
files over
    search_heads = search(:node, "role:#{node['splunk']['server_role']}")
    dedicated_indexer = true
  end
end


template "#{node['splunk']['server_home']}/etc/splunk-launch.conf" do
    source "server/splunk-launch.conf.erb"
    mode "0640"
    owner "root"
    group "root"
end

if node['splunk']['use_ssl'] == true && dedicated_search_head == true
  
  directory "#{node['splunk']['server_home']}/ssl" do
    owner "root"
    group "root"
    mode "0755"
    action :create
    recursive true
  end

  cookbook_file "#{node['splunk']['server_home']}/ssl/#{node['splunk']['ssl_crt']}" do
    source "ssl/#{node['splunk']['ssl_crt']}"
    mode "0755"
    owner "root"
    group "root"
  end

  cookbook_file "#{node['splunk']['server_home']}/ssl/#{node['splunk']['ssl_key']}" do
    source "ssl/#{node['splunk']['ssl_key']}"
    mode "0755"
    owner "root"
    group "root"
  end

end

if node['splunk']['ssl_forwarding'] == true

  directory "#{node['splunk']['server_home']}/etc/auth/forwarders" do
    owner "root"
    group "root"
    action :create
    recursive true
  end

  [node['splunk']['ssl_forwarding_cacert'],node['splunk']['ssl_forwarding_servercert']].each do |cert|
    cookbook_file "#{node['splunk']['server_home']}/etc/auth/forwarders/#{cert}" do
      source "ssl/forwarders/#{cert}"
      owner "root"
      group "root"
      mode "0755"
      notifies :restart, resources(:service => "splunk")
    end
  end

  # Splunk encrypted passwords always start with $1$
  ruby_block "Saving Encrypted Password (inputs.conf/outputs.conf)" do
    block do
      inputsPass = `grep -m 1 "password = " #{node['splunk']['server_home']}/etc/system/local/inputs.conf | sed 's/password = //'`
      if inputsPass.match(/^\$1\$/) && inputsPass != node['splunk']['inputsSSLPass']
        node['splunk']['inputsSSLPass'] = inputsPass
        node.save
      end

      if node['splunk']['distributed_search'] == true && dedicated_search_head == true 
          outputsPass = `grep -m 1 "sslPassword = " #{node['splunk']['server_home']}/etc/system/local/outputs.conf | sed 's/sslPassword = //'`
        
          if outputsPass.match(/^\$1\$/) && outputsPass != node['splunk']['outputsSSLPass']
            node['splunk']['outputsSSLPass'] = outputsPass
            node.save
          end
        end
    end
  end
end

execute "#{splunk_cmd} enable boot-start --accept-license --answer-yes" do
  not_if do
    File.symlink?('/etc/rc3.d/S20splunk') ||
    File.symlink?('/etc/rc3.d/S90splunk')
  end
end

splunk_password = node['splunk']['auth'].split(':')[1]
execute "Changing Admin Password" do 
  command "#{splunk_cmd} edit user admin -password #{splunk_password} -roles admin -auth admin:changeme && echo true > /opt/splunk_setup_passwd"
  not_if do
    File.exists?("/opt/splunk_setup_passwd")
  end
end

service "splunk" do
  action [ :start ]
  supports  :status => true, :start => true, :stop => true, :restart => true
end


if dedicated_indexer == true || node['splunk']['distributed_search'] == false
  execute "Enabling Receiver Port #{node['splunk']['receiver_port']}" do 
    command "#{splunk_cmd} enable listen #{node['splunk']['receiver_port']} -auth #{node['splunk']['auth']}"
    not_if "grep splunktcp:#{node['splunk']['receiver_port']} #{node['splunk']['server_home']}/etc/system/local/inputs.conf"
  end
end

if node['splunk']['scripted_auth'] == true && dedicated_search_head == true
  # Be sure to deploy the authentication template.
  node['splunk']['static_server_configs'] << "authentication"

  if !node['splunk']['data_bag_key'].empty?
    scripted_auth_creds = Chef::EncryptedDataBagItem.load(node['splunk']['scripted_auth_data_bag_group'], node['splunk']['scripted_auth_data_bag_name'], node['splunk']['data_bag_key'])
  else
    scripted_auth_creds = { "user" => "", "password" => ""}
  end

  directory "#{node['splunk']['server_home']}/#{node['splunk']['scripted_auth_directory']}" do
    recursive true
    action :create
  end
  
  node['splunk']['scripted_auth_files'].each do |auth_file|
    cookbook_file "#{node['splunk']['server_home']}/#{node['splunk']['scripted_auth_directory']}/#{auth_file}" do
      source "scripted_auth/#{auth_file}"
      owner "root"
      group "root"
      mode "0755"
      action :create
    end
  end
  
  node['splunk']['scripted_auth_templates'].each do |auth_templ|
    template "#{node['splunk']['server_home']}/#{node['splunk']['scripted_auth_directory']}/#{auth_templ}" do
      source "server/scripted_auth/#{auth_templ}.erb"
      owner "root"
      group "root"
      mode "0744"
      variables(
        :user => scripted_auth_creds['user'],
        :password => scripted_auth_creds['password']
      )
    end
  end
end

node['splunk']['static_server_configs'].each do |cfg|
  template "#{node['splunk']['server_home']}/etc/system/local/#{cfg}.conf" do
   	source "server/#{cfg}.conf.erb"
   	owner "root"
   	group "root"
   	mode "0640"
    variables(
        :search_heads => search_heads,
        :search_indexers => search_indexers,
        :dedicated_search_head => dedicated_search_head,
        :dedicated_indexer => dedicated_indexer
      )
    notifies :restart, resources(:service => "splunk")
  end
end

node['splunk']['dynamic_server_configs'].each do |cfg|
  template "#{node['splunk']['server_home']}/etc/system/local/#{cfg}.conf" do
   	source "server/#{node['splunk']['server_config_folder']}/#{cfg}.conf.erb"
   	owner "root"
   	group "root"
   	mode "0640"
    notifies :restart, resources(:service => "splunk")
   end
end


template "/etc/init.d/splunk" do
    source "server/splunk.erb"
    mode "0755"
    owner "root"
    group "root"
end

directory "#{node['splunk']['server_home']}/etc/users/admin/search/local/data/ui/views" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

if node['splunk']['deploy_dashboards'] == true
  node['splunk']['dashboards_to_deploy'].each do |dashboard|
    cookbook_file "#{node['splunk']['server_home']}/etc/users/admin/search/local/data/ui/views/#{dashboard}.xml" do
      source "dashboards/#{dashboard}.xml"
    end
  end
end

if node['splunk']['distributed_search'] == true
  if search_master == false
    execute "Linking license to search master" do
      command "#{splunk_cmd} edit licenser-localslave -master_uri 'https://#{node['splunk']['dedicated_search_master']}:8089' -auth #{node['splunk']['auth']}"
      not_if "grep \"master_uri = https://#{node['splunk']['dedicated_search_master']}:8089\" #{node['splunk']['server_home']}/etc/system/local/server.conf"
    end
  end

  if dedicated_search_head == true

    ruby_block "Splunk Server - Saving Info" do
      block do
        splunk_server_name = `grep -m 1 "serverName = " #{node['splunk']['server_home']}/etc/system/local/server.conf | sed 's/serverName = //'`
        splunk_server_name = splunk_server_name.strip
      
        if File.exists?("#{node['splunk']['server_home']}/etc/auth/distServerKeys/trusted.pem")
          trustedPem = IO.read("#{node['splunk']['server_home']}/etc/auth/distServerKeys/trusted.pem")
          if node['splunk']['trustedPem'] == nil || node['splunk']['trustedPem'] != trustedPem
            node['splunk']['trustedPem'] = trustedPem
            node.save
          end
        end

        if node['splunk']['splunkServerName'] == nil || node['splunk']['splunkServerName'] != splunk_server_name
          node['splunk']['splunkServerName'] = splunk_server_name
          node.save
        end
      end
    end
  end

  if dedicated_indexer == true
    search_heads.each do |server| 
      if server['splunk'] != nil && server['splunk']['trustedPem'] != nil && server['splunk']['splunkServerName'] != nil
        directory "#{node['splunk']['server_home']}/etc/auth/distServerKeys/#{server['splunk']['splunkServerName']}" do
          owner "root"
          group "root"
          action :create
        end

        file "#{node['splunk']['server_home']}/etc/auth/distServerKeys/#{server['splunk']['splunkServerName']}/trusted.pem" do
          owner "root"
          group "root"
          mode "0600"
          content server['splunk']['trustedPem'].strip
          action :create
          notifies :restart, resources(:service => "splunk")
        end
      end
    end
  end
Chef::Log.warn('End of distribution')
end 
