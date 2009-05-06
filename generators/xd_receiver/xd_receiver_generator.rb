class XdReceiverGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.template "xd_receiver.html",     "public/xd_receiver.html"
      m.template "xd_receiver_ssl.html", "public/xd_receiver_ssl.html"
    end
  end
  
  
end
