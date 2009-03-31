module Rack
  # This Rack middleware checks the signature of Facebook params, and
  # converts them to Ruby objects when appropiate. Also, it converts
  # the request method from the Facebook POST to the original HTTP
  # method used by the client.
  #
  # If the signature is wrong, it returns a "400 Invalid Facebook Signature".
  # 
  # Optionally, it can take a block that receives the Rack environment
  # and returns a value that evaluates to true when we want the middleware to
  # be executed for the specific request.
  #
  # == Usage
  #
  # In your config.ru:
  #
  #   require 'rack/facebook'
  #   use Rack::Facebook, "my_facebook_secret_key"
  #
  # Using a block condition:
  #
  #   use Rack::Facebook, "my_facebook_secret_key" do |env|
  #     env['REQUEST_URI'] =~ /^\/facebook_only/
  #   end
  #
  class Facebook
    def initialize(app, secret_key, &condition)
      @app = app
      @secret_key = secret_key
      @condition = condition
    end
    
    def call(env)
      if @condition.nil? || @condition.call(env)
        request = Rack::Request.new(env)
        fb_params = extract_fb_sig_params(request.POST)
        unless fb_params.empty?
          unless signature_is_valid?(fb_params, request.POST['fb_sig'])
            return Rack::Response.new(["Invalid Facebook signature"], 400).finish
          end
          env['REQUEST_METHOD'] = fb_params["request_method"] if fb_params["request_method"]
          convert_parameters!(request.POST)
        end
      end
      @app.call(env)
    end
    
    private

    def extract_fb_sig_params(params)
      params.inject({}) do |collection, (param, value)|
        collection[param.sub(/^fb_sig_/, '')] = value if param[0,7] == 'fb_sig_'
        collection
      end
    end
    
    def signature_is_valid?(fb_params, actual_sig)
      raw_string = fb_params.map{ |*args| args.join('=') }.sort.join
      expected_signature = Digest::MD5.hexdigest([raw_string, @secret_key].join)
      actual_sig == expected_signature
    end
    
    def convert_parameters!(params)
      
      params.each do |key, value|
        case key
        when 'fb_sig_added', 'fb_sig_in_canvas', 'fb_sig_in_new_facebook', 'fb_sig_position_fix', 'fb_sig_is_ajax'
          params[key] = value == "1"
        when 'fb_sig_expires', 'fb_sig_profile_update_time', 'fb_sig_time'
          params[key] = value == "0" ? nil : Time.at(value.to_f)
        when 'fb_sig_friends'
          params[key] = value.split(',')
        end
      end
    end
  end
end