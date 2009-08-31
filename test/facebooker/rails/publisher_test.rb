require File.expand_path(File.dirname(__FILE__) + '/../../rails_test_helper')

module SymbolHelper
  def symbol_helper_loaded
    true
  end
end

module ModuleHelper
  def module_helper_loaded
    true
  end
end

::RAILS_DEFAULT_LOGGER = Logger.new(STDOUT)

class TestPublisher < Facebooker::Rails::Publisher

  helper :symbol
  helper ModuleHelper

  def action(f)
    send_as :action
    from f
    title "Action Title"
  end

  def templatized_action(f)
    send_as :templatized_action
    from f
    title_template "Templatized Action Title"
  end

  def story(to)
    send_as :story
    recipients to
    title 'Story Title'
  end

  def notification(to,f)
    send_as :notification
    recipients to
    from f
    fbml "Not"
  end

  def email(to,f)
    send_as :email
    recipients to
    from f
    title "Email"
    fbml 'text'
    text fbml
  end

  def render_notification(to,f)
    send_as :notification
    recipients to
    from f
    fbml render(:inline=>"<%=module_helper_loaded%>")
  end


  def profile_update(to,f)
    send_as :profile
    recipients to
    profile "profile"
    profile_action "profile_action"
    mobile_profile "mobile_profile"

  end

   def profile_update_with_profile_main(to,f)
    send_as :profile
    recipients to
    from f
    profile "profile"
    profile_action "profile_action"
    mobile_profile "mobile_profile"
    profile_main "profile_main"
  end

  def ref_update(user)
    send_as :ref
    fbml "fbml"
    handle "handle"
  end

  def user_action_template
    one_line_story_template "{*actor*} did stuff with {*friend*}"
    short_story_template "{*actor*} has a title {*friend*}", render(:inline=>"This is a test render")
    full_story_template "{*actor*} did a lot","This is the full body",:img=>{:some_params=>true}
  end

  def simple_user_action_template
    one_line_story_template "{*actor*} did stuff with {*friend*}"
  end

  def user_action_with_action_links_template
    one_line_story_template "{*actor*} did stuff with {*friend*}"
    short_story_template "{*actor*} has a title {*friend*}", render(:inline=>"This is a test render")
    full_story_template "{*actor*} did a lot","This is the full body",:img=>{:some_params=>true}
    action_links action_link("Source","HREF")
  end

  def user_action(user)
    send_as :user_action
    from user
    data :friend=>"Mike"
  end

  def user_action_with_template_id(user)
    send_as :user_action
    from user
    data :friend=>"Mike"
    template_id 4
  end
  def user_action_with_story_size(user)
    send_as :user_action
    from user
    story_size ONE_LINE
    story_size FULL
    story_size SHORT
    data :friend=>"Mike"
  end
  def user_action_no_data(user)
    send_as :user_action
    from user
  end

  def no_send_as(to)
    recipients to
  end

  def invalid_send_as(to)
    send_as :fake
    recipients to
  end

  def publish_post_to_own_stream(user)
    send_as :publish_stream
    from  user
    target user
    attachment({:name => "Facebooker", :href => "http://www.exampple.com"})
    message "Posting post to own stream"
    action_links([{:text => "Action Link", :href => "http://www.example.com/action_link"}])
  end

  def publish_post_to_friends_stream(from, to)
    send_as :publish_stream
    from  from
    target to
    attachment({:name => "Facebooker", :href => "http://www.exampple.com"})
    message "Posting post to friends stream"
    action_links([{:text => "Action Link", :href => "http://www.example.com/action_link"}])
  end
end

