# -*- ruby -*-
# 
require 'rubygems'
ENV['RUBY_FLAGS']="-I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}"
require 'hoe'
 $: << File.dirname(__FILE__) + '/lib'
require './lib/facebooker.rb'

Hoe.new('facebooker', Facebooker::VERSION::STRING) do |p|
  p.rubyforge_name = 'facebooker'
  p.author = ['Chad Fowler', 'Patrick Ewing', 'Mike Mangino', 'Shane Vitarana', 'Corey Innis']
  p.email = 'mmangino@elevatedrails.com'
  p.summary = 'Pure, idiomatic Ruby wrapper for the Facebook REST API.'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = '' # Release to root
  p.test_globs = 'test/*.rb'
  p.extra_deps << ['json', '>= 1.0.0'] 
end

require 'rcov/rcovtask'

namespace :test do 
  namespace :coverage do
    desc "Delete aggregate coverage data."
    task(:clean) { rm_f "coverage.data" }
  end
  desc 'Aggregate code coverage for unit, functional and integration tests'
  Rcov::RcovTask.new(:coverage) do |t|
    t.libs << "test"
    t.test_files = FileList["test/*.rb"]
    t.output_dir = "coverage/"
    t.verbose = true
  end
end

gem_spec_file = 'facebooker.gemspec'

gem_spec = eval(File.read(gem_spec_file)) rescue nil

desc "Generate the gemspec file."
task :gemspec do
  require 'erb'

  File.open(gem_spec_file, 'w') do |f|
    f.write ERB.new(File.read("#{gem_spec_file}.erb")).result(binding)
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
