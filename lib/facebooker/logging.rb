module Facebooker
  @@logger = nil
  def self.logger=(logger)
    @@logger = logger
  end
  def self.logger
    @@logger
  end

  module Logging
    def self.refresh_colorize_logging
      if Object.const_defined? :ActiveRecord
        @@colorize = ActiveRecord::Base.colorize_logging
      else
        @@colorize = false
      end
    end
    refresh_colorize_logging
    
    def self.colorize_logging
      @@colorize
    end
    
    @@row_even = false
    def self.log_fb_api(method, params)
      message = method # might customize later
      dump = format_fb_params(params)
      if block_given?
        result = nil
        seconds = Benchmark.realtime { result = yield }
        log_info(message, dump, seconds)
        result
      else
        log_info(message, dump)
        nil
      end
    rescue Exception => e
      # Log message and raise exception.
      # Set last_verification to 0, so that connection gets verified
      # upon reentering the request loop
      exception = "#{e.class.name}: #{e.message}: #{dump}"
      log_info(message, exception)
      raise
    end
    
    def self.format_fb_params(params)
      params.to_a.map { |kvp| "#{kvp[0]} = #{kvp[1]}" }.join(', ')
    end
    
    def self.log_info(message, dump, seconds = 0)
      return unless Facebooker.logger
      Facebooker.logger.debug format_log_entry("#{message} (#{'%f' % seconds})", dump)
    end
    
    # stolen from active record  
    def self.format_log_entry(message, dump = nil)
      if colorize_logging
        if @@row_even
          @@row_even = false
          message_color, dump_color = "4;36;1", "0;1"
        else
          @@row_even = true
          message_color, dump_color = "4;35;1", "0"
        end
  
        log_entry = "  \e[#{message_color}m#{message}\e[0m   "
        log_entry << "\e[#{dump_color}m%#{String === dump ? 's' : 'p'}\e[0m" % dump if dump
        log_entry
      else
        "%s  %s" % [message, dump]
      end
    end    
  end  
end