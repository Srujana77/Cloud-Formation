
splunk_app_install "Installing #{node['splunk']['pdf_server_file']} -- Version: #{node['splunk']['pdf_server_version']}" do
  action                    [:create_if_missing]
  app_file                  node['splunk']['pdf_server_file']
  app_version               node['splunk']['pdf_server_version']
  local_templates_directory "pdf-server-app"
  local_templates           ["app.conf.erb"]
  remove_dir_on_upgrade     "true"
  case node['platform']
    when "centos","redhat","fedora"
      required_dependencies ["Xvfb","xauth","bitstream-vera-fonts"]
    when "debian","ubuntu"
      required_dependencies ["xvfb","xauth","fontconfig","libxrender1","libxinerama1"]
  end
end
