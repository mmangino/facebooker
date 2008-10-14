require 'fileutils'

namespace :facebooker do

  desc "Create a basic facebooker.yml configuration file"
  task :setup => :environment do   
    facebook_config = File.join(RAILS_ROOT,"config","facebooker.yml")
    unless File.exist?(facebook_config)
      FileUtils.cp File.join(RAILS_ROOT,"vendor", "plugins", "facebooker", "facebooker.yml.tpl"), facebook_config 
      puts "Ensure 'GatewayPorts yes' is enabled in the remote development server's sshd config when using any of the facebooker:tunnel:*' rake tasks"
      puts "Configuration created in #{RAILS_ROOT}/config/facebooker.yml"
    else
      puts "#{RAILS_ROOT}/config/facebooker.yml already exists"
    end
  end 
        
end

