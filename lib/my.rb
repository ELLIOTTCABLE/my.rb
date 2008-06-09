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
  
  def self.expand_path myrb_path
    File.expand_path(File.join(my.rb.config[:directory], 'my.rb', "#{myrb_path}.rb"))
  end
  
  # ==================
  # = As an instance =
  # ==================
  Variables = %w(name categories content)
  
  # The 'name' of this my.rb, which must be filename-friendly
  # This my.rb will be used by +require 'my.rb/category/subcat/name'+
  attr_accessor :name
  
  # The 'category path' to this my.rb. An array. ['category', 'subcat'] is the
  # category path of the my.rb referenced by +require 'my.rb/category/subcat/name'+
  attr_accessor :categories
  
  def initialize *args, &block
    args = args.inject(Hash.new) {|a,o| raise ArgumentError unless a.class == Hash; o.merge a }
    
    Variables.each do |arg|
      instance_variable_set(('@' + arg).to_sym, args[arg.to_sym] ? args[arg.to_sym] : nil)
    end
    
    yield self if block_given?
    
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
    categories = path.match(%r!#{my.rb.config[:directory]}!) ? File.split_all(path.gsub(%r!^#{my.rb.config[:directory]}!, '')) : []
    name = File.basename(path).gsub(%r!(\.my)?\.rb$!, '')
    
    content = File.open(path, File::RDONLY) {|file| file.read}
    
    my.rb.new(
    { :name        => name,
      :categories  => categories,
      :content     => content
    }.merge(args), &block)
  end
  
  # Saves a my.rb out to a .my.rb file in the my.rb dir, or an optional destination
  # Takes :overwrite, :base (base path), and :to (direct path, overrides :base)
  def save *args
    args = args.inject(Hash.new) {|a,o| raise ArgumentError unless a.class == Hash; o.merge a }
    base = args[:base]  || my.rb.config[:directory]
    path = args[:to]    || File.expand_path(File.join(*[base, 'my.rb', @categories, "#{@name}.rb"].flatten))
    if File.file?(path) && !args[:overwrite]
      raise "** my.rb #{@name} exists at [#{path}] already! Pass :overwrite => true if you wish to overwrite it."
    end
    File.open path, File::RDWR|File::TRUNC|File::CREAT do |file|
      file.puts @content
      file.close
    end
    self
  end
  
end

# One last request... before I die... *gaaasp*...
begin
  $LOAD_PATH.unshift File.expand_path(my.rb.config[:directory])
rescue RuntimeError => e
  puts e
end