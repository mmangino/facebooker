module Facebooker
  ##
  # helper methods primarily supporting the management of Ruby objects which are populatable via Hashes.
  # Since most Facebook API calls accept and return hashes of data (as XML), the Model module allows us to
  # directly populate a model's attributes given a Hash with matching key names.
  module Model
    class UnboundSessionException < Exception; end
    def self.included(includer)
      includer.extend ClassMethods
      includer.__send__(:attr_writer, :session)
      includer.__send__(:attr_reader, :anonymous_fields)
    end
    module ClassMethods
      ##
      # Instantiate a new instance of the class into which we are included and populate that instance's
      # attributes given the provided Hash.  Key names in the Hash should map to attribute names on the model.
      def from_hash(hash)
        instance = new(hash)
        yield instance if block_given?
        instance
      end

      ##
      # Create a standard attr_writer and a populating_attr_reader
      def populating_attr_accessor(*symbols)
        attr_writer(*symbols)
        populating_attr_reader(*symbols)
      end

      ##
      # Create a reader that will attempt to populate the model if it has not already been populated
      def populating_attr_reader(*symbols)
        symbols.each do |symbol|
          define_method(symbol) do
            populate unless populated?
            instance_variable_get("@#{symbol}")
          end
        end
      end
      
      def populating_hash_settable_accessor(symbol, klass)
        populating_attr_reader symbol
        hash_settable_writer(symbol, klass)
      end
        
      def populating_hash_settable_list_accessor(symbol, klass)
        populating_attr_reader symbol
        hash_settable_list_writer(symbol, klass)
      end
      
      #
      # Declares an attribute named ::symbol:: which can be set with either an instance of ::klass::
      # or a Hash which will be used to populate a new instance of ::klass::.
      def hash_settable_accessor(symbol, klass)
        attr_reader symbol
        hash_settable_writer(symbol, klass)
      end
      
      def hash_settable_writer(symbol, klass)
        define_method("#{symbol}=") do |value|
          instance_variable_set("@#{symbol}", value.kind_of?(Hash) ? klass.from_hash(value) : value)
        end
      end
      
      #
      # Declares an attribute named ::symbol:: which can be set with either a list of instances of ::klass::
      # or a list of Hashes which will be used to populate a new instance of ::klass::.
      def hash_settable_list_accessor(symbol, klass)
        attr_reader symbol
        hash_settable_list_writer(symbol, klass)
      end

      def hash_settable_list_writer(symbol, klass)
        define_method("#{symbol}=") do |list|
          instance_variable_set("@#{symbol}", list.map do |item|
            item.kind_of?(Hash) ? klass.from_hash(item) : item
          end)
        end
      end

      def id_is(attribute)
        (file, line) = caller.first.split(':')

        class_eval(<<-EOS, file, line.to_i)
        def #{attribute}=(value)
          @#{attribute} = value.to_i
        end

        attr_reader #{attribute.inspect}
        alias :id #{attribute.inspect}
        alias :id= #{"#{attribute}=".to_sym.inspect}
        EOS
      end
    end

    ##
    # Centralized, error-checked place for a model to get the session to which it is bound.
    # Any Facebook API queries require a Session instance.
    def session
      @session || (raise UnboundSessionException, "Must bind this object to a Facebook session before querying")
    end
    
    # 
    # This gets populated from FQL queries.
    def anon=(value)
      @anonymous_fields = value
    end
    
    def initialize(hash = {})
      populate_from_hash!(hash)
    end

    def populate
      raise NotImplementedError, "#{self.class} included me and should have overriden me"
    end

    def populated?
      @populated
    end
    
    ##
    # Set model's attributes via Hash.  Keys should map directly to the model's attribute names.
    def populate_from_hash!(hash)
      unless hash.nil? || hash.empty?
        hash.each do |key, value|
          set_attr_method = "#{key}="
          unless value.nil?
            if respond_to?(set_attr_method)
              self.__send__(set_attr_method, value) 
            else
              Facebooker::Logging.log_info("**Warning**, Attempt to set non-attribute: #{key}",hash)
            end
          end
        end
        @populated = true
      end      
    end    
  end
end
