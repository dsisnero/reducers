require 'aruba/cucumber'
require 'tmpdir'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Before do
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
  @new_home = Dir.mktmpdir("HOME")
  @original_home = ENV['HOME']
  ENV['HOME'] = @new_home
end

After do
  ENV['RUBYLIB'] = @original_rubylib
  ENV['HOME'] = @original_home
  FileUtils.remove_entry_secure @new_home
end
