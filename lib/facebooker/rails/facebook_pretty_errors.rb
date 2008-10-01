if Facebooker.facebooker_config['pretty_errors'] || (Facebooker.facebooker_config['pretty_errors'].nil? && RAILS_ENV=="development")
  class ActionController::Base
    def rescues_path_with_facebooker(template_name)
      t="#{RAILS_ROOT}/vendor/plugins/facebooker/templates/#{template_name}.erb"
      File.exist?(t) ? t : rescues_path_without_facebooker(template_name)
    end

    alias_method_chain :rescues_path,:facebooker

    def response_code_for_rescue(exception)
      200
    end
  end
end