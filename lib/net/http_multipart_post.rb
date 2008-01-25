require 'net/http'

module Net
  class HTTP
    class << self
      def post_multipart_form(url, params)
        MultipartPost.new(url, params).post
      end
    end

    class MultipartPostFile
      def initialize(filename=nil, content_type=nil, data=nil)
        @filename = filename
        @content_type = content_type
        @data = data
      end
  
      attr_accessor :filename
      attr_accessor :content_type
      attr_accessor :data
    end

    class MultipartPost
      def initialize(url, params)
        @url = url
        @multipart_post_files = extract_file_parameters_from(params)
        @params = extract_non_file_parameters_from(params)
      end
  
      def post
        req = Post.new(url.path)
        req.body = body
        req.content_type = content_type
        req.basic_auth url.user, url.password if url.user
        Net::HTTP.new(url.host, url.port).start {|http|
          http.request(req)
        }    
      end
      
      BOUNDARY = "MichaelNiessnerIsSuperDuperAwesome"
  
    protected
      attr_reader :url, :params, :multipart_post_files

      def extract_file_parameters_from(hash)
        hash.reject{|key, value| !multipart_post_file?(value)}
      end
      
      def extract_non_file_parameters_from(hash)
        hash.reject{|key, value| multipart_post_file?(value)}
      end
      
      def multipart_post_file?(object)
        object.respond_to?(:content_type) &&
        object.respond_to?(:data) &&
        object.respond_to?(:filename)
      end

      def content_type
        "multipart/form-data; boundary=#{BOUNDARY}"
      end
  
      def body
        encode_parameters + encode_multipart_post_files + final_boundary
      end
  
      def encode_multipart_post_files
        return "" if multipart_post_files.empty?
        if multipart_post_files.size == 1
          name = multipart_post_files.keys.first
          file = multipart_post_files.values.first
          encode_multipart_post_file(name, file)
        else
          raise "Currently more than 1 file upload is not supported."
        end
      end
      
      def encode_multipart_post_file(name, multipart_post_file)
        parameter_boundary + 
        disposition_with_filename(name, multipart_post_file.filename) + 
        file_content_type(multipart_post_file.content_type) + 
        multipart_post_file.data + 
        "\r\n"
      end
  
      def encode_parameters
       params.sort_by{|key, value| key.to_s}.map{|key, value| encode_parameter(key, value)}.join
      end
  
      def encode_parameter(key, value)
        parameter_boundary + disposition_with_name(key) + value.to_s + "\r\n"
      end
  
      def file_content_type(string)
        "Content-Type: #{string}\r\n\r\n"
      end
  
      def disposition_with_filename(name, filename)
        if name.nil?
          disposition("filename=\"#{filename}\"")
        else
          disposition("name=\"#{name}\"; filename=\"#{filename}\"")
        end
      end
  
      def disposition_with_name(name)
        disposition("name=\"#{name}\"\r\n")
      end
  
      def disposition(attribute)
        "Content-Disposition: form-data; #{attribute}\r\n"
      end
    
      def parameter_boundary
        "--#{BOUNDARY}\r\n"
      end
  
      def final_boundary
        "--#{BOUNDARY}--\r\n"
      end
    end
  end
end