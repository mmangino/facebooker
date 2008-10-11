# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{facebooker}
  s.version = "0.9.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chad Fowler", "Patrick Ewing", "Mike Mangino", "Shane Vitarana"]
  s.date = %q{2008-02-13}
  s.description = %q{== DESCRIPTION:  Facebooker is a Ruby wrapper over the Facebook[http://facebook.com] {REST API}[http://developer.facebook.com].  Its goals are:  * Idiomatic Ruby * No dependencies outside of the Ruby standard library * Concrete classes and methods modeling the Facebook data, so it's easy for a Rubyist to understand what's available * Well tested  == FEATURES/PROBLEMS:}
  s.email = %q{mmangino@elevatedrails.com}
  s.extra_rdoc_files = ["CHANGELOG.txt", "History.txt", "Manifest.txt", "README.txt", "TODO.txt", "test/fixtures/multipart_post_body_with_only_parameters.txt", "test/fixtures/multipart_post_body_with_single_file.txt", "test/fixtures/multipart_post_body_with_single_file_that_has_nil_key.txt"]
  s.files = ["CHANGELOG.txt", "COPYING", "History.txt", "Manifest.txt", "README", "README.txt", "Rakefile", "TODO.txt", "facebooker.yml.tpl", "init.rb", "install.rb", "lib/facebooker.rb", "lib/facebooker/affiliation.rb", "lib/facebooker/album.rb", "lib/facebooker/cookie.rb", "lib/facebooker/data.rb", "lib/facebooker/education_info.rb", "lib/facebooker/event.rb", "lib/facebooker/feed.rb", "lib/facebooker/group.rb", "lib/facebooker/location.rb", "lib/facebooker/model.rb", "lib/facebooker/notifications.rb", "lib/facebooker/parser.rb", "lib/facebooker/photo.rb", "lib/facebooker/rails/controller.rb", "lib/facebooker/rails/facebook_asset_path.rb", "lib/facebooker/rails/facebook_form_builder.rb", "lib/facebooker/rails/facebook_request_fix.rb", "lib/facebooker/rails/facebook_session_handling.rb", "lib/facebooker/rails/facebook_url_rewriting.rb", "lib/facebooker/rails/helpers.rb", "lib/facebooker/rails/routing.rb", "lib/facebooker/rails/test_helpers.rb", "lib/facebooker/rails/utilities.rb", "lib/facebooker/server_cache.rb", "lib/facebooker/service.rb", "lib/facebooker/session.rb", "lib/facebooker/tag.rb", "lib/facebooker/user.rb", "lib/facebooker/version.rb", "lib/facebooker/work_info.rb", "lib/net/http_multipart_post.rb", "lib/tasks/facebooker.rake", "lib/tasks/tunnel.rake", "setup.rb", "test/event_test.rb", "test/facebook_cache_test.rb", "test/facebook_data_test.rb", "test/facebooker_test.rb", "test/fixtures/multipart_post_body_with_only_parameters.txt", "test/fixtures/multipart_post_body_with_single_file.txt", "test/fixtures/multipart_post_body_with_single_file_that_has_nil_key.txt", "test/http_multipart_post_test.rb", "test/model_test.rb", "test/rails_integration_test.rb", "test/session_test.rb", "test/test_helper.rb", "test/user_test.rb"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{facebooker}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{Pure, idiomatic Ruby wrapper for the Facebook REST API.}
  s.test_files = ["test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hoe>, [">= 1.5.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.5.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.5.0"])
  end
end
