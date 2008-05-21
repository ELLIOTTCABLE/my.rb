require 'fileutils'

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

# Aaaaand we welcome to the stage, Mr. MyRB! *clapclapclap*
module MyRB
  
  # ===============
  # = As a module =
  # ===============
  def self.loaded
    $LOADED_FEATURES.select {|f| f =~ %r|^my.rb/|}.map {|f| f.gsub(%r|^my.rb/|, nil)}
  end
  
  # ==================
  # = As an instance =
  # ==================
  Variables = %w(name description categories)
  
  # The 'name' of this myrb, which must be filename-friendly
  # This myrb will be used by +require 'myrb/category/subcat/name'+
  attr_accessor :name
  
  # A short description of this myrb, for future reference/sharing.
  attr_accessor :description
  
  # The 'category path' to this myrb. An array. ['category', 'subcat'] is the
  # category path of the myrb referenced by +require 'myrb/category/subcat/name'+
  attr_accessor :categories
  
  def initialize *args, &block
    path = 
    args = args.collect(Hash.new) {|a,o| raise ArgumentError unless a.class == Hash; o.merge a }
    
    Variables.each do |arg|
      instance_variable_set(arg.to_sym, args[arg.to_sym] ? args[arg.to_sym] : nil)
    end
    
    yield self if block
    
    Variables.each do |arg|
      raise ArgumentError, "#{arg} must be defined on #{self.inspect}!" unless
        !instance_variable_get(arg.to_sym).nil?
    end
  end
  protected :name=
  protected :categories=
  
  # Creates a new MyRB from a Myrbfile/.myrb file.
  def self.new_from path, *args, &block
    categories = File.expand_path path
    categories = categories.gsub(%r|^/.*/my.rb/|, nil)
    categories = FileUtils.split_all categories
    name = categories.pop.gsub(/.rb$/, nil)
    
    description, content = MyRB.parse path
    MyRB.new(
    { :name        => name,
      :categories  => categories,
      :description => description,
      :content     => content
    }.merge(args), &block)
  end
  
  # Gets a description, and code, from a Myrbfile/.myrb file.
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
  
end

# One last request... before I die... *gaaasp*...
$LOAD_PATH.unshift File.join(File.expand_path('~'), '.myrb', 'snippets')