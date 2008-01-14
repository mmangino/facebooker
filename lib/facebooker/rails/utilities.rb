module Facebooker
  module Rails
    class Utilities
      class << self
        def refresh_all_images(session)
          Dir.glob(File.join(RAILS_ROOT,"public","images","*.{png,jpg,gif}")).each do |img|
            refresh_image(session,img)
          end
        end
        
        def refresh_image(session,full_path)
          basename=File.basename(full_path)
          base_path=ActionController::Base.asset_host
          base_path += "/" unless base_path.ends_with?("/")
          image_path=base_path+"images/#{basename}"
          puts "refreshing: #{image_path}"
          session.server_cache.refresh_img_src(image_path)
        end
      end
    end
  end
end