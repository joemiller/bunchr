Bunchr::Software.new do |t|
  t.name = 'libyaml'
  t.version = '0.1.4'

  install_prefix = "#{Bunchr.install_dir}/embedded"

  t.download_commands << "curl -O http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz"
  t.download_commands << "tar xfvz yaml-0.1.4.tar.gz"

  t.work_dir = "yaml-#{t.version}"

  t.build_commands << "./configure --prefix=#{install_prefix}"
  t.build_commands << "make"

  t.install_commands << "make install"

  CLEAN << install_prefix
end