class Facebooker::Rails::Publisher::FacebookTemplateTest < Test::Unit::TestCase
  FacebookTemplate = Facebooker::Rails::Publisher::FacebookTemplate

  def setup
    super
    ENV['FACEBOOK_API_KEY'] = '1234567'
    @template = mock("facebook template")
    FacebookTemplate.stubs(:register).returns(@template)
    FacebookTemplate.clear_cache!
  end

  def test_find_or_register_calls_find_cached
    FacebookTemplate.expects(:find_cached).with(TestPublisher,"simple_user_action").returns(@template)
    assert_equal FacebookTemplate.for_class_and_method(TestPublisher,"simple_user_action"),@template
  end

  def test_find_cached_should_use_cached_if_it_exists
    FacebookTemplate.cache(TestPublisher,"simple_user_action",@template)
    assert_equal FacebookTemplate.find_cached(TestPublisher,"simple_user_action"), @template

  end

  def test_find_cached_should_call_find_in_db_if_not_in_cache
    FacebookTemplate.expects(:find_in_db).with(TestPublisher,"simple_user_action").returns(@template)
    assert_equal FacebookTemplate.find_cached(TestPublisher,"simple_user_action"), @template
  end

  def test_find_in_db_should_run_find
    FacebookTemplate.expects(:find_by_template_name).with("1234567: TestPublisher::simple_user_action").returns(@template)
    @template.stubs(:template_changed?).returns(false)
    assert_equal FacebookTemplate.find_in_db(TestPublisher,"simple_user_action"), @template
  end

  def test_find_in_db_should_register_if_not_found
    FacebookTemplate.expects(:find_by_template_name).with("1234567: TestPublisher::simple_user_action").returns(nil)
    FacebookTemplate.expects(:register).with(TestPublisher,"simple_user_action").returns(@template)
    FacebookTemplate.find_cached(TestPublisher,"simple_user_action")

  end

  def test_find_in_db_should_check_for_change_if_found
    FacebookTemplate.stubs(:find_by_template_name).returns(@template)
    FacebookTemplate.stubs(:hashed_content).returns("MY CONTENT")
    @template.expects(:template_changed?).with("MY CONTENT").returns(false)
    FacebookTemplate.find_in_db(TestPublisher,"simple_user_action")
  end

  def test_find_in_db_should_re_register_if_changed
    FacebookTemplate.stubs(:find_by_template_name).with("1234567: TestPublisher::simple_user_action").returns(@template)
    FacebookTemplate.stubs(:hashed_content).returns("MY CONTENT")
    @template.stubs(:template_changed?).returns(true)
    @template.stubs(:destroy)
    FacebookTemplate.expects(:register).with(TestPublisher,"simple_user_action").returns(@template)
    FacebookTemplate.find_in_db(TestPublisher,"simple_user_action")
  end

end

