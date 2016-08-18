
splunk_app_install "Installing Pulse for AWS Cloudwatch" do
   action                  [:create_if_missing]
   app_file                node['splunk']['pulse_app_file']
   app_version             node['splunk']['pulse_app_version']
   remove_dir_on_upgrade   "true"
end

remote_file "Grabbing boto-#{node['splunk']['boto_version']}.tar.gz" do
   source "#{node['splunk']['boto_remote_location']}/boto-#{node['splunk']['boto_version']}.tar.gz"
   path "#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/pymodules/boto-#{node['splunk']['boto_version']}.tar.gz"
   action [:create_if_missing]
end

remote_file "Grabbing python-dateutil-#{node['splunk']['dateutil_version']}.tar.gz" do 
   source "#{node['splunk']['dateutil_remote_location']}/python-dateutil-#{node['splunk']['dateutil_version']}.tar.gz"
   path "#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/pymodules/python-dateutil-#{node['splunk']['dateutil_version']}.tar.gz"
   action [:create_if_missing]
end

if !File.directory?("#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/bin/boto") 

  execute "Extracting boto-#{node['splunk']['boto_version']}.tar.gz" do
    command "tar zxvf #{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/pymodules/boto-#{node['splunk']['boto_version']}.tar.gz"
    cwd "#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/pymodules"
  end

  link "Linking boto to pulse_for_aws_cloudwatch/bin" do
    to "#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/pymodules/boto-#{node['splunk']['boto_version']}/boto"
    target_file "#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/bin/boto"
  end
 
end

if !File.directory?("#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/bin/dateutil") 

  execute "Extracting dateutil-1.5.tar.gz" do
    command "tar zxvf #{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/pymodules/python-dateutil-#{node['splunk']['dateutil_version']}.tar.gz"
    cwd "#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/pymodules"
  end

  link "Linking dateutils to pulse_for_aws_cloudwatch/bin" do
    to "#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/pymodules/python-dateutil-#{node['splunk']['dateutil_version']}/dateutil"
    target_file "#{node['splunk']['server_home']}/etc/apps/pulse_for_aws_cloudwatch/bin/dateutil"
  end
 
end