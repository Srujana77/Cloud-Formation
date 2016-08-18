default['splunk']['forwarder_home']             = "/opt/splunkforwarder"

#Set the default role for splunk forwarders
default['splunk']['forwarder_role']             = "default"
default['splunk']['forwarder_config_folder']    = "prodlike"

# Max Transfer Rate (KB) - 0 is unlimited
default['splunk']['limits_thruput']             = "1024"

# SSL Forwarding

# http://wiki.splunk.com/index.php?title=Community:Splunk2Splunk_SSL_SelfSignedCert_NewRootCA
default['splunk']['ssl_forwarding']             = false

# Located in files/default/ssl/forwarders/
default['splunk']['ssl_forwarding_cacert']      = "myCertificate.pem"
default['splunk']['ssl_forwarding_servercert']  = "myServerCertificate.pem"
default['splunk']['ssl_forwarding_pass']        = "splunk"      # SSL Cert Password
