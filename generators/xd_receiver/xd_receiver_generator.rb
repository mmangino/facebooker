class XdReceiverGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.template "xd_receiver.html", "public/xd_receiver.html"
    end
  end
  
  
end