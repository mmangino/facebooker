class FacebookGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file 'config/facebooker.yml',            'config/facebooker.yml'
      m.file 'public/javascripts/facebooker.js', 'public/javascripts/facebooker.js'
    end
  end

  protected

  def banner
    "Usage: #{$0} facebooker"
  end
end
