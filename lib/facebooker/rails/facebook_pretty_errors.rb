class ActionController::Base
  def rescues_path_with_facebooker(template_name)
    if pretty_facebook_errors?
      t = "#{RAILS_ROOT}/vendor/plugins/facebooker/templates/#{template_name}.erb"
      template_name = t if File.exist?(t)
    end
    rescues_path_without_facebooker(template_name)
  end
  alias_method_chain :rescues_path, :facebooker

  def response_code_for_rescue_with_facebooker(exception)
    pretty_facebook_errors? ? 200 : response_code_for_rescue_without_facebooker(exception)
  end
  alias_method_chain :response_code_for_rescue, :facebooker
  
  
  def pretty_facebook_errors?
    Facebooker.facebooker_config['pretty_errors'] ||
      (Facebooker.facebooker_config['pretty_errors'].nil? && RAILS_ENV=="development")
  end
end
