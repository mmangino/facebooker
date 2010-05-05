require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'active_support'

class Facebooker::UserTest < Test::Unit::TestCase

  def setup
    @session = Facebooker::Session.create('apikey', 'secretkey')
    @user = Facebooker::User.new(1234, @session)
    @other_user = Facebooker::User.new(4321, @session)
    ENV['FACEBOOK_CANVAS_PATH'] ='facebook_app_name'
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'

    @user.friends = [@other_user]
  end

  def test_has_permission
    expect_http_posts_with_responses(has_app_permission_response_xml)
    assert @user.has_permission?("status_update")
  end

  def test_has_permissions
    expect_http_posts_with_responses(has_app_permission_response_xml, has_app_permission_response_xml)
    assert @user.has_permissions?(["status_update", "read_stream"])
  end

  def test_app_user_should_return_false_if_facebook_returns_one
    expect_http_posts_with_responses(is_app_user_true_response_xml)
    assert @user.app_user?
  end

  def test_app_user_should_return_false_if_facebook_does_not_return_one
    expect_http_posts_with_responses(is_app_user_false_response_xml)
    assert !@user.app_user?
  end

  def test_can_ask_user_if_he_or_she_is_friends_with_another_user
    assert(@user.friends_with?(@other_user))
  end

  def test_can_ask_user_if_he_or_she_is_friends_with_another_user_by_user_id
    assert(@user.friends_with?(@other_user.id))
  end

  def test_does_not_query_facebook_for_uid
    @session.expects(:post).never
    assert_equal 1234, Facebooker::User.new(1234, @session).uid
  end

  def test_uid_is_always_an_integer
    assert_equal 1234, Facebooker::User.new(:uid => "1234").uid
    assert_equal 1234, Facebooker::User.new(:id  => "1234").uid

    assert_equal 1234, Facebooker::User.new(:uid => "1234").id
    assert_equal 1234, Facebooker::User.new(:id  => "1234").id

    assert_equal 1234, Facebooker::User.new(:uid => "1234").facebook_id
    assert_equal 1234, Facebooker::User.new(:id  => "1234").facebook_id
  end

  def test_cast_to_friend_list_id_with_nil
    assert_nil @user.cast_to_friend_list_id(nil)
  end
  def test_cast_to_friend_list_id_with_integer
    assert_equal 14,@user.cast_to_friend_list_id(14)
  end
  def test_cast_to_friend_list_id_with_string
    @user.expects(:friend_lists).returns([Facebooker::FriendList.new(:flid=>199,:name=>"Work")])
    assert_equal 199,@user.cast_to_friend_list_id("Work")
  end
  def test_cast_to_friend_list_id_with_friend_list
    assert_equal 199,@user.cast_to_friend_list_id(Facebooker::FriendList.new(:flid=>199,:name=>"Work"))
  end

  def test_cast_to_friend_list_id_with_invalid_string_raises
    @user.expects(:friend_lists).returns([Facebooker::FriendList.new(:flid=>1,:name=>"Not Picked")])
    assert_nil @user.cast_to_friend_list_id("Something")
    fail("No exception raised, Expected Facebooker::Session::InvalidFriendList")
  rescue   Facebooker::Session::InvalidFriendList
    nil
  end

  def test_can_create_from_current_session
    Facebooker::Session.expects(:current).returns("current")
    user=Facebooker::User.new(1)
    assert_equal("current",user.session)
  end

  def test_raises_when_no_session_bound
    assert_raises(Facebooker::Model::UnboundSessionException) { Facebooker::User.new(1, nil).populate }
  end
  
  def test_passes_request_locale_when_set
    session = mock()
    session.expects(:post).with("facebook.users.getInfo",has_entry(:locale,"es_ES"))
    Facebooker::Session.expects(:current).returns(session)
    user=Facebooker::User.new(1)
    user.request_locale="es_ES"
    user.name
    
  end
  
  def test_doesnt_pass_request_locale_when_not_set
    session = mock()
    session.expects(:post).with("facebook.users.getInfo",Not(has_key(:locale)))
    Facebooker::Session.expects(:current).returns(session)
    user=Facebooker::User.new(1)
    user.name
    
  end

  def test_can_set_mobile_fbml
    @user.expects(:set_profile_fbml).with(nil,"test",nil,nil)
    @user.mobile_fbml="test"
  end
  def test_can_set_profile_action
    @user.expects(:set_profile_fbml).with(nil,nil,"test",nil)
    @user.profile_action="test"
  end
  def test_can_set_profile_fbml
    @user.expects(:set_profile_fbml).with("test",nil,nil,nil)
    @user.profile_fbml="test"
  end

  def test_can_set_profile_main
    @user.expects(:set_profile_fbml).with(nil,nil,nil,"test")
    @user.profile_main="test"
  end


  def test_can_call_get_status
    @session.expects(:post).with('facebook.status.get', {:uid => 1234, :limit => 4}).returns([{ "time" => 1233804858, "source" => 6628568379, "message" => "my message rocks!", "status_id" => 61436484312, 'uid' => 1234 }])
    st = @user.statuses( 4 )
    assert_equal st.size, 1
    assert_equal st.first.message, 'my message rocks!'
  end

  def test_can_call_set_profile_fbml
    @session.expects(:post).with('facebook.profile.setFBML', {:uid=>1234,:profile=>"profile",:profile_action=>"action",:mobile_profile=>"mobile"},false)
    @user.set_profile_fbml("profile","mobile","action")
  end

  def test_can_call_set_profile_fbml_with_profile_main
    @session.expects(:post).with('facebook.profile.setFBML', {:uid=>1234,:profile=>"profile",:profile_action=>"action",:mobile_profile=>"mobile", :profile_main => 'profile_main'},false)
    @user.set_profile_fbml("profile","mobile","action",'profile_main')
  end

  def test_can_get_profile_photos
    @user.expects(:profile_photos)
    @user.profile_photos
  end

  def test_can_set_cookie
    @user.expects(:set_cookie).with('name', 'value')
    @user.set_cookie('name', 'value')
  end

  def test_can_get_cookies
    @user.expects(:get_cookies).with('name')
    @user.get_cookies('name')
  end

  def test_get_profile_photos
    @user = Facebooker::User.new(548871286, @session)
    expect_http_posts_with_responses(example_profile_photos_get_xml)
    photos = @user.profile_photos
    assert_equal "2357384227378429949", photos.first.aid
  end

  def test_prepare_publish_to_options_pass_only_neccessary_parameters
    options = @user.prepare_publish_to_options(@user, {:message => 'Hey there', :action_links => [:text => 'Link', :href => 'http://example.com']})
    assert_equal(options[:uid], @user.uid)
    assert_equal(options[:target_id], @user.id)
    assert_equal(options[:message], 'Hey there')
    assert_nil(options[:attachment])
    assert_equal(options[:action_links], [:text => 'Link', :href => 'http://example.com'].to_json )
  end

  def test_prepare_publish_to_options_to_page_on_behave_of_page
    page_id = 12345678
    options = @user.prepare_publish_to_options(@user, {:uid => 12345678, :post_as_page => true, :message => 'Hey there', :action_links => [:text => 'Link', :href => 'http://example.com']})
    assert_equal(options[:uid], page_id)
    assert_nil(options[:target_id])
    assert_equal(options[:message], 'Hey there')
    assert_nil(options[:attachment])
    assert_equal(options[:action_links], [:text => 'Link', :href => 'http://example.com'].to_json )
  end

  def test_publish_to
    @user = Facebooker::User.new(548871286, @session)
    expect_http_posts_with_responses(example_profile_publish_to_get_xml)
    @user.publish_to(@other_user, :message => 'i love you man')
  end

  def test_publish_to_converts_attachment_to_json
    @user = Facebooker::User.new(548871286, @session)
    @user.session.expects(:post).with("facebook.stream.publish",has_entry(:attachment=>instance_of(String)),false)
    @user.publish_to(@other_user, :message => 'i love you man',:attachment=>{:a=>"b"})
  end

  def test_publish_to_converts_attachment_from_attachment_objecect
    @user = Facebooker::User.new(548871286, @session)
    @user.session.expects(:post).with("facebook.stream.publish",has_entry(:attachment=>instance_of(String)),false)
    attachment = Facebooker::Attachment.new
    attachment.name = "My name"
    @user.publish_to(@other_user, :message => 'i love you man',:attachment=>attachment)
  end

  def test_comment_on
    @user = Facebooker::User.new(548871286, @session)
    expect_http_posts_with_responses(example_comment_on_response)
    assert_equal('703826862_78463536863', @user.comment_on('703826862_78463536862', :message => 'that was hilarious!'))
  end
  
  def test_add_comment
    @user = Facebooker::User.new(548871286, @session)
    expect_http_posts_with_responses(example_add_comment_response)
    assert_equal('403917', @user.add_comment('test_xid','that was realy hilarious!') )
  end

  def test_add_like_on
    @user = Facebooker::User.new(548871286, @session)
    expect_http_posts_with_responses(example_add_like_on_response)
    assert_equal('1', @user.add_like_on('703826862_78463536862'))
  end

  def test_remove_like_on
    @user = Facebooker::User.new(548871286, @session)
    expect_http_posts_with_responses(example_remove_like_on_response)
    assert_equal(true, @user.remove_like_on('703826862_78463536862'))
  end

  def test_can_send_email
    @user.expects(:send_email).with("subject", "body text")
    @user.send_email("subject", "body text")

    @user.expects(:send_email).with("subject", nil, "body fbml")
    @user.send_email("subject", nil, "body fbml")
  end

  def test_doesnt_post_to_facebook_when_assigning_status
    @session.expects(:post).never
    @user.status="my status"
  end
  def test_can_set_status_with_string
    @session.expects(:post).with('facebook.users.setStatus', {:status=>"my status",:status_includes_verb=>1, :uid => @user.uid}, false)
    @user.set_status("my status")
  end

  def test_get_events
    @user = Facebooker::User.new(9507801, @session)
    expect_http_posts_with_responses(example_events_get_xml)
    events = @user.events
    assert_equal 29511517904, events.first.eid
  end

  def test_events_caching_honors_params
    @user = Facebooker::User.new(9507801, @session)
    @session.expects(:post).returns([{:eid=>1}])
    assert_equal 1,@user.events.first.eid
    @session.expects(:post).returns([{:eid=>2}])
    assert_equal 2,@user.events(:start_time=>1.day.ago).first.eid
    @session.expects(:post).never
    assert_equal 1,@user.events.first.eid
  end


  def test_to_s
    assert_equal("1234",@user.to_s)
  end

  def test_equality_with_same_id
    assert_equal @user, @user.dup
    assert_equal @user, Facebooker::User.new(:id => @user.id)
  end

  def test_not_equal_to_differnt_class
    assert_not_equal @user, flexmock(:id => @user.id)
  end

  def test_hash_email
    assert_equal "4228600737_c96da02bba97aedfd26136e980ae3761", Facebooker::User.hash_email("mary@example.com")
  end
  def test_hash_email_not_normalized
    assert_equal "4228600737_c96da02bba97aedfd26136e980ae3761", Facebooker::User.hash_email(" MaRy@example.com  ")
  end

  def test_register_with_array
    expect_http_posts_with_responses(register_response_xml)
    assert_equal ["4228600737_c96da02bba97aedfd26136e980ae3761"],Facebooker::User.register([{:email=>"mary@example.com",:account_id=>1}])
  end

  def test_unregister_with_array
    expect_http_posts_with_responses(unregister_response_xml)
    assert_equal ["4228600737_c96da02bba97aedfd26136e980ae3761"],Facebooker::User.unregister(["4228600737_c96da02bba97aedfd26136e980ae3761"])
  end

  def test_unregister_emails_with_array
    expect_http_posts_with_responses(unregister_response_xml)
    assert_equal ["mary@example.com"],Facebooker::User.unregister_emails(["mary@example.com"])
  end

  def test_register_with_array_raises_if_not_all_success
    expect_http_posts_with_responses(register_response_xml)
    assert_equal ["4228600737_c96da02bba97aedfd26136e980ae3761"],Facebooker::User.register([{:email=>"mary@example.com",:account_id=>1},{:email=>"mike@example.com",:account_id=>2}])
    fail "Should have raised Facebooker::Session::UserRegistrationFailed"
  rescue Facebooker::Session::UserRegistrationFailed => e
    assert_equal({:email=>"mike@example.com",:account_id=>2},e.failed_users.first)
  end

  def test_unregister_with_array_raises_if_not_all_success
    expect_http_posts_with_responses(unregister_response_xml)
    assert_equal ["4228600737_c96da02bba97aedfd26136e980ae3761"],Facebooker::User.unregister(["4228600737_c96da02bba97aedfd26136e980ae3761","3587916587_791214eb452bf4de30e957d65a0234d4"])
    fail "Should have raised Facebooker::Session::UserUnRegistrationFailed"
  rescue Facebooker::Session::UserUnRegistrationFailed => e
    assert_equal("3587916587_791214eb452bf4de30e957d65a0234d4",e.failed_users.first)
  end

  def test_unregister_emails_with_array_raises_if_not_all_success
    expect_http_posts_with_responses(unregister_response_xml)
    assert_equal ["mary@example.com"],Facebooker::User.unregister_emails(["mary@example.com","mike@example.com"])
    fail "Should have raised Facebooker::Session::UserUnRegistrationFailed"
  rescue Facebooker::Session::UserUnRegistrationFailed => e
    assert_equal("mike@example.com",e.failed_users.first)
  end


  def test_get_locale
    @user = Facebooker::User.new(9507801, @session)
    expect_http_posts_with_responses(example_users_get_info_xml)
    assert_equal "en_US", @user.locale
  end

  def test_get_profile_url
    @user = Facebooker::User.new(8055, @session)
    expect_http_posts_with_responses(example_users_get_info_xml)
    assert_equal "http://www.facebook.com/profile.php?id=8055", @user.profile_url
  end

  def test_can_rsvp_to_event
    expect_http_posts_with_responses(example_events_rsvp_xml)
    result = @user.rsvp_event(1000, 'attending')
    assert result
  end
  
  # Dashboard count APIs
  
  def test_can_set_dashboard_count
    @session.expects(:post).with('facebook.dashboard.setCount', {:uid => @user.uid, :count => 12})
    @user.dashboard_count = 12
  end

  def test_parse_set_dashboard_count
    expect_http_posts_with_responses(dashboard_set_count_xml)
    assert_equal 12, @user.dashboard_count = 12
  end

  def test_can_increment_dashboard_count
    @session.expects(:post).with('facebook.dashboard.incrementCount', {:uid => @user.uid})
    @user.dashboard_increment_count
  end

  def test_parse_increment_dashboard_count
    expect_http_posts_with_responses(dashboard_increment_count_xml)
    assert_equal true, @user.dashboard_increment_count
  end

  def test_can_decrement_dashboard_count
    @session.expects(:post).with('facebook.dashboard.decrementCount', {:uid => @user.uid})
    @user.dashboard_decrement_count
  end

  def test_parse_decrement_dashboard_count
    expect_http_posts_with_responses(dashboard_decrement_count_xml)
    assert_equal true, @user.dashboard_decrement_count
  end

  def test_can_get_dashboard_count
    @session.expects(:post).with('facebook.dashboard.getCount', {:uid => @user.uid}).returns(12)
    @user.dashboard_count
  end
  
  def test_threads_should_return_an_array_of_thread_instances_containing_messages_and_attachments
    expect_http_posts_with_responses(example_threads)
    threads = @user.threads
    assert_not_nil threads
    assert_instance_of Array, threads
    assert_operator threads.size, :>, 0
    for thread in threads
      assert_instance_of Facebooker::MessageThread, thread
      assert_instance_of Array, thread.messages
      assert_operator thread.messages.size, :>, 0
      assert_instance_of Facebooker::MessageThread::Message, thread.messages.first
      
      for message in thread.messages
        next if message.attachment.blank?
        assert_instance_of Facebooker::MessageThread::Message::Attachment, message.attachment
        
        case message.message_id
        when '1344434538976_0'
          assert message.attachment.photo?, 'Attachment of message "1344434538976_0" should be a photo'
        when '1344434538976_2'
          assert message.attachment.link?, 'Attachment of message "1344434538976_2" should be a link'
        when '1012985167472_0'
          assert message.attachment.video?, 'Attachment of message "1012985167472_0" should be a video'
        end
      end
    end
  end

  def test_threads_should_return_populated_fields
    expect_http_posts_with_responses(example_threads)
    threads = @user.threads
    
    thread = threads.first
    [:thread_id, :subject, :updated_time, :recipients, :parent_message_id, :parent_thread_id,
      :message_count, :snippet, :snippet_author, :object_id, :unread].each do |field|
      assert_not_nil thread.__send__(field), "Field #{field} should not be nil"
    end
  end

  def test_parse_get_dashboard_count
    expect_http_posts_with_responses(dashboard_get_count_xml)
    assert_equal '12', @user.dashboard_count
  end
  
  def test_can_dashboard_multi_set_count
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiSetCount', :ids => { '1234' => '11', '5678' => '22' }.to_json)
    Facebooker::User.dashboard_multi_set_count({ '1234' => '11', '5678' => '22' })
  end
  
  def test_parse_dashboard_multi_set_count
    expect_http_posts_with_responses(dashboard_multi_set_count_xml)
    assert_equal({ '1234' => true, '4321' => true }, Facebooker::User.dashboard_multi_set_count({ '1234' => '11', '5678' => '22' }))
  end
  
  def test_can_dashboard_multi_get_count
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiGetCount', :uids => ['1234', '4321'])
    Facebooker::User.dashboard_multi_get_count ['1234', '4321']
  end
  
  def test_parse_dashboard_multi_get_count
    expect_http_posts_with_responses(dashboard_multi_get_count_xml)
    assert_equal({ '1234' => '11', '4321' => '22' }, Facebooker::User.dashboard_multi_get_count(['1234', '4321']))
  end
  
  def test_can_dashboard_multi_increment_count_with_single_uid
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiIncrementCount', :uids => ['8675309'].to_json)
    Facebooker::User.dashboard_multi_increment_count 8675309
  end
  
  def test_can_dashboard_multi_increment_count_with_multiple_uids
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiIncrementCount', :uids => ['8675309', '555'].to_json)
    Facebooker::User.dashboard_multi_increment_count 8675309, 555
  end
  
  def test_can_dashboard_multi_increment_count_with_array_of_uids
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiIncrementCount', :uids => ['1234', '4321'].to_json)
    Facebooker::User.dashboard_multi_increment_count ['1234', '4321']
  end
  
  def test_parse_dashboard_multi_increment_count
    expect_http_posts_with_responses(dashboard_multi_increment_count_xml)
    assert_equal({ '1234' => true, '4321' => true }, Facebooker::User.dashboard_multi_increment_count(['1234', '4321']))
  end
  
  def test_can_dashboard_multi_decrement_count_with_single_uid
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiDecrementCount', :uids => ['99999999'].to_json)
    Facebooker::User.dashboard_multi_decrement_count 99999999
  end
  
  def test_can_dashboard_multi_decrement_count_with_multiple_uids
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiDecrementCount', :uids => ['1111', '2222'].to_json)
    Facebooker::User.dashboard_multi_decrement_count 1111, 2222
  end

  def test_parse_dashboard_multi_decrement_count_with_array_of_uids
    expect_http_posts_with_responses(dashboard_multi_decrement_count_xml)
    assert_equal({ '1234' => true, '4321' => true }, Facebooker::User.dashboard_multi_decrement_count(['1234', '4321']))
  end
  # Dashboard
  
  def test_can_get_news
    @session.expects(:post).with('facebook.dashboard.getNews', {:uid => @user.uid, :news_ids => ['123']})
    @user.get_news ['123']
  end
  
  def test_can_get_news
    @session.expects(:post).with('facebook.dashboard.getNews', {:uid => @user.uid, :news_ids => ['123']})
    @user.get_news ['123']
  end
  
  def test_parse_get_news
    expect_http_posts_with_responses(get_news_xml)
    assert_equal({"304847042079"=>{"fbid"=>"304847042079", "time"=>"1266020260510", "news"=>[{"action_link"=>{"href"=>"http://facebook.er/", "text"=>"I... I'm a test user"}, "message"=>"Hey, who are you?"}, {"action_link"=>{"href"=>"http://facebook.er/", "text"=>"I'm sorry"}, "message"=>"Stop using my application, nerd"}], "image"=>"http://facebook.er/icon.png"}}, @user.get_news(['304847042079']))
  end
  
  def test_can_add_news
    @session.expects(:post).with('facebook.dashboard.addNews', {:news => [{:message => 'Hi user', :action_link => {:text => 'Uh hey there app', :href => 'http://facebook.er/'}}], :uid => @user.uid, :image => 'http://facebook.er/icon.png'})
    @user.add_news [{ :message => 'Hi user', :action_link => { :text => "Uh hey there app", :href => 'http://facebook.er/' }}], 'http://facebook.er/icon.png'
  end
  
  def test_parse_add_news
    expect_http_posts_with_responses(add_news_xml)
    assert_equal("316446838026", @user.add_news([{ :message => 'Hi user', :action_link => { :text => "Uh hey there app", :href => 'http://facebook.er/' }}], 'http://facebook.er/icon.png'))
  end
  
  def test_can_clear_news
    @session.expects(:post).with('facebook.dashboard.clearNews', { :uid => @user.uid, :news_ids => ['123']})
    @user.clear_news '123'
  end
  
  def test_parse_clear_news
    expect_http_posts_with_responses(clear_news_xml)
    assert_equal({"362466171040"=>true}, @user.clear_news('362466171040'))
  end
  
  def test_can_multi_add_news
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiAddNews', { :uids => ['1234', '4321'], :news => [{ :message => 'Hi user', :action_link => { :text => "Uh hey there app", :href => 'http://facebook.er/' }}], :image => 'http://facebook.er/icon.png'})
    Facebooker::User.multi_add_news(['1234', '4321'], [{ :message => 'Hi user', :action_link => { :text => "Uh hey there app", :href => 'http://facebook.er/' }}], 'http://facebook.er/icon.png')
  end
  
  def test_parse_multi_add_news
    expect_http_posts_with_responses(multi_add_news_xml)
    assert_equal({"1234"=>"319103117527", "4321"=>"313954287803"}, Facebooker::User.multi_add_news(['1234', '4321'], [{ :message => 'Hi user', :action_link => { :text => "Uh hey there app", :href => 'http://facebook.er/' }}], 'http://facebook.er/icon.png'))
  end
  
  def test_can_multi_get_news
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiGetNews', { :ids => {"1234"=>["319103117527"], "4321"=>["313954287803"]}.to_json})
    Facebooker::User.multi_get_news({"1234"=>["319103117527"], "4321"=>["313954287803"]})
  end
  
  def test_parse_multi_get_news
    expect_http_posts_with_responses(multi_get_news_xml)
    assert_equal({"1234"=>{"319103117527"=>{"fbid"=>"319103117527", "time"=>"1266605866056", "news"=>[{"action_link"=>{"href"=>"http://facebook.er/", "text"=>"Uh hey there app"}, "message"=>"Hi user"}], "image"=>"http://facebook.er/icon.png"}}, "4321"=>{"313954287803"=>{"fbid"=>"313954287803", "time"=>"1266605866123", "news"=>[{"action_link"=>{"href"=>"http://facebook.er/", "text"=>"Uh hey there app"}, "message"=>"Hi user"}], "image"=>"http://facebook.er/icon.png"}}}, Facebooker::User.multi_get_news({"1234"=>["319103117527"], "4321"=>["313954287803"]}))
  end
  
  def test_can_multi_clear_news
    Facebooker::Session.any_instance.expects(:post).with('facebook.dashboard.multiClearNews', { :ids => {"1234"=>["319103117527"], "4321"=>["313954287803"]}.to_json})
    Facebooker::User.multi_clear_news({"1234"=>["319103117527"], "4321"=>["313954287803"]})
  end
  
  def test_parse_multi_clear_news
    expect_http_posts_with_responses(multi_clear_news_xml)
    assert_equal({"1234"=>{"319103117527"=>true}, "4321"=>{"313954287803"=>true}}, Facebooker::User.multi_clear_news({"1234"=>["319103117527"], "4321"=>["313954287803"]}))
  end
  
  def test_can_publish_activity
    @session.expects(:post).with('facebook.dashboard.publishActivity', { :activity => { :message => '{*actor*} rolled around', :action_link => { :text => 'Roll around too', :href => 'http://facebook.er/' }}.to_json})
    @user.publish_activity({ :message => '{*actor*} rolled around', :action_link => { :text => 'Roll around too', :href => 'http://facebook.er/' }})
  end
  
  def test_parse_publish_activity
    expect_http_posts_with_responses(publish_activity_xml)
    assert_equal('484161135393', @user.publish_activity({ :message => '{*actor*} rolled around', :action_link => { :text => 'Roll around too', :href => 'http://facebook.er/' }}))
  end
  
  def test_can_get_activity
    @session.expects(:post).with('facebook.dashboard.getActivity', { :activity_ids => ['123'] })
    @user.get_activity '123'
  end
  
  def test_parse_get_activity
    expect_http_posts_with_responses(get_activity_xml)
    assert_equal({"342454152268"=>{"fbid"=>"342454152268", "time"=>"1266607632567", "action_link"=>{"href"=>"http://facebook.er/", "text"=>"Roll around too"}, "message"=>"{*actor*} rolled around"}}, @user.get_activity('342454152268'))
  end
  
  def test_can_remove_activity
    @session.expects(:post).with('facebook.dashboard.removeActivity', { :activity_ids => ['123'] })
    @user.remove_activity ['123']
  end
  
  def test_parse_remove_activity
    expect_http_posts_with_responses(remove_activity_xml)
    assert_equal({"342454152268"=>true}, @user.remove_activity('123'))
  end

  
  private
  def example_profile_photos_get_xml
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <photos_get_response xmlns=\"http://api.facebook.com/1.0/\"
      xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
      xsi:schemaLocation=\"http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd\" list=\"true\">
       <photo>
         <pid>34585991612804</pid>
         <aid>2357384227378429949</aid>
         <owner>1240077</owner>
         <src>http://ip002.facebook.com/v11/135/18/8055/s1240077_30043524_2020.jpg</src>
         <src_big>http://ip002.facebook.com/v11/135/18/8055/n1240077_30043524_2020.jpg</src_big>
         <src_small>http://ip002.facebook.com/v11/135/18/8055/t1240077_30043524_2020.jpg</src_small>
         <link>http://www.facebook.com/photo.php?pid=30043524&amp;id=8055</link>
         <caption>From The Deathmatch (Trailer) (1999)</caption>
         <created>1132553361</created>
       </photo>
       <photo>
         <pid>34585991612805</pid>
         <aid>2357384227378429949</aid>
         <owner>1240077</owner>
         <src>http://ip002.facebook.com/v11/135/18/8055/s1240077_30043525_2184.jpg</src>
         <src_big>http://ip002.facebook.com/v11/135/18/8055/n1240077_30043525_2184.jpg</src_big>
         <src_small>http://ip002.facebook.com/v11/135/18/8055/t1240077_30043525_2184.jpg</src_small>
         <link>http://www.facebook.com/photo.php?pid=30043525&amp;id=8055</link>
         <caption>Mexico City, back cover of the CYHS Student Underground 1999.</caption>
         <created>1132553362</created>
       </photo>
    </photos_get_response>"
  end

  def example_events_get_xml
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <events_get_response xmlns=\"http://api.facebook.com/1.0/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd\" list=\"true\">
      <event>
        <eid>29511517904</eid>
        <name>PUMA SALE</name>
        <tagline/>
        <nid>0</nid>
        <pic>http://profile.ak.facebook.com/object3/370/66/s29511517904_6952.jpg</pic>
        <pic_big>http://profile.ak.facebook.com/object3/370/66/n29511517904_6952.jpg</pic_big>
        <pic_small>http://profile.ak.facebook.com/object3/370/66/t29511517904_6952.jpg</pic_small>
        <host>PUMA</host>
        <description>PUMA SALE</description>
        <event_type>Education</event_type>
        <event_subtype>Study Group</event_subtype>
        <start_time>1212166800</start_time>
        <end_time>1212364800</end_time>
        <creator>1234261165</creator>
        <update_time>1209768148</update_time>
        <location>PUMA LOT</location>
        <venue>
          <street>5 LYBERTY WAY</street>
          <city>Westford</city>
          <state>Massachusetts</state>
          <country>United States</country>
          <latitude>42.5792</latitude>
          <longitude>-71.4383</longitude>
        </venue>
      </event>
    </events_get_response>"
  end

  def example_users_get_info_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?> <users_getInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true"> <user> <uid>8055</uid> <about_me>This field perpetuates the glorification of the ego. Also, it has a character limit.</about_me> <activities>Here: facebook, etc. There: Glee Club, a capella, teaching.</activities> <affiliations list="true"> <affiliation> <nid>50453093</nid> <name>Facebook Developers</name> <type>work</type> <status/> <year/> </affiliation> </affiliations> <birthday>November 3</birthday> <books>The Brothers K, GEB, Ken Wilber, Zen and the Art, Fitzgerald, The Emporer's New Mind, The Wonderful Story of Henry Sugar</books> <current_location> <city>Palo Alto</city> <state>CA</state> <country>United States</country> <zip>94303</zip> </current_location> <education_history list="true"> <education_info> <name>Harvard</name> <year>2003</year> <concentrations list="true"> <concentration>Applied Mathematics</concentration> <concentration>Computer Science</concentration> </concentrations> </education_info> </education_history> <first_name>Dave</first_name> <hometown_location> <city>York</city> <state>PA</state> <country>United States</country> </hometown_location> <hs_info> <hs1_name>Central York High School</hs1_name> <hs2_name/> <grad_year>1999</grad_year> <hs1_id>21846</hs1_id> <hs2_id>0</hs2_id> </hs_info> <is_app_user>1</is_app_user> <has_added_app>1</has_added_app> <interests>coffee, computers, the funny, architecture, code breaking,snowboarding, philosophy, soccer, talking to strangers</interests> <last_name>Fetterman</last_name> <locale>en_US</locale> <meeting_for list="true"> <seeking>Friendship</seeking> </meeting_for> <meeting_sex list="true"> <sex>female</sex> </meeting_sex> <movies>Tommy Boy, Billy Madison, Fight Club, Dirty Work, Meet the Parents, My Blue Heaven, Office Space </movies> <music>New Found Glory, Daft Punk, Weezer, The Crystal Method, Rage, the KLF, Green Day, Live, Coldplay, Panic at the Disco, Family Force 5</music> <name>Dave Fetterman</name> <notes_count>0</notes_count> <pic>http://photos-055.facebook.com/ip007/profile3/1271/65/s8055_39735.jpg</pic> <pic_big>http://photos-055.facebook.com/ip007/profile3/1271/65/n8055_39735.jpg</pic_big> <pic_small>http://photos-055.facebook.com/ip007/profile3/1271/65/t8055_39735.jpg</pic_small> <pic_square>http://photos-055.facebook.com/ip007/profile3/1271/65/q8055_39735.jpg</pic_square> <political>Moderate</political> <profile_update_time>1170414620</profile_update_time> <profile_url>http://www.facebook.com/profile.php?id=8055</profile_url> <quotes/> <relationship_status>In a Relationship</relationship_status> <religion/> <sex>male</sex> <significant_other_id xsi:nil="true"/> <status> <message>Fast Company, November issue, page 84</message> <time>1193075616</time> </status> <timezone>-8</timezone> <tv>cf. Bob Trahan</tv> <wall_count>121</wall_count> <work_history list="true"> <work_info> <location> <city>Palo Alto</city> <state>CA</state> <country>United States</country> </location> <company_name>Facebook</company_name> <position>Software Engineer</position> <description>Tech Lead, Facebook Platform</description> <start_date>2006-01</start_date> <end_date/> </work_info> </work_history> </user> </users_getInfo_response>
    XML
  end

  def register_response_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <connect_registerUsers_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/facebook.xsd" list="true">
      <connect_registerUsers_response_elt>4228600737_c96da02bba97aedfd26136e980ae3761</connect_registerUsers_response_elt>
    </connect_registerUsers_response>
    XML
  end

  def unregister_response_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <connect_unregisterUsers_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/facebook.xsd" list="true">
      <connect_unregisterUsers_response_elt>4228600737_c96da02bba97aedfd26136e980ae3761</connect_unregisterUsers_response_elt>
    </connect_unregisterUsers_response>
    XML
  end

  def has_app_permission_response_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_hasAppPermission_response xmlns="http://api.facebook.com/1.0/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</users_hasAppPermission_response>
    XML
  end

  def is_app_user_true_response_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_isAppUser_response xmlns="http://api.facebook.com/1.0/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</users_isAppUser_response>
    XML
  end

  def is_app_user_false_response_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_isAppUser_response xmlns="http://api.facebook.com/1.0/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">0</users_isAppUser_response>
    XML
  end

  def example_profile_publish_to_get_xml
    <<-eoxml
