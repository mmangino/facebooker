namespace :facebooker do
  # Tunnel tasks courtesy of Christopher Haupt
  # http://www.BuildingWebApps.com
  # http://www.LearningRails.com
  namespace :tunnel do 
    desc "Create a reverse tunnel from a public server to a private \
    development server." 
    task :start => :environment do  
      public_host_username = FACEBOOKER['tunnel']['public_host_username'] 
      public_host = FACEBOOKER['tunnel']['public_host'] 
      public_port = FACEBOOKER['tunnel']['public_port'] 
      local_port = FACEBOOKER['tunnel']['local_port'] 
    
      puts "Starting tunnel #{public_host}:#{public_port} to 0.0.0.0:#{local_port}" 
      exec "ssh -nNT -g -R *:#{public_port}:0.0.0.0:#{local_port} #{public_host_username}@#{public_host} > /dev/null 2>&1 &" 
    end 
    
    # Adapted from Evan Weaver's article: http://blog.evanweaver.com/articles/2007/07/13/developing-a-facebook-app-locally/ 
     desc "Check if reverse tunnel is running"
     task :status => :environment do
       public_host_username = FACEBOOKER['tunnel']['public_host_username'] 
       public_host = FACEBOOKER['tunnel']['public_host'] 
       public_port = FACEBOOKER['tunnel']['public_port'] 

       if `ssh #{public_host} -l #{public_host_username} netstat -an | 
           egrep "tcp.*:#{public_port}.*LISTEN" | wc`.to_i > 0
         puts "Seems ok"
       else
         puts "Down"
       end
     end
    
  end
end