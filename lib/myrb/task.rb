require 'rubygems'
require 'rake'
require 'fileutils'
require 'rake/tasklib'

class MyRB
  module Rake

    class DeployTask < ::Rake::TaskLib
      # Name of deploy task. (default is :deploy)
      attr_accessor :name

      # Array of directories to be added to $LOAD_PATH before running.
      attr_accessor :libs

      # Defines a new task, using the name +name+.
      def initialize(name=:deploy)
        @name = name
        @libs = ['my cool lib dir']

        yield self if block_given?
        define
      end

      def define
        spec_script = File.expand_path(File.dirname(__FILE__) + '/../../../bin/spec')

        lib_path = libs.join(File::PATH_SEPARATOR)
        
        unless ::Rake.application.last_comment
          desc 'Deploy my.rbs'
        end
        task name do
          puts "** Deploying my.rbs..."
          my.rb.loaded.each do |myrb|
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
            destination = File.expand_path(args[:to] || FileUtils.pwd)
            cp my.rb.expand_path myrb, File.join(path, 'my.rb', myrb, '.rb')
          end
          
        when nil
          # Nil args, so expect a custom block
          block
        end
      end
      
    end
    
  end
end

