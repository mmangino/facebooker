require 'facebooker/parser'
module Facebooker
  class Service
    def initialize(api_base, api_path, api_key)
      @api_base = api_base
      @api_path = api_path
      @api_key = api_key
    end

    def self.active_service
      unless @active_service
        if Facebooker.use_curl?
          @active_service = Facebooker::Service::CurlService.new
        else
          @active_service = Facebooker::Service::NetHttpService.new
        end        
      end
      @active_service
    end
    
    def self.active_service=(new_service)
      @active_service = new_service
    end
    
    def self.with_service(service)
      old_service = active_service
      self.active_service = service
      begin
        yield
      ensure
        self.active_service = old_service
      end
    end
    
    
    # Process all calls to Facebook in th block asynchronously
    # nil will be returned from all calls and no results will be parsed. This is mostly useful
    # for sending large numbers of notifications or sending a lot of profile updates
    #
    # for example:
    #   User.find_in_batches(:batch_size => 200) do |users|
    #     Faceboooker::Service.with_async do
    #       users.each {|u| u.facebook_session.send_notification(...)}
    #     end
    #   end
    #
    # Note: You shouldn't make more than about 200 api calls in a with_async block
    # or you might exhaust all filehandles. 
    #
    # This functionality require the typhoeus gem
    #
    def self.with_async(&proc)
      block_with_process = Proc.new { proc.call ; process_async}
      with_service(Facebooker::Service::TyphoeusMultiService.new,&block_with_process)
    end
    
    def self.process_async
      active_service.process
    end  
    

    # TODO: support ssl 
    def post(params)
      attempt = 0
      if active_service.parse_results?
        Parser.parse(params[:method], post_form(url,params) )
      else
        post_form(url,params)
      end
    rescue Errno::ECONNRESET, EOFError
      if attempt == 0
        attempt += 1
        retry
      end
    end

    def post_form(url,params)
      active_service.post_form(url,params)
    end
    
    def post_multipart_form(url,params)
      active_service.post_multipart_form(url,params)
    end
    
    def active_service
      self.class.active_service
    end
        
    def post_file(params)
      service_url = url(params.delete(:base))
      result = post_multipart_form(service_url, params)
      Parser.parse(params[:method], result)
    end
    
    private
    def url(base = nil)
      base ||= @api_base
      URI.parse('http://'+ base + @api_path)
    end

  end
end
