#!/usr/bin/ruby

require 'active_ldap'
require 'optparse'

require 'config/user'
require 'config/group'
require 'config/connect'

##
# OptionParser Object

opts = OptionParser.new do |opts|
  opts.banner = "Usage: groupdel.rb username"

  opts.separator ""
  opts.separator "Common attr:"

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

end

opts.parse!(ARGV)
   
cn = ARGV[0] || raise( "Groupname missing." )

##
# Delete user

Group.exists?(cn) || raise("Group #{cn} does not exist.")
Group.destroy(cn)
