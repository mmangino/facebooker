class PublisherGenerator < Rails::Generator::NamedBase
  def manifest
    puts banner
    exit(1)
  end
  
  def banner
    <<-EOM
    This generator has been renamed to facebook_publisher    
    please run:  #{$0} facebook_publisher
    EOM
  end
  
end