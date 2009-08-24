# -*- ruby -*-
#
require 'rubygems'
require 'hoe'
begin
  require 'load_multi_rails_rake_tasks'
rescue LoadError
  $stderr.puts "Install the multi_rails gem to run tests against multiple versions of Rails"
end

require 'lib/facebooker/version'

HOE = Hoe.spec('facebooker') do
  self.version = Facebooker::VERSION::STRING
  self.rubyforge_name = 'facebooker'
  developer 'Chad Fowler',    'chad@chadfowlwer.com'
  developer 'Patrick Ewing',  ''
  developer 'Mike Mangino',   ''
  developer 'Shane Vitarana', ''
  developer 'Corey Innis',    ''
  developer 'Mike Mangino',   'mmangino@elevatedrails.com'

  self.readme_file   = 'README.rdoc'
  self.history_file  = 'CHANGELOG.rdoc'
  self.remote_rdoc_dir = '' # Release to root
  self.test_globs = ['test/**/*_test.rb']
  extra_deps << ['json', '>= 1.0.0']
  self.extra_rdoc_files  = FileList['*.rdoc']
end

begin
  require 'rcov/rcovtask'

  namespace :test do
    namespace :coverage do
      desc "Delete aggregate coverage data."
      task(:clean) { rm_f "coverage.data" }
    end
    desc 'Aggregate code coverage for unit, functional and integration tests'
    Rcov::RcovTask.new(:coverage) do |t|
      t.libs << "test"
      t.test_files = FileList["test/**/*_test.rb"]
      t.output_dir = "coverage/"
      t.verbose = true
      t.rcov_opts = ['--exclude', 'test,/usr/lib/ruby,/Library/Ruby,/System/Library', '--sort', 'coverage']
    end
  end
rescue LoadError
  $stderr.puts "Install the rcov gem to enable test coverage analysis"
end

namespace :gem do
  task :spec do
    File.open("#{HOE.name}.gemspec", 'w') do |f|
      f.write(HOE.spec.to_ruby)
    end
  end

  namespace :spec do
    task :dev do
      File.open("#{HOE.name}.gemspec", 'w') do |f|
        HOE.spec.version = "#{HOE.version}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
        f.write(HOE.spec.to_ruby)
      end
    end
  end
end

# vim: syntax=Ruby
# 
# 
# require File.dirname(__FILE__) + '/vendor/gardener/lib/gardener'
# 
# require 'facebooker'
# 
# namespace :doc do
#   task :readme do
#     puts "Readme"
#   end
# end
# 
# Gardener.configure do
#   gem_spec do |spec|
#     spec.name              = 'facebooker'
#     spec.version           = Gem::Version.new(Facebooker::VERSION::STRING)
#     spec.summary           = "Pure, idiomatic Ruby wrapper for the Facebook REST API."
#     spec.email             = 'chad@infoether.com'
#     spec.author            = ['Chad Fowler', 'Patrick Ewing','Mike Mangino','Shane Vitarana']
#     spec.extra_rdoc_files  = %w(COPYING)
#     spec.rdoc_options      = ['--title', "Gardener",
#                               '--main',  'README',
#                               '--line-numbers', '--inline-source']
#   end
# end
