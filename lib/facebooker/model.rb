module Facebooker
  module Model
    class UnboundSessionException < Exception; end
    def self.included(includer)
      includer.extend ClassMethods
      includer.__send__(:attr_accessor, :session)
    end
    module ClassMethods
      def from_hash(hash)
        new(hash)
      end
      
      #
      # Declares an attribute named ::symbol:: which can be set with either an instance of ::klass::
      # or a Hash which will be used to populate a new instance of ::klass::.
      def hash_settable_accessor(symbol, klass)
        attr_reader symbol
        define_method("#{symbol}=") do |value|
          instance_variable_set("@#{symbol}", value.kind_of?(Hash) ? klass.from_hash(value) : value)
        end
      end
      
      #
      # Declares an attribute named ::symbol:: which can be set with either a list of instances of ::klass::
      # or a list of Hashes which will be used to populate a new instance of ::klass::.      
      def hash_settable_list_accessor(symbol, klass)
        attr_reader symbol
        define_method("#{symbol}=") do |list|
          instance_variable_set("@#{symbol}", list.map do |item|
            item.kind_of?(Hash) ? klass.from_hash(item) : item
          end)
        end
      end
      
    end
    
    def session
      @session || (raise UnboundSessionException, "Must bind this object to a Facebook session before querying")
    end
    
    def initialize(hash = {})
      populate_from_hash!(hash)
    end    
    def populate_from_hash!(hash)
      unless hash.empty?
        hash.each do |key, value|
          self.__send__("#{key}=", value)
        end
      end      
    end    
  end
end