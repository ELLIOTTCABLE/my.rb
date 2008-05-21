( $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')) ).uniq!
require 'my.rb'

desc 'Prepares my.rb for use'
task :init do
  
end

task :default do
  system 'my.rb -T'
end