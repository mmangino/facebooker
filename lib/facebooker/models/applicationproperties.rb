module Facebooker
  
  # application_name  string   The name of your application.  
  # callback_url  string   Your application's callback URL. The callback URL cannot be longer than 100 characters.  
  # post_install_url  string   The URL where a user gets redirected after installing your application. The post-install URL cannot be longer than 100 characters. 
  # edit_url  string    
  # dashboard_url string    
  # uninstall_url string   The URL where a user gets redirected after removing your application.  
  # ip_list string   For Web-based applications, these are the IP addresses of your servers that can access Facebook's servers and serve information to your application. 
  # email string   The email address associated with the application; the email address Facebook uses to contact you about your application. (default value is your Facebook email address.)  
  # description string   The description of your application. 
  # use_iframe  bool   Indicates whether you render your application with FBML (0) or in an iframe (1). (default value is 1)  
  # desktop bool   Indicates whether your application is Web-based (0) or gets installed on a user's desktop (1). (default value is 1)  
  # is_mobile bool   Indicates whether your application can run on a mobile device (1) or not (0). (default value is 1) 
  # default_fbml  string   The default FBML code that appears in the user's profile box when he or she adds your application. 
  # default_column  bool   Indicates whether your application appears in the wide (1) or narrow (0) column of a user's Facebook profile. (default value is 1) 
  # message_url string   For applications that can create attachments, this is the URL where you store the attachment's content.  
  # message_action  string   For applications that can create attachments, this is the label for the action that creates the attachment. It cannot be more than 20 characters.  
  # about_url string   This is the URL to your application's About page. About pages are now Facebook Pages.  
  # private_install bool   Indicates whether you want to disable (1) or enable (0) News Feed and Mini-Feed stories when a user installs your application. (default value is 1)  
  # installable bool   Indicates whether a user can (1) or cannot (0) install your application. (default value is 1)  
  # privacy_url string   The URL to your application's privacy terms. 
  # help_url  string   The URL to your application's help page. 
  # see_all_url string    
  # tos_url string   The URL to your application's Terms of Service.  
  # dev_mode  bool   Indicates whether developer mode is enabled (1) or disabled (0). Only developers can install applications in developer mode. (default value is 1)  
  # preload_fql string   A preloaded FQL query.
  class ApplicationProperties
    include Model
    FIELDS = [ :application_name, :callback_url, :post_install_url, :edit_url, :dashboard_url,
               :uninstall_url, :ip_list, :email, :description, :use_iframe, :desktop, :is_mobile,
               :default_fbml, :default_column, :message_url, :message_action, :about_url,
               :private_install, :installable, :privacy_url, :help_url, :see_all_url, :tos_url,
               :dev_mode, :preload_fql, :icon_url, :canvas_name, :logo_url, :connect_logo_url ]
    
    attr_accessor(*FIELDS)
         
  end
end
