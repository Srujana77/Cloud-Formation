maintainer       "Srujana"
maintainer_email "srujanan15@gmail.com"
license          "Apache 2.0"
description      "Installs/Configures a Splunk Server, Forwarders, and Apps"
version          "0.0.1"
%w{redhat centos fedora debian ubuntu}.each do |os|
  supports os
end
