require 'myrb'
require 'rake'
require 'fileutils'
require 'rake/tasklib'

class MyRB
  module Rake
    
    
    # The class for a task to create your myrbs. Used as follows:
    #   MyRB::Rake::DeployTask.new
    # The default action for deploy is to copy the my.rbs to your project dir, in
    # project/snippets/<your username>/my.rb/foo.rb - you can change this path with :to
    #   MyRB::Rake::DeployTask.new do |myrbs|
    #     myrbs.each :copy, :to => 'blah'
    #   end
    # You can also apply a different task name (the default is 'deploy'), and a custom
    # deployment block to execute on each myrb during deployment.
    #   MyRB::Rake::DeployTask.new :a_different_task_name do |myrbs|
    #     myrb.each do |myrb|
    #       puts "Iterating over #{myrb}, but not doing anything with it! Hah, sucker!"
    #     end
    #   end
    class DeployTask < ::Rake::TaskLib
      # Name of deploy task. (default is :deploy)
      attr_accessor :name
      
      # Defines a new task, using the name +name+.
      def initialize(name=:deploy)
        @name = name
        each :copy # Sets default @block
        
        yield self if block_given?
        
        define
      end
      
      def define
        desc 'Deploy my.rbs' unless ::Rake.application.last_comment
        task name do
          puts "** Deploying my.rbs..."
          MyRB.loaded.each do |myrb|
            puts "-- #{myrb}.my.rb"
            @block.call myrb
          end
        end
        
        self
      end
      
      # Nothing like the traditional enumerable #each task, this is meant to
      # set the block to be run on each my.rb
      def each *args, &block
        to_do = args.shift
        args = args.inject(Hash.new) {|a,o| raise ArgumentError unless a.class == Hash; o.merge a }
        
        @block = case to_do
        when :copy
          # Copy the my.rbs to a destination my.rb folder. It's expected that
          # target_dir/ will be somehow added to the load path, so the
          # +require 'my.rb/foo' will refer to target_dir/my.rb/foo.rb
          lambda do |myrb|
            source = MyRB.expand_path(myrb)
            destination = File.join(File.expand_path(args[:to] || 'snippets'), %x[whoami].strip, 'my.rb')
            FileUtils.mkdir_p destination rescue nil
            FileUtils.cp MyRB.expand_path(myrb), File.join(destination, "#{myrb}.rb")
          end
          
        when nil
          # Nil args, so expect a custom block
          block_given? ? block : lambda {|m| nil }
        end
      end
      
    end
    
  end
end

