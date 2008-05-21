( $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')) ).uniq!
require 'my.rb'
require 'fileutils'
include FileUtils

desc 'Prepares my.rb for use'
task :init => [:config] do
  config = YAML.load_file(File.expand_path(my.rb::ConfigFile))
  mkdir_p File.join(File.expand_path(config[:directory]), 'my.rb')
  puts "** my.rb will store snippets in [#{File.join(config[:directory], 'my.rb')}]"
  puts '** my.rb is ready to be used!'
end

task :config do
  mkdir_p File.expand_path(my.rb::Directory)
  next if File.file? File.expand_path(my.rb::ConfigFile)
  File.open File.expand_path(my.rb::ConfigFile), File::WRONLY|File::TRUNC|File::CREAT do |file|
    file.puts '# This config file must remain at ~/.my.rb/config, but you can change'
    file.puts '# the global snippets location with the :directory: declaration below.'
    file << "\n"
    
    file.puts({
      :name       => nil,
      :email      => nil,
      :directory  => File.join('~', '.my.rb', 'snippets')
    }.to_yaml)
  end
  puts "** Config file at [#{my.rb::ConfigFile}] created. Please edit it with the"
  puts "** correct information, and then run `my.rb init` again."
  puts "** Attempting to open the config file with $VISUAL (#{ENV['VISUAL']})..."
  system "#{ENV['VISUAL']} #{my.rb::ConfigFile}"
  exit
end

task :default do
  system 'my.rb -T'
end