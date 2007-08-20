require File.dirname(__FILE__) + '/vendor/gardener/lib/gardener'
$: << File.dirname(__FILE__) + '/lib'
require 'facebooker'

Gardener.configure do
  gem_spec do |spec|
    spec.name              = 'facebooker'
    spec.version           = Gem::Version.new(Facebooker::VERSION::STRING)
    spec.summary           = "Pure, idiomatic Ruby wrapper for the Facebook REST API."
    spec.email             = 'chad@infoether.com'
    spec.author            = ['Chad Fowler', 'Patrick Ewing']
    spec.extra_rdoc_files  = %w(COPYING)
    spec.rdoc_options      = ['--title', "Gardener",
                              '--main',  'README',
                              '--line-numbers', '--inline-source']
  end
end
