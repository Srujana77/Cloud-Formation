
splunk_app_install "Installing #{node['splunk']['deployment_mon_file']} -- Version: #{node['splunk']['deployment_mon_version']}" do
  action                  [:create_if_missing]
  app_file                node['splunk']['deployment_mon_file']
  app_version             node['splunk']['deployment_mon_version']
  local_templates_directory "deploy-mon-app"
  local_templates         ["app.conf.erb"]
  remove_dir_on_upgrade   "true"
end
