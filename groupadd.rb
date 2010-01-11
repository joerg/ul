#!/usr/bin/ruby

require 'active_ldap'
require 'optparse'

require 'config/user'
require 'config/group'
require 'config/connect'

##
# Attr

attr = Hash.new
#attr["gid_number"] = false # -g, --gid
#attr["members"] = false # 

modify = false # -m, --modify

##
# OptionParser Object

opts = OptionParser.new do |opts|
  opts.banner = "Usage: groupadd.rb [attr] username"

  opts.separator ""
  opts.separator "Specific attr:"

  opts.on("-g", "--gid GID",
          "GID Number, defaults highest existing gid+1") do |gid|
    attr["gid_number"] = gid
  end

  opts.on("-M", "--members MEMBER1,MEMBER2,...",
          "Add MEMBER1, MEMBER22, ... to group") do |members|
    attr["members"] = members.split(',')
  end

  opts.on("-m", "--modify",
          "Modify existing group") do |mod|
    modify = true
  end

  opts.separator ""
  opts.separator "Common attr:"

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

end

opts.parse!(ARGV)
   
attr["cn"] = ARGV[0] || raise( "Username missing." )

##
# Modify existing group?

if modify

  Group.exists?(attr["cn"]) || raise("Group #{attr['cn']} does not exist.")

  group = Group.find(attr["cn"])

else
  
  !Group.exists?(attr["cn"]) || raise("Group #{attr["cn"]} already exists.")

  group = Group.new(attr["cn"])
  
  unless attr["gid_number"]
    attr["gid_number"] = 9999
    Group.find(:all, :attribute => 'gidNumber').collect { |group| group.gid_Number>attr["gid_number"] ? attr["gid_number"]=group.gid_Number : false }
    attr["gid_number"]+=1
  end

end

if attr["members"]
  tmp = Array.new
  attr["members"].each { |member| tmp << User.find(member) }
  attr["members"] = tmp
end

attr.each do |key, val|
  if key == "members"
    group.members = val
  else
    group[key] = val
  end
end

unless group.save
  puts "failed"
  puts group.errors.full_messages
  exit 1
end
