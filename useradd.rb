#!/usr/bin/ruby

require 'active_ldap'
require 'optparse'

require 'config/user'
require 'config/group'
require 'config/connect'

##
# Attr

attr = Hash.new
#attr["uid"] = false
#attr["gid_number"] = false # -g, --gid
#attr["uid_number"] = false # -u, --uid
#attr["groups"] = false # -G, --groups
#attr["home_directory"] = false # -d, --home
#attr["login_shell"] = false # -s, --shell
#attr["given_name"] = false # -f, --first
#attr["sn"] = false # -l, --last
#attr["cn"] = false # automatically created

modify = false # -m, --modify

##
# OptionParser Object

opts = OptionParser.new do |opts|
  opts.banner = "Usage: useradd.rb [attr] username"

  opts.separator ""
  opts.separator "Specific attr:"

  opts.on("-g", "--gid GID",
          "GID Number, defaults to 100") do |gid|
    attr["gid_number"] = gid
  end

  opts.on("-u", "--uid UID",
          "UID Number, defaults to highest existing uid+1") do |uid|
    attr["uid_number"] = uid
  end

  opts.on("-G", "--groups GROUP1,GROUP2,...",
          "Add user to GROUP1, GROUP2, ...") do |groups|
    attr["groups"] = groups.split(',')
  end

  opts.on("-d", "--home HOME",
          "Set home folder, defaults to /home/NAME") do |home|
    attr["home_directory"] = home
  end

  opts.on("-s", "--shell SHELL",
          "Set shell of user, defaults to /bin/bash") do |shell|
    attr["login_shell"] = shell
  end

  opts.on("-f", "--first FIRST",
          "Set first name") do |first|
    attr["given_name"] = first
  end

  opts.on("-l", "--last SURNAME",
          "Set surname") do |last|
    attr["sn"] = last
  end

  opts.on("-m", "--modify",
          "Modify existing user") do |mod|
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
   
attr["uid"] = ARGV[0] || raise( "Username missing." )

##
# Checks for name and uid
# create default home if not given

if modify

  User.exists?(attr["uid"]) || raise("User #{attr['uid']} does not exist.")
  user = User.find(attr["uid"])

else
  ##
  # Default values following here

  if User.exists?(attr["uid"])
    $stderr.puts("User #{attr['uid']} already exists.")
    exit 1
  end

  attr["gid_number"] = 100 unless attr["gid_number"]

  # Get highest existing uid + 1, start at 999 (+1)
  if !attr["uid_number"]
    attr["uid_number"] = 999
    User.find(:all, :attribute => 'uidNumber').collect { |user| user.uid_Number>attr["uid_number"] ? attr["uid_number"]=user.uid_Number : false }
    attr["uid_number"]+=1
  end

  attr["home_directory"] = "/home/#{attr['uid']}" unless attr["home_directory"]
  attr["login_shell"] = "/bin/bash" unless attr["login_shell"]

  user = User.new(attr["uid"])

end

##
# Things that are always needed

# Add failure notice here if group can not be found
if attr["groups"]
  tmp = Array.new
  attr["groups"].each { |grp| tmp << Group.find(grp) }
  attr["groups"] = tmp
end

# Very unRubyish. Make this a lot prettyer for release!
if attr["given_name"] || attr["sn"]
  attr["given_name"] = user.given_name unless attr["given_name"]
  attr["sn"] = user.sn unless attr["sn"]
  ( attr["given_name"] && attr["sn"] ) ? delimiter = " " : delimiter = ""

  attr["cn"] = attr["given_name"] + delimiter + attr["sn"]
end

##
# Create user

def mod_user(user, attributes)

  # I am sure this could be done better!
  attributes.each do |key, val|
      if key != "groups"
        user[key] = val
      else
        user.groups = val
      end
  end

  return user

end

mod_user(user,attr)

#puts user.to_ldif

unless user.save
  puts "User creation failed"
  puts user.errors.full_messages
  exit 1
end
