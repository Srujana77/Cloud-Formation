
# Required App for SoS

splunk_app_install "Installing #{node['splunk']['sideview_file']} -- Version: #{node['splunk']['sideview_version']}" do
  action                  [:create_if_missing]
  app_file                node['splunk']['sideview_file']
  app_version             node['splunk']['sideview_version']
  remove_dir_on_upgrade   "true"
end

# SoS

splunk_app_install "Installing #{node['splunk']['splunk_sos_file']} -- Version: #{node['splunk']['splunk_sos_version']}" do
  action                  [:create_if_missing]
  app_file                node['splunk']['splunk_sos_file']
  app_version             node['splunk']['splunk_sos_version']
  remove_dir_on_upgrade   "true"
end
