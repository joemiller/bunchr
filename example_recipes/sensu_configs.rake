Bunchr::Software.new do |t|
  t.name = 'sensu_configs'

  # build and install commands run from t.work_dir. In this case, our
  # files are located in the same dir as the Rakefile.
  t.work_dir = Dir.pwd

  t.install_commands << "rm -rf /etc/sensu"
  t.install_commands << "rm -rf /etc/init.d/sensu-*"
  t.install_commands << "rm -rf /usr/share/sensu"
  t.install_commands << "rm -rf /var/log/sensu"
  
  t.install_commands << "cp -rf ./sensu_configs/sensu /etc/sensu"
  t.install_commands << "cp -f ./sensu_configs/logrotate.d/sensu /etc/logrotate.d/sensu"

  t.install_commands << "cp -f ./sensu_configs/init.d/sensu-api /etc/init.d/sensu-api"
  t.install_commands << "cp -f ./sensu_configs/init.d/sensu-server /etc/init.d/sensu-server"
  t.install_commands << "cp -f ./sensu_configs/init.d/sensu-client /etc/init.d/sensu-client"
  t.install_commands << "cp -f ./sensu_configs/init.d/sensu-dashboard /etc/init.d/sensu-dashboard"

  t.install_commands << "mkdir -p /usr/share/sensu/upstart"
  t.install_commands << "cp -f ./sensu_configs/init/*.conf /usr/share/sensu/upstart/"

  t.install_commands << "mkdir /var/log/sensu"

  CLEAN << "/var/log/sensu"
  CLEAN << "/etc/sensu"
  CLEAN << "/etc/init.d/sensu-*"
  CLEAN << "/usr/share/sensu"
end
