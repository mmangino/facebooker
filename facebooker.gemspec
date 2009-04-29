# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{facebooker}
  s.version = "1.0.30"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chad Fowler", "Patrick Ewing", "Mike Mangino", "Shane Vitarana", "Corey Innis"]
  s.date = %q{2009-04-29}
  s.description = %q{Facebooker is a Ruby wrapper over the Facebook[http://facebook.com] {REST API}[http://wiki.developers.facebook.com/index.php/API].  Its goals are:

* Idiomatic Ruby
* No dependencies outside of the Ruby standard library (This is true with Rails 2.1. Previous Rails versions require the JSON gem)
* Concrete classes and methods modeling the Facebook data, so it's easy for a Rubyist to understand what's available
* Well tested}
  s.email = %q{mmangino@elevatedrails.com}
  s.extra_rdoc_files = ["Manifest.txt", "CHANGELOG.rdoc", "COPYING.rdoc", "README.rdoc", "TODO.rdoc"]
  s.files = [".autotest", "CHANGELOG.rdoc", "COPYING.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "TODO.rdoc", "examples/desktop_login.rb", "facebooker.gemspec", "generators/facebook/facebook_generator.rb", "generators/facebook/templates/config/facebooker.yml", "generators/facebook/templates/public/javascripts/facebooker.js", "generators/facebook_controller/USAGE", "generators/facebook_controller/facebook_controller_generator.rb", "generators/facebook_controller/templates/controller.rb", "generators/facebook_controller/templates/functional_test.rb", "generators/facebook_controller/templates/helper.rb", "generators/facebook_controller/templates/view.fbml.erb", "generators/facebook_controller/templates/view.html.erb", "generators/facebook_publisher/facebook_publisher_generator.rb", "generators/facebook_publisher/templates/create_facebook_templates.rb", "generators/facebook_publisher/templates/publisher.rb", "generators/facebook_scaffold/USAGE", "generators/facebook_scaffold/facebook_scaffold_generator.rb", "generators/facebook_scaffold/templates/controller.rb", "generators/facebook_scaffold/templates/facebook_style.css", "generators/facebook_scaffold/templates/functional_test.rb", "generators/facebook_scaffold/templates/helper.rb", "generators/facebook_scaffold/templates/layout.fbml.erb", "generators/facebook_scaffold/templates/layout.html.erb", "generators/facebook_scaffold/templates/style.css", "generators/facebook_scaffold/templates/view_edit.fbml.erb", "generators/facebook_scaffold/templates/view_edit.html.erb", "generators/facebook_scaffold/templates/view_index.fbml.erb", "generators/facebook_scaffold/templates/view_index.html.erb", "generators/facebook_scaffold/templates/view_new.fbml.erb", "generators/facebook_scaffold/templates/view_new.html.erb", "generators/facebook_scaffold/templates/view_show.fbml.erb", "generators/facebook_scaffold/templates/view_show.html.erb", "generators/publisher/publisher_generator.rb", "generators/xd_receiver/templates/xd_receiver.html", "generators/xd_receiver/xd_receiver_generator.rb", "init.rb", "install.rb", "lib/facebooker.rb", "lib/facebooker/adapters/adapter_base.rb", "lib/facebooker/adapters/bebo_adapter.rb", "lib/facebooker/adapters/facebook_adapter.rb", "lib/facebooker/admin.rb", "lib/facebooker/batch_request.rb", "lib/facebooker/data.rb", "lib/facebooker/feed.rb", "lib/facebooker/logging.rb", "lib/facebooker/mobile.rb", "lib/facebooker/mock/service.rb", "lib/facebooker/mock/session.rb", "lib/facebooker/model.rb", "lib/facebooker/models/affiliation.rb", "lib/facebooker/models/album.rb", "lib/facebooker/models/applicationproperties.rb", "lib/facebooker/models/applicationrestrictions.rb", "lib/facebooker/models/cookie.rb", "lib/facebooker/models/education_info.rb", "lib/facebooker/models/event.rb", "lib/facebooker/models/friend_list.rb", "lib/facebooker/models/group.rb", "lib/facebooker/models/info_item.rb", "lib/facebooker/models/info_section.rb", "lib/facebooker/models/location.rb", "lib/facebooker/models/notifications.rb", "lib/facebooker/models/page.rb", "lib/facebooker/models/photo.rb", "lib/facebooker/models/tag.rb", "lib/facebooker/models/user.rb", "lib/facebooker/models/video.rb", "lib/facebooker/models/work_info.rb", "lib/facebooker/parser.rb", "lib/facebooker/rails/controller.rb", "lib/facebooker/rails/cucumber.rb", "lib/facebooker/rails/cucumber/world.rb", "lib/facebooker/rails/extensions/action_controller.rb", "lib/facebooker/rails/extensions/rack_setup.rb", "lib/facebooker/rails/extensions/routing.rb", "lib/facebooker/rails/facebook_form_builder.rb", "lib/facebooker/rails/facebook_pretty_errors.rb", "lib/facebooker/rails/facebook_request_fix.rb", "lib/facebooker/rails/facebook_session_handling.rb", "lib/facebooker/rails/facebook_url_helper.rb", "lib/facebooker/rails/facebook_url_rewriting.rb", "lib/facebooker/rails/helpers.rb", "lib/facebooker/rails/helpers/fb_connect.rb", "lib/facebooker/rails/integration_session.rb", "lib/facebooker/rails/profile_publisher_extensions.rb", "lib/facebooker/rails/publisher.rb", "lib/facebooker/rails/routing.rb", "lib/facebooker/rails/test_helpers.rb", "lib/facebooker/rails/utilities.rb", "lib/facebooker/server_cache.rb", "lib/facebooker/service.rb", "lib/facebooker/session.rb", "lib/facebooker/version.rb", "lib/net/http_multipart_post.rb", "lib/rack/facebook.rb", "lib/tasks/facebooker.rake", "lib/tasks/tunnel.rake", "rails/init.rb", "setup.rb", "templates/layout.erb", "test/facebooker/adapters_test.rb", "test/facebooker/admin_test.rb", "test/facebooker/batch_request_test.rb", "test/facebooker/data_test.rb", "test/facebooker/logging_test.rb", "test/facebooker/mobile_test.rb", "test/facebooker/model_test.rb", "test/facebooker/models/event_test.rb", "test/facebooker/models/user_test.rb", "test/facebooker/rails/publisher_test.rb", "test/facebooker/rails_integration_test.rb", "test/facebooker/server_cache_test.rb", "test/facebooker/session_test.rb", "test/facebooker_test.rb", "test/fixtures/multipart_post_body_with_only_parameters.txt", "test/fixtures/multipart_post_body_with_single_file.txt", "test/fixtures/multipart_post_body_with_single_file_that_has_nil_key.txt", "test/net/http_multipart_post_test.rb", "test/rack/facebook_test.rb", "test/rails_test_helper.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://facebooker.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{facebooker}
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Facebooker is a Ruby wrapper over the Facebook[http://facebook.com] {REST API}[http://wiki.developers.facebook.com/index.php/API]}
  s.test_files = ["test/facebooker/adapters_test.rb", "test/facebooker/admin_test.rb", "test/facebooker/batch_request_test.rb", "test/facebooker/data_test.rb", "test/facebooker/logging_test.rb", "test/facebooker/mobile_test.rb", "test/facebooker/model_test.rb", "test/facebooker/models/event_test.rb", "test/facebooker/models/user_test.rb", "test/facebooker/rails/publisher_test.rb", "test/facebooker/rails_integration_test.rb", "test/facebooker/server_cache_test.rb", "test/facebooker/session_test.rb", "test/facebooker_test.rb", "test/net/http_multipart_post_test.rb", "test/rack/facebook_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.0.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.12.1"])
    else
      s.add_dependency(%q<json>, [">= 1.0.0"])
      s.add_dependency(%q<hoe>, [">= 1.12.1"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.0.0"])
    s.add_dependency(%q<hoe>, [">= 1.12.1"])
  end
end
