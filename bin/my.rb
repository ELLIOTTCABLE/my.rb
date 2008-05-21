#!/usr/bin/env ruby
require 'fileutils'
rakefile = File.expand_path( File.join(File.dirname(__FILE__), '..', 'lib', 'myrb.rake') )

# This is SO fucking dirty, but using #!/usr/bin/env rake doesn't work correctly.
system "rake --nosearch -f #{rakefile} #{ARGV.join(' ')}"