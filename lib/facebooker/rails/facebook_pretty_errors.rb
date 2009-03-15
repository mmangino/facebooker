class ActionController::Base
  def rescues_path_with_facebooker(template_name)
    t = "#{RAILS_ROOT}/vendor/plugins/facebooker/templates/#{template_name}.erb"
    if pretty_facebook_errors? && File.exist?(t)
      t
    else
      rescues_path_without_facebooker(template_name)
    end
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
