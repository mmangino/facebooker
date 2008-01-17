namespace :facebooker do
  # Tunnel tasks courtesy of Christopher Haupt
  # http://www.BuildingWebApps.com
  # http://www.LearningRails.com
  namespace :tunnel do 
    desc "Create a reverse tunnel from a public server to a private \
    development server. Use tunnel.yml for parameter configuration." 
    task :start => :environment do 
      SSH_TUNNEL = YAML.load_file("#{RAILS_ROOT}/config/tunnel.yml")[RAILS_ENV] 
      public_host_username = SSH_TUNNEL['public_host_username'] 
      public_host = SSH_TUNNEL['public_host'] 
      public_port = SSH_TUNNEL['public_port'] 
      local_port = SSH_TUNNEL['local_port'] 
    
      puts "Starting tunnel #{public_host}:#{public_port} to 0.0.0.0:#{local_port}" 
      exec "ssh -nNT -g -R *:#{public_port}:0.0.0.0:#{local_port} #{public_host_username}@#{public_host} > /dev/null 2>&1 &" 
    end 
    
    desc "Create a basic tunnel.yml file"
    task :configure => :environment do   
      config = <<-EOF
      # Your callback url should be set to
      #  http://public_host:public_port
      development: 
        public_host_username:  
        public_host: 
        public_port: 3333 
        local_port: 3000
      EOF
      File.open("#{RAILS_ROOT}/config/tunnel.yml","w+") do |f|
        f.puts(config)
      end
      puts "Configuration created in #{RAILS_ROOT}/config/tunnel.yml"
    end 
    
    # Adapted from Evan Weaver's article
    # http://blog.evanweaver.com/articles/2007/07/13/developing-a-facebook-app-locally/ 
     desc "Check if reverse tunnel is running"
     task :status => :environment do
       SSH_TUNNEL = YAML.load_file("#{RAILS_ROOT}/config/tunnel.yml")[RAILS_ENV] 
       public_host_username = SSH_TUNNEL['public_host_username'] 
       public_host = SSH_TUNNEL['public_host'] 
       public_port = SSH_TUNNEL['public_port'] 

       if `ssh #{public_host} -l #{public_host_username} netstat -an | 
           egrep "tcp.*:#{public_port}.*LISTEN" | wc`.to_i > 0
         puts "Seems ok"
       else
         puts "Down"
       end
     end
    
  end
end