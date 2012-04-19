Bunchr::Software.new do |t|
  t.name = 'sensu_dashboard'

  install_prefix = "#{Bunchr.install_dir}"
  # use the gem installed by the ruby.rake recipe in <Bunchr.install_dir>/embedded/bin
  gem_bin = "#{install_prefix}/embedded/bin/gem"

  t.download_commands << "git clone git://github.com/sensu/sensu-dashboard.git"

  t.work_dir = 'sensu-dashboard'
  
  t.build_commands << "rm -f sensu-dashboard-*.gem"
  t.build_commands << "#{gem_bin} build sensu-dashboard.gemspec"

  t.install_commands << "#{gem_bin} install --no-ri --no-rdoc \
                        sensu-dashboard-*.gem"
end