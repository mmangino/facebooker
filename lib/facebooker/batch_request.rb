module Facebooker
  class BatchRequest
    instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^respond_to\?$|^new|object_id$)/ }
    attr_reader :uri
    attr_reader :method
    class UnexecutedRequest < StandardError; end
    def initialize(params,proc)
      @exception  = nil
      @result     = nil
      @method     = params[:method]
      @uri        = params.map{|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join("&")
      @proc       = proc
    end

    def result=(result_object)
      @result = @proc.nil? ? result_object : @proc.call(result_object)
    end

    def exception_raised=(ex)
      @exception=ex
    end

    def exception_raised?
      @exception.nil? ? false : raise(@exception)
    end

    def respond_to?(name)
      super || @result.respond_to?(name)
    end

    def ===(other)
      other === @result
    end

    def method_missing(name,*args,&proc)
      if @exception
        raise @exception
      elsif @result.nil?
        raise UnexecutedRequest.new("You must execute the batch before accessing the result: #{@uri}")
      else
        @result.send(name,*args,&proc)
      end
    end
  end
end