<?xml version="1.0" encoding="UTF-8"?>
<stream_publish_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">703826862_78463536862</stream_publish_response>
    eoxml
  end

  def example_comment_on_response
    <<-eoxml
<?xml version="1.0" encoding="UTF-8"?>
<stream_addComment_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">703826862_78463536863</stream_addComment_response>
    eoxml
  end
  
  def example_add_comment_response
    <<-eoxml
<?xml version="1.0" encoding="UTF-8"?>
<comments_add_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">403917</comments_add_response>
    eoxml
  end
  
  def example_add_like_on_response
        <<-eoxml
    <?xml version="1.0" encoding="UTF-8"?>
    <stream_addLike_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</stream_addLike_response>
        eoxml
  end

  def example_remove_like_on_response
        <<-eoxml
    <?xml version="1.0" encoding="UTF-8"?>
    <stream_removeLike_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</stream_removeLike_response>
        eoxml
  end

  def example_events_rsvp_xml
      <<-E
      <?xml version="1.0" encoding="UTF-8"?>
      <events_rsvp_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1
      </events_rsvp_response>
    E
  end

  def example_threads
    <<-XML
<message_getThreadsInFolder_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
  <thread>
    <thread_id>1344434538976</thread_id>
    <subject>Test attachments</subject>
    <recipients list="true">
      <uid>1410850842</uid>
      <uid>662074872</uid>
    </recipients>
    <updated_time>1265723631</updated_time>
    <parent_message_id>0</parent_message_id>
    <parent_thread_id>0</parent_thread_id>
    <message_count>3</message_count>
    <snippet>one link attachment to a youtube video</snippet>
    <snippet_author>1410850842</snippet_author>
    <object_id>0</object_id>
    <unread>0</unread>
    <messages list="true">
      <message>
        <message_id>1344434538976_0</message_id>
        <author_id>662074872</author_id>
        <body>one photo attachment ,  4KB jpeg image</body>
        <created_time>1265723631</created_time>
        <attachment>
          <media list="true"/>
          <href>http://www.facebook.com/photo.php?pid=3358326&amp;id=662074872</href>
          <properties list="true"/>
          <icon>http://static.ak.fbcdn.net/rsrc.php/zB010/hash/9yvl71tw.gif</icon>
          <fb_object_type/>
          <fb_object_id/>
          <tagged_ids list="true"/>
        </attachment>
        <thread_id>1344434538976</thread_id>
      </message>
      <message>
        <message_id>1344434538976_1</message_id>
        <author_id>1410850842</author_id>
        <body>one link attachment (http://www.facebook.com/l/e46dd;google.fr)</body>
        <created_time>1265723941</created_time>
        <attachment>
          <media list="true">
            <stream_media>
              <href>http://www.facebook.com/l.php?u=http%253A%252F%252Fwww.google.fr%252F&amp;h=e46dd63cdbfadb74958fbe44e98f339c</href>
              <type>link</type>
              <src>http://external.ak.fbcdn.net/safe_image.php?d=dd54bba6b6e6479a89bb8084573c02c8&amp;w=90&amp;h=90&amp;url=http%3A%2F%2Fwww.google.fr%2Fintl%2Ffr_fr%2Fimages%2Flogo.gif</src>
            </stream_media>
          </media>
          <name>Google</name>
          <href>http://www.facebook.com/l.php?u=http%253A%252F%252Fwww.google.fr%252F&amp;h=e46dd63cdbfadb74958fbe44e98f339c</href>
          <caption>www.google.fr</caption>
          <properties list="true"/>
          <icon>http://static.ak.fbcdn.net/rsrc.php/zB010/hash/9yvl71tw.gif</icon>
          <fb_object_type/>
          <fb_object_id/>
          <tagged_ids list="true"/>
        </attachment>
        <thread_id>1344434538976</thread_id>
      </message>
      <message>
        <message_id>1344434538976_2</message_id>
        <author_id>1410850842</author_id>
        <body>one link attachment to a youtube video</body>
        <created_time>1265726503</created_time>
        <attachment>
          <media list="true">
            <stream_media>
              <href>http://www.facebook.com/l.php?u=http%253A%252F%252Fwww.youtube.com%252Fwatch%253Fv%253DAW-sNQUmUIM%2526feature%253Dpopular&amp;h=e46dd63cdbfadb74958fbe44e98f339c</href>
              <alt>super bowl 44 highlights saints vs colts</alt>
              <type>video</type>
              <src>http://external.ak.fbcdn.net/safe_image.php?d=66f4aa965e2ae4a20a11c6a8ae3e4b1b&amp;w=90&amp;h=90&amp;url=http%3A%2F%2Fi.ytimg.com%2Fvi%2FAW-sNQUmUIM%2F2.jpg</src>
              <video>
                <display_url>http://www.youtube.com/watch?v=AW-sNQUmUIM&amp;feature=popular</display_url>
                <source_url>http://www.youtube.com/v/AW-sNQUmUIM&amp;autoplay=1</source_url>
                <owner>1410850842</owner>
                <source_type>html</source_type>
              </video>
            </stream_media>
          </media>
          <name>super bowl 44 highlights saints vs colts</name>
          <href>http://www.facebook.com/l.php?u=http%253A%252F%252Fwww.youtube.com%252Fwatch%253Fv%253DAW-sNQUmUIM%2526feature%253Dpopular&amp;h=e46dd63cdbfadb74958fbe44e98f339c</href>
          <caption>www.youtube.com</caption>
          <description>NFL super bowl 44 highlights saints vs colts from south florida.</description>
          <properties list="true"/>
          <icon>http://static.ak.fbcdn.net/rsrc.php/z9XZ8/hash/976ulj6z.gif</icon>
          <fb_object_type/>
          <fb_object_id/>
          <tagged_ids list="true"/>
        </attachment>
        <thread_id>1344434538976</thread_id>
      </message>
    </messages>
  </thread>
  <thread>
    <thread_id>1012985167472</thread_id>
    <subject>Happy Holidays from the Facebook Platform Team</subject>
    <recipients list="true">
      <uid>220400</uid>
    </recipients>
    <updated_time>1230000685</updated_time>
    <parent_message_id>0</parent_message_id>
    <parent_thread_id>0</parent_thread_id>
    <message_count>1</message_count>
    <snippet>We wanted to take a moment and thank you for all of your great work and amazi...</snippet>
    <snippet_author>220400</snippet_author>
    <object_id>2205007948</object_id>
    <unread>0</unread>
    <messages list="true">
      <message>
        <message_id>1012985167472_0</message_id>
        <author_id>220400</author_id>
        <body>We wanted to take a moment and thank you for all of your great work and amazing applications that have helped make Facebook Platform the largest and fastest-growing social platform over the past year and a half. As we end 2008 there are over 660,000 of you worldwide building applications that give users more powerful ways to share and connect, and collectively your applications have reached nearly 140 million people.

Just recently, we've been excited to bring you Facebook Connect - allowing you to integrate the tools and features of Facebook Platform on your Websites, devices and desktop applications. In the next several months, we're looking forward to introducing additional improvements to help users more easily find your applications as well as launching the first sets of Verified Applications to users. If you haven't applied for verification yet, apply here:
http://developers.facebook.com/verification.php

Over the next year, we look forward to continued developments to improve Facebook Platform and help you reach and engage more users, and grow and sustain your business.  We would love your feedback and input on what you think is most important - please take a few minutes and answer our survey here: 

http://www.facebook.com/l/e46dd;https://www.questionpro.com/akira/TakeSurvey?id=1121648

From all of us at Facebook, we wish you and your families &quot;Happy Holidays,&quot; and we look forward to making the web even more social with you in 2009!</body>
        <created_time>1230000042</created_time>
        <attachment>
          <media list="true"/>
          <name>Feb 10, 2010 1:26pm</name>
          <href>http://www.facebook.com/video/video.php?v=12345</href>
          <properties list="true"/>
          <icon>http://static.ak.fbcdn.net/rsrc.php/zB010/hash/9yvl71tw.gif</icon>
          <fb_object_type/>
          <fb_object_id/>
          <tagged_ids list="true"/>
        </attachment>
        <thread_id>1012985167472</thread_id>
      </message>
    </messages>
  </thread>
</message_getThreadsInFolder_response>
    XML
  end

  
  def dashboard_get_count_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_getCount_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">12</dashboard_getCount_response>
    XML
  end
  
  def dashboard_set_count_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_setCount_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</dashboard_setCount_response>
    XML
  end
  
  def dashboard_increment_count_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_incrementCount_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</dashboard_incrementCount_response>
    XML
  end
  
  def dashboard_decrement_count_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_decrementCount_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</dashboard_decrementCount_response>
    XML
  end

  def dashboard_multi_set_count_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_multiSetCount_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_multiSetCount_response_elt key="1234">1</dashboard_multiSetCount_response_elt>
        <dashboard_multiSetCount_response_elt key="4321">1</dashboard_multiSetCount_response_elt>
      </dashboard_multiSetCount_response>
    XML
  end

  def dashboard_multi_get_count_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_multiGetCount_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_multiGetCount_response_elt key="1234">11</dashboard_multiGetCount_response_elt>
        <dashboard_multiGetCount_response_elt key="4321">22</dashboard_multiGetCount_response_elt>
      </dashboard_multiGetCount_response>
    XML
  end

  def dashboard_multi_increment_count_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_multiIncrementCount_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_multiIncrementCount_response_elt key="1234">1</dashboard_multiIncrementCount_response_elt>
        <dashboard_multiIncrementCount_response_elt key="4321">1</dashboard_multiIncrementCount_response_elt>
      </dashboard_multiIncrementCount_response>
    XML
  end

  def dashboard_multi_decrement_count_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_multiDecrementCount_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_multiDecrementCount_response_elt key="1234">1</dashboard_multiDecrementCount_response_elt>
        <dashboard_multiDecrementCount_response_elt key="4321">1</dashboard_multiDecrementCount_response_elt>
      </dashboard_multiDecrementCount_response>
    XML
  end

  def get_news_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_getNews_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_getNews_response_elt key="304847042079" list="true">
          <dashboard_getNews_response_elt_elt key="image">http://facebook.er/icon.png</dashboard_getNews_response_elt_elt>
          <dashboard_getNews_response_elt_elt key="news" list="true">
            <dashboard_getNews_response_elt_elt_elt list="true">
              <dashboard_getNews_response_elt_elt_elt_elt key="action_link" list="true">
                <dashboard_getNews_response_elt_elt_elt_elt_elt key="href">http://facebook.er/</dashboard_getNews_response_elt_elt_elt_elt_elt>
                <dashboard_getNews_response_elt_elt_elt_elt_elt key="text">I... I'm a test user</dashboard_getNews_response_elt_elt_elt_elt_elt>
              </dashboard_getNews_response_elt_elt_elt_elt>
              <dashboard_getNews_response_elt_elt_elt_elt key="message">Hey, who are you?</dashboard_getNews_response_elt_elt_elt_elt>
            </dashboard_getNews_response_elt_elt_elt>
            <dashboard_getNews_response_elt_elt_elt list="true">
              <dashboard_getNews_response_elt_elt_elt_elt key="action_link" list="true">
                <dashboard_getNews_response_elt_elt_elt_elt_elt key="href">http://facebook.er/</dashboard_getNews_response_elt_elt_elt_elt_elt>
                <dashboard_getNews_response_elt_elt_elt_elt_elt key="text">I'm sorry</dashboard_getNews_response_elt_elt_elt_elt_elt>
              </dashboard_getNews_response_elt_elt_elt_elt>
              <dashboard_getNews_response_elt_elt_elt_elt key="message">Stop using my application, nerd</dashboard_getNews_response_elt_elt_elt_elt>
            </dashboard_getNews_response_elt_elt_elt>
          </dashboard_getNews_response_elt_elt>
          <dashboard_getNews_response_elt_elt key="time">1266020260510</dashboard_getNews_response_elt_elt>
          <dashboard_getNews_response_elt_elt key="fbid">304847042079</dashboard_getNews_response_elt_elt>
        </dashboard_getNews_response_elt>
      </dashboard_getNews_response>
    XML
  end
  
  def add_news_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_addNews_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">316446838026</dashboard_addNews_response>
    XML
  end
  
  def clear_news_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_clearNews_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_clearNews_response_elt key="362466171040">1</dashboard_clearNews_response_elt>
      </dashboard_clearNews_response>
    XML
  end
  
  def multi_add_news_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_multiAddNews_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_multiAddNews_response_elt key="1234">319103117527</dashboard_multiAddNews_response_elt>
        <dashboard_multiAddNews_response_elt key="4321">313954287803</dashboard_multiAddNews_response_elt>
      </dashboard_multiAddNews_response>
    XML
  end
  
  def multi_get_news_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_multiGetNews_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_multiGetNews_response_elt key="1234" list="true">
          <dashboard_multiGetNews_response_elt_elt key="319103117527" list="true">
            <dashboard_multiGetNews_response_elt_elt_elt key="image">http://facebook.er/icon.png</dashboard_multiGetNews_response_elt_elt_elt>
            <dashboard_multiGetNews_response_elt_elt_elt key="news" list="true">
              <dashboard_multiGetNews_response_elt_elt_elt_elt list="true">
                <dashboard_multiGetNews_response_elt_elt_elt_elt_elt key="message">Hi user</dashboard_multiGetNews_response_elt_elt_elt_elt_elt>
                <dashboard_multiGetNews_response_elt_elt_elt_elt_elt key="action_link" list="true">
                  <dashboard_multiGetNews_response_elt_elt_elt_elt_elt_elt key="href">http://facebook.er/</dashboard_multiGetNews_response_elt_elt_elt_elt_elt_elt>
                  <dashboard_multiGetNews_response_elt_elt_elt_elt_elt_elt key="text">Uh hey there app</dashboard_multiGetNews_response_elt_elt_elt_elt_elt_elt>
                </dashboard_multiGetNews_response_elt_elt_elt_elt_elt>
              </dashboard_multiGetNews_response_elt_elt_elt_elt>
            </dashboard_multiGetNews_response_elt_elt_elt>
            <dashboard_multiGetNews_response_elt_elt_elt key="time">1266605866056</dashboard_multiGetNews_response_elt_elt_elt>
            <dashboard_multiGetNews_response_elt_elt_elt key="fbid">319103117527</dashboard_multiGetNews_response_elt_elt_elt>
          </dashboard_multiGetNews_response_elt_elt>
        </dashboard_multiGetNews_response_elt>
        <dashboard_multiGetNews_response_elt key="4321" list="true">
          <dashboard_multiGetNews_response_elt_elt key="313954287803" list="true">
            <dashboard_multiGetNews_response_elt_elt_elt key="image">http://facebook.er/icon.png</dashboard_multiGetNews_response_elt_elt_elt>
            <dashboard_multiGetNews_response_elt_elt_elt key="news" list="true">
              <dashboard_multiGetNews_response_elt_elt_elt_elt list="true">
                <dashboard_multiGetNews_response_elt_elt_elt_elt_elt key="message">Hi user</dashboard_multiGetNews_response_elt_elt_elt_elt_elt>
                <dashboard_multiGetNews_response_elt_elt_elt_elt_elt key="action_link" list="true">
                  <dashboard_multiGetNews_response_elt_elt_elt_elt_elt_elt key="href">http://facebook.er/</dashboard_multiGetNews_response_elt_elt_elt_elt_elt_elt>
                  <dashboard_multiGetNews_response_elt_elt_elt_elt_elt_elt key="text">Uh hey there app</dashboard_multiGetNews_response_elt_elt_elt_elt_elt_elt>
                </dashboard_multiGetNews_response_elt_elt_elt_elt_elt>
              </dashboard_multiGetNews_response_elt_elt_elt_elt>
            </dashboard_multiGetNews_response_elt_elt_elt>
            <dashboard_multiGetNews_response_elt_elt_elt key="time">1266605866123</dashboard_multiGetNews_response_elt_elt_elt>
            <dashboard_multiGetNews_response_elt_elt_elt key="fbid">313954287803</dashboard_multiGetNews_response_elt_elt_elt>
          </dashboard_multiGetNews_response_elt_elt>
        </dashboard_multiGetNews_response_elt>
      </dashboard_multiGetNews_response>
    XML
  end
  
  def multi_clear_news_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?><dashboard_multiClearNews_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_multiClearNews_response_elt key="1234" list="true">
          <dashboard_multiClearNews_response_elt_elt key="319103117527">1</dashboard_multiClearNews_response_elt_elt>
        </dashboard_multiClearNews_response_elt>
        <dashboard_multiClearNews_response_elt key="4321" list="true">
          <dashboard_multiClearNews_response_elt_elt key="313954287803">1</dashboard_multiClearNews_response_elt_elt>
        </dashboard_multiClearNews_response_elt>
      </dashboard_multiClearNews_response>
    XML
  end
  
  def publish_activity_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_publishActivity_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">484161135393</dashboard_publishActivity_response>
    XML
  end
  
  def get_activity_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_getActivity_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_getActivity_response_elt key="342454152268" list="true">
          <dashboard_getActivity_response_elt_elt key="message">{*actor*} rolled around</dashboard_getActivity_response_elt_elt>
          <dashboard_getActivity_response_elt_elt key="action_link" list="true">
            <dashboard_getActivity_response_elt_elt_elt key="href">http://facebook.er/</dashboard_getActivity_response_elt_elt_elt>
            <dashboard_getActivity_response_elt_elt_elt key="text">Roll around too</dashboard_getActivity_response_elt_elt_elt>
          </dashboard_getActivity_response_elt_elt>
          <dashboard_getActivity_response_elt_elt key="time">1266607632567</dashboard_getActivity_response_elt_elt>
          <dashboard_getActivity_response_elt_elt key="fbid">342454152268</dashboard_getActivity_response_elt_elt>
        </dashboard_getActivity_response_elt>
      </dashboard_getActivity_response>
    XML
  end
  
  def remove_activity_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <dashboard_removeActivity_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <dashboard_removeActivity_response_elt key="342454152268">1</dashboard_removeActivity_response_elt>
      </dashboard_removeActivity_response>
    XML
  end
  
end
