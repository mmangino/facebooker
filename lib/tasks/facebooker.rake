require 'fileutils'

namespace :facebooker do

  desc "Create a basic facebooker.yml configuration file"
  task :setup => :environment do   
    facebook_config = File.join(RAILS_ROOT,"config","facebooker.yml")
    unless File.exist?(facebook_config)
      facebooker_root = File.expand_path(File.join(File.dirname(__FILE__),"..",".."))
      facebook_config_tpl = File.join(facebooker_root,"generators","facebook","templates","config","facebooker.yml")
      FileUtils.cp facebook_config_tpl, facebook_config 
      puts "Ensure 'GatewayPorts yes' is enabled in the remote development server's sshd config when using any of the facebooker:tunnel:*' rake tasks"
      puts "Configuration created in #{RAILS_ROOT}/config/facebooker.yml"
    else
      puts "#{RAILS_ROOT}/config/facebooker.yml already exists"
    end
  end
  
end