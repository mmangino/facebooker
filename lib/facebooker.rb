Dir[File.join(File.dirname(__FILE__), 'facebooker/**/*.rb')].sort.each { |lib| require lib }
