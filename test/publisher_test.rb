require File.dirname(__FILE__) + '/test_helper.rb'
require 'rubygems'
require 'flexmock/test_unit'
require 'action_controller'
require 'action_controller/test_process'
require 'active_record'
require File.dirname(__FILE__)+'/../init'
require 'facebooker/rails/controller'
require 'facebooker/rails/helpers'
require 'facebooker/rails/publisher'


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
  
end

class PublisherTest < Test::Unit::TestCase
  FacebookTemplate = Facebooker::Rails::Publisher::FacebookTemplate
  
  def setup
    super
    @user = Facebooker::User.new
    @user.id=4
    @session = "session"
    @user.stubs(:session).returns(@session)
  end
  
  def teardown
    super
    FacebookTemplate.clear_template_ids!
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
    FacebookTemplate.expects(:find_or_register_template_id).
                     with('user_action', TestPublisher, :skip_template_cache => true).returns(20309041537)
    
    TestPublisher.register_user_action
  end
  def test_register_user_action_with_action_links
    ActionController::Base.append_view_path("./test/../../app/views")
    Facebooker::Session.any_instance.expects(:register_template_bundle)
    Facebooker::Rails::Publisher::FacebookTemplate.expects(:register)
    TestPublisher.register_user_action_with_action_links
  end
  
  def test_create_user_action
    @from_user = Facebooker::User.new
    @session = Facebooker::Session.new("","")
    @from_user.stubs(:session).returns(@session)
    Facebooker::Rails::Publisher::FacebookTemplate.expects(:template_id_for).
                                                   with('user_action', TestPublisher).
                                                   returns(20309041537)
    ua = TestPublisher.create_user_action(@from_user)
    assert_equal "user_action", ua.template_name
  end
  
  def test_publisher_user_action
    @from_user = Facebooker::User.new
    @session = Facebooker::Session.new("","")
    @from_user.stubs(:session).returns(@session)
    @session.expects(:publish_user_action).with(20309041537,{:friend=>"Mike"},nil,nil)
    
    Facebooker::Rails::Publisher::FacebookTemplate.expects(:template_id_for).
                                                   with('user_action', TestPublisher).
                                                   returns(20309041537)
    # pseudo_template = Struct.new(:bundle_id, :content_hash).new(20309041537, '')
    # pseudo_template.expects(:matches_content?).returns(true)
    # Facebooker::Rails::Publisher::FacebookTemplate.expects(:for).returns(pseudo_template)
    TestPublisher.deliver_user_action(@from_user)
  end
  
  def test_publishing_user_data_no_action_gives_nil_hash
    @from_user = Facebooker::User.new
    @session = Facebooker::Session.new("","")
    @from_user.stubs(:session).returns(@session)
    @session.expects(:publish_user_action).with(20309041537,{},nil,nil)
    
    Facebooker::Rails::Publisher::FacebookTemplate.expects(:template_id_for).returns(20309041537)
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
  
  def test_template_content_hashing
    a1 = [['1', '2'], ['3', '4'], []]
    a2 = [['1', '2'], [], ['3', '4']]
    a3 = [['1', '2', '3'], ['4'], []]
    a11 = [['1', '2'], ['3', '4'], []]
    
    hasher = Facebooker::Rails::Publisher::FacebookTemplate
    assert_equal hasher.hash_content!(a1), hasher.hash_content!(a11)
    assert_not_equal hasher.hash_content!(a1), hasher.hash_content!(a2)
    assert_not_equal hasher.hash_content!(a1), hasher.hash_content!(a3)
    assert_not_equal hasher.hash_content!(a2), hasher.hash_content!(a3)    
  end
  
  def test_template_publisher_content
    expected_content =  [["{*actor*} did stuff with {*friend*}"],
                         [{:template_title=>"{*actor*} has a title {*friend*}",
                           :template_body=>"This is a test render"}],
                         {:template_title=>"{*actor*} did a lot",
                          :template_body=>"This is the full body",
                          :img=>{:some_params=>true}}]
    assert_equal expected_content, FacebookTemplate.publisher_content('user_action', TestPublisher)
  end  
  
  def test_template_cache
    FacebookTemplate.update_template_cache! 12345, 't_a', 'TestPublisher'
    FacebookTemplate.update_template_cache! 12346, 't_b', 'TestPublisher'
    FacebookTemplate.update_template_cache! 12347, 't_a', 'TestPublisher2'
    
    assert_equal 12345, FacebookTemplate.template_id_for('t_a', 'TestPublisher')
    assert_equal 12346, FacebookTemplate.template_id_for('t_b', 'TestPublisher')
    assert_equal 12347, FacebookTemplate.template_id_for('t_a', 'TestPublisher2')
    assert_raise(RuntimeError) { FacebookTemplate.template_id_for('t_d', 'TestPublisher') }

    FacebookTemplate.clear_template_ids_for_class! TestPublisher
    assert_raise(RuntimeError) { FacebookTemplate.template_id_for('t_a', 'TestPublisher') }
    assert_raise(RuntimeError) { FacebookTemplate.template_id_for('t_b', 'TestPublisher') }
    assert_equal 12347, FacebookTemplate.template_id_for('t_a', 'TestPublisher2')
    
    FacebookTemplate.clear_template_ids!
    assert_raise(RuntimeError) { FacebookTemplate.template_id_for('t_a', 'TestPublishe2') }    
  end
  
  def test_register_new_template_id
    content = FacebookTemplate.publisher_content 'user_action', TestPublisher
    Facebooker::Session.any_instance.expects(:register_template_bundle).with(*content).returns(20309041537)
    FacebookTemplate.expects(:update_template_db!).
                     with(20309041537, 'user_action', TestPublisher, content).returns(nil)

    template_id = FacebookTemplate.register_new_template_id!('user_action', TestPublisher, content)    
    assert_equal 20309041537, template_id
    assert_equal 20309041537, FacebookTemplate.template_id_for('user_action', TestPublisher)
  end
  
  def test_find_or_register_template_id_registers_new_content
    ActionController::Base.append_view_path("./test/../../app/views")
    
    expected_content = FacebookTemplate.publisher_content 'user_action', TestPublisher
    pseudo_template = Object.new
    pseudo_template.expects(:matches_content?).with(expected_content).returns(false)
    FacebookTemplate.expects(:for).returns(pseudo_template)
    FacebookTemplate.expects(:register_new_template_id!).with('user_action', TestPublisher, expected_content).
                                                         returns(20309041537)
    
    template_id = FacebookTemplate.find_or_register_template_id 'user_action', TestPublisher
    assert_equal 20309041537, template_id
  end
  
  def test_find_or_register_template_id_honors_db_cache
    ActionController::Base.append_view_path("./test/../../app/views")
    
    expected_content = FacebookTemplate.publisher_content 'user_action', TestPublisher
    pseudo_template = Struct.new(:template_id).new(20309041537)
    pseudo_template.expects(:matches_content?).returns(true)
    FacebookTemplate.expects(:for).returns(pseudo_template)
    FacebookTemplate.expects(:register_new_template_id!).never

    template_id = FacebookTemplate.find_or_register_template_id 'user_action', TestPublisher
    assert_equal 20309041537, template_id    
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
    assert_equal({:src => '/images/image.png', :href => 'raw_string' },
        TestPublisher.new.image('image.png', 'raw_string'))
    assert_equal({:src => '/images/image.png', :href => 'http://apps.facebook.com/mike/pokes/do/1' },
        TestPublisher.new.image('image.png', {:controller => :pokes, :action => :do, :id => 1}))    
  end
  
  def test_action_link
    assert_equal({:text=>"text", :href=>"href"}, TestPublisher.new.action_link("text","href"))
  end
  
  def test_default_url_options
    Facebooker.expects(:facebook_path_prefix).returns("/mike")
    assert_equal({:host=>"apps.facebook.com/mike"},TestPublisher.default_url_options)
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
    if ActionController::Base.respond_to?(:append_view_path)
      ActionController::Base.append_view_path("./test/../../app/views")
    end
    notification=TestPublisher.create_render_notification(12451752,@user)
    assert_equal "true",notification.fbml
  end
  
  def test_notification_as_announcement
    #normally Rails would do this for us
    if ActionController::Base.respond_to?(:append_view_path)
      ActionController::Base.append_view_path("./test/../../app/views")
    end
    notification=TestPublisher.create_render_notification(12451752,nil)
    assert_equal "true",notification.fbml
  end
end
