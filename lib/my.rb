require 'yaml'
require 'myrb/core_ext'

# Allows calling MyRB as +my.rb+ or +My.RB+, because I'm a lazy, semantic fucker - heh
module Kernel
  protected # Don't touch me, you drink!
  def my; My; end
  module My
    class <<self
      def rb; ::MyRB; end
      alias_method :RB, :rb
    end
  end
end

# Aaaaand we welcome to the stage, Mr. My.RB! *clapclapclap*
class MyRB
  Directory = File.join '~', '.my.rb'
  ConfigFile = File.join Directory, 'config'
  @@config = nil
  
  # ===============
  # = As a module =
  # ===============
  def self.loaded
    $LOADED_FEATURES.select {|f| f =~ %r|^my.rb/|}.map {|f| f.gsub(%r!(^my\.rb/|(\.my)?\.rb$)!, '')}
  end
  
  def self.config
    raise RuntimeError, '** You need to run `my.rb init` before you can use my.rb!' unless
      File.directory?(File.expand_path(Directory)) && File.file?(File.expand_path(ConfigFile))
    return @@config unless @@config.nil?
    @@config = ::YAML::load_file File.expand_path(ConfigFile)
  end
  
  def self.save_config
    File.open File.expand_path(Config), File::WRONLY|File::TRUNC|File::CREAT do |file|
      ::YAML::dump my.rb.config
    end
  end
  
  # ==================
  # = As an instance =
  # ==================
  Variables = %w(name description categories)
  
  # The 'name' of this my.rb, which must be filename-friendly
  # This my.rb will be used by +require 'my.rb/category/subcat/name'+
  attr_accessor :name
  
  # A short description of this my.rb, for future reference/sharing.
  attr_accessor :description
  
  # The 'category path' to this my.rb. An array. ['category', 'subcat'] is the
  # category path of the my.rb referenced by +require 'my.rb/category/subcat/name'+
  attr_accessor :categories
  
  def initialize *args, &block
    args = args.inject(Hash.new) {|a,o| raise ArgumentError unless a.class == Hash; o.merge a }
    
    Variables.each do |arg|
      instance_variable_set(('@' + arg).to_sym, args[arg.to_sym] ? args[arg.to_sym] : nil)
    end
    
    yield self if block
    
    Variables.each do |arg|
      raise ArgumentError, "#{arg} must be defined on #{self.inspect}!" unless
        !instance_variable_get(('@' + arg).to_sym).nil?
    end
  end
  protected :name=
  protected :categories=
  
  # Creates a new my.rb from a Myrbfile/.my.rb file.
  def self.new_from path, *args, &block
    args = args.inject(Hash.new) {|a,o| raise ArgumentError unless a.class == Hash; o.merge a }
    path = File.expand_path path
    categories = path.match(%r|^/.*/my\.rb/|) ? File.split_all(path.gsub(%r|^/.*/my\.rb/|, '')) : []
    name = File.basename(path).gsub(/(\.my)?\.rb$/, '')
    
    description, content = my.rb.parse path
    my.rb.new(
    { :name        => name,
      :categories  => categories,
      :description => description,
      :content     => content
    }.merge(args), &block)
  end
  
  # Gets a description, and code, from a Myrbfile/.my.rb file.
  def self.parse path
    File.open path, File::RDONLY do |file|
      snippet = file.read
      match = snippet.match /(^(?:\s*#[^\n]*\n)*)[\s\n]*(.*)/m
      comment = match[1]
      content = match[2]
      
      # Gets rid of all line returns and comment hashes, and turns it into a single sentance.
      description = comment.gsub(/(^\s*#\s|\s*\n\s*#\s)/, ' ').strip
      [description, content]
    end
  end
  
  # Saves a my.rb out to a .my.rb file in the my.rb dir
  def save *args
    args = args.inject(Hash.new) {|a,o| raise ArgumentError unless a.class == Hash; o.merge a }
    path = File.expand_path File.join(my.rb.config[:directory], 'my.rb', @categories, "#{@name}.rb")
    if File.file? path
      raise "** my.rb #{@name} exists at [#{path}] already! Pass :overwrite => true if you wish to overwrite it."
    end
    File.open path, File::RDWR|File::TRUNC|File::CREAT do |file|
      file.puts @description.gsub /^/, "# "
      file << "\n"
      file.puts @content
      file.close
    end
    self
  end
  
end

# One last request... before I die... *gaaasp*...
begin
  $LOAD_PATH.unshift File.join(my.rb.config[:directory])
rescue RuntimeError => e
  puts e
end