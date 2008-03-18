require 'fileutils'
require 'rubygems'
facebook_config = File.join(RAILS_ROOT,"config","facebooker.yml")
facebook_js = File.join(RAILS_ROOT,"public","javascripts",'facebooker.js')
FileUtils.cp File.join(File.dirname(__FILE__) , 'facebooker.yml.tpl'), facebook_config unless File.exist?(facebook_config)
FileUtils.cp File.join(File.dirname(__FILE__) , 'javascripts','facebooker.js'), facebook_js unless File.exist?(facebook_js)
puts IO.read(File.join(File.dirname(__FILE__), 'README'))
