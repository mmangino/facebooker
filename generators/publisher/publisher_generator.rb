class PublisherGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.directory "app/models"
      m.template "publisher.rb", "app/models/#{file_name}_publisher.rb"
    end
  end
  
  
end