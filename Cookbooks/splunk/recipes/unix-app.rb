
splunk_app_install "Installing #{node['splunk']['unix_app_file']} -- Version: #{node['splunk']['unix_app_version']}" do
  action                  [:create_if_missing]
  app_file                node['splunk']['unix_app_file']
  app_version             node['splunk']['unix_app_version']
  local_templates_directory "unix-app"
  local_templates         ["app.conf.erb","inputs.conf.erb"]
  remove_dir_on_upgrade   "true"
end