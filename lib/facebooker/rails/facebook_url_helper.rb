# Extends the ActionView::Helpers::UrlHelper module.  See it for details on
# the usual url helper methods: url_for, link_to, button_to, etc.  
#
# Mostly, the changes sanitize javascript into facebook javascript.  
# It sanitizes link_to solely by altering the private methods: 
# convert_options_to_javascript!, confirm_javascript_function, and 
# method_javascript_function.  For button_to, it alters button_to
# itself, as well as confirm_javascript_function.  No other methods 
# need to be changed because of Facebook javascript.
#
# For button_to and link_to, adds alternate confirm options for facebook.
# ==== Options
# * <tt>:confirm => 'question?'</tt> - This will add a JavaScript confirm
#   prompt with the question specified.
#
#   Example:
#     # Generates: <a href="http://rubyforge.org/projects/facebooker" onclick="
#     #			var dlg = new Dialog().showChoice('Please Confirm', 'Go to Facebooker?').setStyle();
#     #			var a=this;dlg.onconfirm = function() {
#     #		          document.setLocation(a.getHref()); 
#     #			}; return false;">Facebooker</a>
#     link_to("Facebooker", "http://rubyforge.org/projects/facebooker", :confirm=>"Go to Facebooker?")
#
#   Alternatively, options[:confirm] may be specified.  
#   See the Facebook page http://wiki.developers.facebook.com/index.php/FBJS.
#   These options are:
#   <tt>:title</tt>::       Specifies the title of the Facebook dialog. Default is "Please Confirm".
#   <tt>:content</tt>::       Specifies the title of the Facebook dialog. Default is "Are you sure?".
#
#   Example:
#     # Generates: <a href="http://rubyforge.org/projects/facebooker" onclick="
#     #			var dlg = new Dialog().showChoice('the page says:', 'Go to Facebooker?').setStyle();
#     #			var a=this;dlg.onconfirm = function() {
#     #		          document.setLocation(a.getHref()); 
#     #			}; return false;">Facebooker</a>
#     link_to("Facebooker", "http://rubyforge.org/projects/facebooker", :confirm=>{:title=>"the page says:", :content=>"Go to Facebooker?"})
#
#   Any other options passed are assumed to be css styles.
#   Again, see the Facebook page http://wiki.developers.facebook.com/index.php/FBJS.
#
#   Example:
#     # Generates: <a href="http://rubyforge.org/projects/facebooker" onclick="
#     #			var dlg = new Dialog().showChoice('the page says:', 'Are you sure?').setStyle({color: 'pink', width: '200px'});
#     #			var a=this;dlg.onconfirm = function() {
#     #		          document.setLocation(a.getHref()); 
#     #			}; return false;">Facebooker</a>
#     link_to("Facebooker", "http://rubyforge.org/projects/facebooker", :confirm=>{:title=>"the page says:, :color=>"pink", :width=>"200px"})
module ActionView
  module Helpers
    module UrlHelper
      # Alters one and only one line of the Rails button_to.  See below.
      def button_to_with_facebooker(name, options={}, html_options = {})
        if !respond_to?(:request_comes_from_facebook?) || !request_comes_from_facebook?
           button_to_without_facebooker(name,options,html_options)
        else
          html_options = html_options.stringify_keys
          convert_boolean_attributes!(html_options, %w( disabled ))

          method_tag = ''
          if (method = html_options.delete('method')) && %w{put delete}.include?(method.to_s)
            method_tag = tag('input', :type => 'hidden', :name => '_method', :value => method.to_s)
          end

          form_method = method.to_s == 'get' ? 'get' : 'post'
        
          request_token_tag = ''
          if form_method == 'post' && protect_against_forgery?
            request_token_tag = tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => form_authenticity_token)
          end
        
          if confirm = html_options.delete("confirm")
            # this line is the only change => html_options["onclick"] = "return #{confirm_javascript_function(confirm)}"
            html_options["onclick"] = "#{confirm_javascript_function(confirm, 'a.getForm().submit();')}return false;"
          end

          url = options.is_a?(String) ? options : self.url_for(options)
          name ||= url
 
          html_options.merge!("type" => "submit", "value" => name)

          "<form method=\"#{form_method}\" action=\"#{escape_once url}\" class=\"button-to\"><div>" +
            method_tag + tag("input", html_options) + request_token_tag + "</div></form>"
        end
      end

      alias_method_chain :button_to, :facebooker

      private

	# Altered to throw an error on :popup and sanitize the javascript
	# for Facebook.
        def convert_options_to_javascript_with_facebooker!(html_options, url ='')
          if !respond_to?(:request_comes_from_facebook?) || !request_comes_from_facebook?
            convert_options_to_javascript_without_facebooker!(html_options,url)
   	      else
            confirm, popup = html_options.delete("confirm"), html_options.delete("popup")

            method, href = html_options.delete("method"), html_options['href']

            html_options["onclick"] = case
              when popup
                raise ActionView::ActionViewError, "You can't use :popup"
              when method # or maybe (confirm and method)
                "#{method_javascript_function(method, url, href, confirm)}return false;"
              when confirm # and only confirm
                "#{confirm_javascript_function(confirm)}return false;"
              else
                html_options["onclick"]
            end
 	  end
        end

	alias_method_chain :convert_options_to_javascript!, :facebooker


	# Overrides a private method that link_to calls via convert_options_to_javascript! and
	# also, button_to calls directly.  For Facebook, confirm can be a hash of options to 
	# stylize the Facebook dialog.  Takes :title, :content, :style options.  See
	# the Facebook page http://wiki.developers.facebook.com/index.php/FBJS for valid
	# style formats like "color: 'black', background: 'white'" or like "'color','black'".
	#
	# == Examples ==
	#
	# link_to("Facebooker", "http://rubyforge.org/projects/facebooker", :confirm=>"Go to Facebooker?")
	# link_to("Facebooker", "http://rubyforge.org/projects/facebooker", :confirm=>{:title=>"the page says:, :content=>"Go to Facebooker?"})
	# link_to("Facebooker", "http://rubyforge.org/projects/facebooker", :confirm=>{:title=>"the page says:, :content=>"Go to Facebooker?", :color=>"pink"})
  def confirm_javascript_function_with_facebooker(confirm, fun = nil)
    if !respond_to?(:request_comes_from_facebook?) || !request_comes_from_facebook?
      confirm_javascript_function_without_facebooker(confirm)
    else
      if(confirm.is_a?(Hash))
        confirm_options = confirm.stringify_keys
		    title = confirm_options.delete("title") || "Please Confirm"
		    content = confirm_options.delete("content") || "Are you sure?"
		    button_confirm = confirm_options.delete("button_confirm") || "Okay"
		    button_cancel = confirm_options.delete("button_cancel") || "Cancel"
		    style = confirm_options.empty? ? "" : convert_options_to_css(confirm_options)
	    else
	      title,content,style,button_confirm,button_cancel = 'Please Confirm', confirm, "", "Okay", "Cancel"
	    end
      "var dlg = new Dialog().showChoice('#{escape_javascript(title.to_s)}','#{escape_javascript(content.to_s)}','#{escape_javascript(button_confirm.to_s)}','#{escape_javascript(button_cancel.to_s)}').setStyle(#{style});"+
	    "var a=this;dlg.onconfirm = function() { #{fun ? fun : 'document.setLocation(a.getHref());'} };"
	  end
  end

	alias_method_chain :confirm_javascript_function, :facebooker

	def convert_options_to_css(options)
	  key_pair = options.shift
	  style = "{#{key_pair[0]}: '#{key_pair[1]}'"
	  for key in options.keys
	    style << ", #{key}: '#{options[key]}'"
	  end
	  style << "}"
	end

	# Dynamically creates a form for link_to with method.  Calls confirm_javascript_function if and 
	# only if (confirm && method) for link_to
        def method_javascript_function_with_facebooker(method, url = '', href = nil, confirm = nil)
          if !respond_to?(:request_comes_from_facebook?) || !request_comes_from_facebook?
            method_javascript_function_without_facebooker(method,url,href)
 	  else
            action = (href && url.size > 0) ? "'#{url}'" : 'a.getHref()'
            submit_function =
              "var f = document.createElement('form'); f.setStyle('display','none'); " +
              "a.getParentNode().appendChild(f); f.setMethod('POST'); f.setAction(#{action});"

            unless method == :post
              submit_function << "var m = document.createElement('input'); m.setType('hidden'); "
              submit_function << "m.setName('_method'); m.setValue('#{method}'); f.appendChild(m);"
            end

            if protect_against_forgery?
              submit_function << "var s = document.createElement('input'); s.setType('hidden'); "
              submit_function << "s.setName('#{request_forgery_protection_token}'); s.setValue('#{escape_javascript form_authenticity_token}'); f.appendChild(s);"
            end
            submit_function << "f.submit();"

	    if(confirm)
	      confirm_javascript_function(confirm, submit_function)
  	    else
	      "var a=this;" + submit_function
 	    end
          end
	end

	alias_method_chain :method_javascript_function, :facebooker

    end
  end
end

