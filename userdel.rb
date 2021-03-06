#!/usr/bin/ruby

require 'active_ldap'
require 'optparse'

require 'config/user'
require 'config/group'
require 'config/connect'

##
# OptionParser Object

opts = OptionParser.new do |opts|
opts.banner = "Usage: userdel.rb username"

  opts.separator ""
  opts.separator "Common attr:"

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

end

opts.parse!(ARGV)
   
uid = ARGV[0] || raise( "Username missing." )

##
# Delete user

User.exists?(uid) || raise("User #{uid} does not exist.")
User.destroy(uid)
