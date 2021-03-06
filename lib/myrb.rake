( $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')) ).uniq!
require 'myrb'
require 'fileutils'
include FileUtils

desc 'Prepares my.rb for use'
task :init => [:config] do
  config = YAML.load_file(File.expand_path(MyRB::ConfigFile))
  mkdir_p File.join(File.expand_path(config[:directory]), 'my.rb')
  puts "** my.rb will store snippets in [#{File.join(config[:directory], 'my.rb')}]"
  puts '** my.rb is ready to be used!'
end

task :config do
  mkdir_p File.expand_path(MyRB::Directory)
  next if File.file? File.expand_path(MyRB::ConfigFile)
  File.open File.expand_path(MyRB::ConfigFile), File::WRONLY|File::TRUNC|File::CREAT do |file|
    file.puts '# This config file must remain at ~/.my.rb/config, but you can change'
    file.puts '# the global snippets location with the :directory: declaration below.'
    file << "\n"
    
    file.puts({
      :name       => nil,
      :email      => nil,
      :directory  => File.join('~', '.my.rb', 'snippets')
    }.to_yaml)
  end
  puts "** Config file at [#{MyRB::ConfigFile}] created. Please edit it with the"
  puts "** correct information, and then run `my.rb init` again."
  puts "** Attempting to open the config file with $VISUAL (#{ENV['VISUAL']})..."
  system "#{ENV['VISUAL']} #{MyRB::ConfigFile}"
  exit
end

desc 'Load a new snippet into my.rb'
task :load, :path do |_, args|
  path = args[:path]
  raise ArgumentError, '** You must provide a path to load a my.rb' unless path
  m = MyRB.new_from path
  m.save
end

task :default do
  puts %x[my.rb -T].gsub(/\(.*\)\n/, '').gsub(/rake /, 'my.rb ')
end