class Facebooker::Rails::Publisher::PublisherTest < Test::Unit::TestCase
  FacebookTemplate = Facebooker::Rails::Publisher::FacebookTemplate

  def setup
    super

    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'

    @user = Facebooker::User.new
    @user.id=4
    @session = "session"
    @user.stubs(:session).returns(@session)
  end

  def teardown
    super
  end

  def test_create_action
    action=TestPublisher.create_action(@user)
    assert_equal Facebooker::Feed::Action,action.class
    assert_equal "Action Title",action.title
  end

  def test_deliver_action
    @user.expects(:publish_action)
    TestPublisher.deliver_action(@user)
  end

  def test_create_story
    action=TestPublisher.create_story(@user)
    assert_equal Facebooker::Feed::Story,action.class
    assert_equal "Story Title",action.title
  end

  def test_deliver_story
    @user.expects(:publish_story)
    TestPublisher.deliver_story(@user)
  end

  def test_create_notification
    notification=TestPublisher.create_notification(12451752,@user)
    assert_equal Facebooker::Rails::Publisher::Notification,notification.class
    assert_equal "Not",notification.fbml
  end

  def test_deliver_notification
    @session.expects(:send_notification)
    TestPublisher.deliver_notification("12451752",@user)
  end

  def test_create_email
    email=TestPublisher.create_email("12451752",@user)
    assert_equal Facebooker::Rails::Publisher::Email,email.class
    assert_equal "Email",email.title
    assert_equal "text",email.text
    assert_equal "text",email.fbml
  end

  def test_deliver_email
    @session.expects(:send_email)
    TestPublisher.deliver_email("12451752",@user)
  end

  def test_create_templatized_action
    ta=TestPublisher.create_templatized_action(@user)
    assert_equal Facebooker::Feed::TemplatizedAction,ta.class
    assert_equal "Templatized Action Title",ta.title_template

  end



  def test_deliver_templatized_action
    @user.expects(:publish_action)
    TestPublisher.deliver_templatized_action(@user)
  end
  def test_create_profile_update
    p=TestPublisher.create_profile_update(@user,@user)
    assert_equal Facebooker::Rails::Publisher::Profile,p.class
    assert_equal "profile",p.profile
    assert_equal "profile_action",p.profile_action
    assert_equal "mobile_profile",p.mobile_profile
  end
   def test_create_profile_update_with_profile_main
    p=TestPublisher.create_profile_update_with_profile_main(@user,@user)
    assert_equal Facebooker::Rails::Publisher::Profile,p.class
    assert_equal "profile",p.profile
    assert_equal "profile_action",p.profile_action
    assert_equal "mobile_profile",p.mobile_profile
    assert_equal "profile_main",p.profile_main
  end


  def test_deliver_profile
    Facebooker::User.stubs(:new).returns(@user)
    @user.expects(:set_profile_fbml).with('profile', 'mobile_profile', 'profile_action',nil)
    TestPublisher.deliver_profile_update(@user,@user)
  end

   def test_deliver_profile_with_main
    Facebooker::User.stubs(:new).returns(@user)
    @user.expects(:set_profile_fbml).with('profile', 'mobile_profile', 'profile_action','profile_main')
    TestPublisher.deliver_profile_update_with_profile_main(@user,@user)
  end


  def test_create_ref_update
    p=TestPublisher.create_ref_update(@user)
    assert_equal Facebooker::Rails::Publisher::Ref,p.class
    assert_equal "fbml",p.fbml
    assert_equal "handle",p.handle
  end

  def test_deliver_ref_update
    Facebooker::Session.stubs(:create).returns(@session)
    @server_cache="server_cache"
    @session.expects(:server_cache).returns(@server_cache)
    @server_cache.expects(:set_ref_handle).with("handle","fbml")
    TestPublisher.deliver_ref_update(@user)
  end

  def test_register_user_action
   Facebooker::Rails::Publisher::FacebookTemplate.expects(:register)
    TestPublisher.register_user_action
  end

  def test_register_should_deactivate_template_bundle_if_exists
    @template = mock
    @template.stubs(:bundle_id).returns(999)
    @template.stubs(:bundle_id=)
    @template.stubs(:save!)
    @session = mock
    @session.stubs(:register_template_bundle).returns(1000)
    Facebooker::Session.stubs(:create).returns(@session)
    Facebooker::Rails::Publisher::FacebookTemplate.stubs(:find_or_initialize_by_template_name).returns(@template)
    @template.expects(:deactivate)
    FacebookTemplate.register(TestPublisher, "simple_user_action")
  end

  def test_register_user_action_with_action_links
    ActionController::Base.append_view_path("./test/../../app/views")
    Facebooker::Rails::Publisher::FacebookTemplate.expects(:register)
    TestPublisher.register_user_action_with_action_links
  end

  def test_create_user_action
    @from_user = Facebooker::User.new
    @session = Facebooker::Session.new("","")
    @from_user.stubs(:session).returns(@session)
    Facebooker::Rails::Publisher::FacebookTemplate.expects(:bundle_id_for_class_and_method).
                                                   with(TestPublisher,'user_action').
                                                   returns(20309041537)
    ua = TestPublisher.create_user_action(@from_user)
    assert_equal "user_action", ua.template_name
  end
  def test_create_user_action_with_template_id
    @from_user = Facebooker::User.new
    @session = Facebooker::Session.new("","")
    @from_user.stubs(:session).returns(@session)
    Facebooker::Rails::Publisher::FacebookTemplate.expects(:bundle_id_for_class_and_method).
                                                   with(TestPublisher,'user_action').never
    ua = TestPublisher.create_user_action_with_template_id(@from_user)
    assert_equal 4,ua.template_id
  end

  def test_publisher_user_action
    @from_user = Facebooker::User.new
    @session = Facebooker::Session.new("","")
    @from_user.stubs(:session).returns(@session)
    @session.expects(:publish_user_action).with(20309041537,{:friend=>"Mike"},nil,nil,nil)

    Facebooker::Rails::Publisher::FacebookTemplate.expects(:bundle_id_for_class_and_method).
                                                   with(TestPublisher, 'user_action').
                                                   returns(20309041537)
    # pseudo_template = Struct.new(:bundle_id, :content_hash).new(20309041537, '')
    # pseudo_template.expects(:matches_content?).returns(true)
    # Facebooker::Rails::Publisher::FacebookTemplate.expects(:for).returns(pseudo_template)
    TestPublisher.deliver_user_action(@from_user)
  end

  def test_publish_user_action_with_story_size
    @from_user = Facebooker::User.new
    @session = Facebooker::Session.new("","")
    @from_user.stubs(:session).returns(@session)
    @session.expects(:publish_user_action).with(20309041537,{:friend=>"Mike"},nil,nil,2)

    Facebooker::Rails::Publisher::FacebookTemplate.expects(:bundle_id_for_class_and_method).
                                                   with(TestPublisher, 'user_action_with_story_size').
                                                   returns(20309041537)
    TestPublisher.deliver_user_action_with_story_size(@from_user)

  end

  def test_publishing_user_data_no_action_gives_nil_hash
    @from_user = Facebooker::User.new
    @session = Facebooker::Session.new("","")
    @from_user.stubs(:session).returns(@session)
    @session.expects(:publish_user_action).with(20309041537,{},nil,nil,nil)

    Facebooker::Rails::Publisher::FacebookTemplate.stubs(:bundle_id_for_class_and_method).returns(20309041537)
    TestPublisher.deliver_user_action_no_data(@from_user)
  end
  def test_no_sends_as_raises
    assert_raises(Facebooker::Rails::Publisher::UnspecifiedBodyType) {
      TestPublisher.deliver_no_send_as(@user)
    }
  end

  def test_invalid_send_as_raises
    assert_raises(Facebooker::Rails::Publisher::UnknownBodyType) {
      TestPublisher.deliver_invalid_send_as(@user)
    }
  end

  def test_publish_post_to_own_stream
    @user = Facebooker::User.new
    @user.expects(:publish_to).with(@user, has_entry(:attachment=>instance_of(Hash)))

    TestPublisher.deliver_publish_post_to_own_stream(@user)
  end

  def test_publish_post_to_friends_stream
    @from_user = Facebooker::User.new
    @to_user = Facebooker::User.new
    @from_user.expects(:publish_to).with(@to_user, has_entry(:action_links=>instance_of(Array)))

    TestPublisher.deliver_publish_post_to_friends_stream(@from_user, @to_user)
  end

  def test_keeps_class_method_missing
    assert_raises(NoMethodError) {
      TestPublisher.fake
    }
  end
  def test_keeps_instance_method_missing
    assert_raises(NoMethodError) {
      TestPublisher.new.fake
    }
  end

  def test_image_urls
    Facebooker.expects(:facebook_path_prefix).returns("/mike")
    string_image = TestPublisher.new.image('image.png', 'raw_string')
    assert_equal('/images/image.png',string_image.src)
    assert_equal('raw_string',string_image.href)
    route_image = TestPublisher.new.image('image.png', {:controller => :pokes, :action => :do, :id => 1})
    assert_equal('http://apps.facebook.com/mike/pokes/do/1',route_image.href)
  end

  def test_image_holder_equality
    assert_equal TestPublisher::ImageHolder.new('image.png', 'raw_string'), TestPublisher::ImageHolder.new('image.png', 'raw_string')
  end

  def test_image_to_json_puts_src_first
    string_image = TestPublisher.new.image('image.png', 'raw_string')
    assert_equal "{\"src\":\"/images/image.png\", \"href\":\"raw_string\"}",string_image.to_json
  end
  def test_action_link
    assert_equal({:text=>"text", :href=>"href"}, TestPublisher.new.action_link("text","href"))
  end

  def test_default_url_options
    Facebooker.expects(:facebook_path_prefix).returns("/mike")
    assert_equal({:host=>"apps.facebook.com/mike"},TestPublisher.new.default_url_options)
  end

  def test_recipients
    tp=TestPublisher.new
    tp.recipients "a"
    assert_equal("a",tp.recipients)
  end

  def test_symbol_helper
    assert TestPublisher.new.symbol_helper_loaded
  end
  def test_module_helper
    assert TestPublisher.new.module_helper_loaded
  end

  def test_with_render
    #normally Rails would do this for us
    silence_warnings do
      if ActionController::Base.respond_to?(:append_view_path)
        ActionController::Base.append_view_path("./test/../../app/views")
      end
      notification=TestPublisher.create_render_notification(12451752,@user)
      assert_equal "true",notification.fbml
    end
  end

  def test_notification_as_announcement
    #normally Rails would do this for us
    silence_warnings do
      if ActionController::Base.respond_to?(:append_view_path)
        ActionController::Base.append_view_path("./test/../../app/views")
      end
      notification=TestPublisher.create_render_notification(12451752,nil)
      assert_equal "true",notification.fbml
    end
  end
end
