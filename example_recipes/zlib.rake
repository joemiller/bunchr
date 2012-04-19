Bunchr::Software.new do |t|
  t.name = 'zlib'
  t.version = '1.2.6'

  install_prefix = "#{Bunchr.install_dir}/embedded"

  t.download_commands << "curl -O http://zlib.net/zlib-1.2.6.tar.gz"
  t.download_commands << "tar xfvz zlib-1.2.6.tar.gz"

  os   = t.ohai['os']
  arch = t.ohai['kernel']['machine']

  if os == 'darwin' && arch == 'x86_64'
    t.build_environment['LDFLAGS'] = "-R#{install_prefix}/lib -L#{install_prefix}/lib -I#{install_prefix}/include"
    t.build_environment['CFLAGS'] = "-I#{install_prefix}/include -L#{install_prefix}/lib"
  elsif os == 'linux'
    t.build_environment['LDFLAGS'] = "-Wl,-rpath #{install_prefix}/lib -L#{install_prefix}/lib -I#{install_prefix}/include"
    t.build_environment['CFLAGS'] = "-I#{install_prefix}/include -L#{install_prefix}/lib"
  end

  # gcc will error if the lib dir doesn't exist, at least on some linux platforms
  unless File.directory?("#{install_prefix}/lib")
    t.build_commands << "mkdir #{install_prefix}/lib"
  end
  
  t.build_commands << "./configure --prefix=#{install_prefix}"
  t.build_commands << "make"

  t.install_commands << "make install"

  CLEAN << install_prefix
end
