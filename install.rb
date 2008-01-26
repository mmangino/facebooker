require 'fileutils'

facebook_config = File.dirname(__FILE__) + '/../../../config/facebooker.yml'
FileUtils.cp File.dirname(__FILE__) + '/facebooker.yml.tpl', facebook_config unless File.exist?(facebook_config)
puts IO.read(File.join(File.dirname(__FILE__), 'README'))