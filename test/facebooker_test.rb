require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'net/http_multipart_post'
class TestFacebooker < Test::Unit::TestCase

  def setup
    @api_key = "95a71599e8293s66f1f0a6f4aeab3df7"
    @secret_key = "3e4du8eea435d8e205a6c9b5d095bed1"
    ENV["FACEBOOK_API_KEY"] = @api_key
    ENV["FACEBOOK_SECRET_KEY"] = @secret_key
    @session = Facebooker::Session.create(@api_key, @secret_key)
    @desktop_session = Facebooker::Session::Desktop.create(@api_key, @secret_key)
    @service = Facebooker::Service.new('http://apibase.com', '/api/path', @api_key)
    @desktop_session.instance_variable_set("@service", @service)
  end

  def test_asset_host_callback_url
    Facebooker.set_asset_host_to_callback_url = true
    assert_equal true, Facebooker.set_asset_host_to_callback_url

    Facebooker.set_asset_host_to_callback_url = false
    assert_equal false, Facebooker.set_asset_host_to_callback_url
  end

  def test_session_must_be_created_from_api_key_and_secret_key
    assert_kind_of(Facebooker::Session, @session)
  end

  def test_session_can_tell_you_its_login_url
    assert_not_nil(@session.login_url)
    assert_equal("http://www.facebook.com/login.php?api_key=#{@api_key}&v=1.0", @session.login_url)
  end

  def test_desktop_session_returns_auth_toke_as_part_of_login_url
    @service = flexmock(@service).should_receive(:post).at_least.once.and_return(123)
    assert_kind_of(Facebooker::Session::Desktop, @desktop_session)
    assert_match(/auth_token=[a-z0-9A-Z]/, @desktop_session.login_url)
  end

  def test_service_posts_data_to_http_location
    flexmock(Net::HTTP).should_receive(:post_form).and_return(example_auth_token_xml)
    assert_equal("http://www.facebook.com/login.php?api_key=#{@api_key}&v=1.0&auth_token=3e4a22bb2f5ed75114b0fc9995ea85f1", @desktop_session.login_url)
  end

  # def test_serivce_post_file_delegates_to_post_multipart_form
  #   # flexmock(@service).should_receive(:url).and_return('url')
  #   # flexmock(Net::HTTP).expects(:post_multipart_form).with('url', {:method => 'facebook.auth.createToken'}).returns(example_auth_token_xml)
  #
  #   res = mock(:content_type => 'text/html', :code => '200', :body => '<html><body>my blog</body></html>')
  #   Net::HTTP.stubs(:get_response).once.with(uri).returns res
  #
  #   @service.post_file(:method => 'facebook.auth.createToken')
  # end

  def test_desktop_session_be_secured_and_activated_after_receiving_auth_token_and_logging_in
    establish_session
    assert_equal("5f34e11bfb97c762e439e6a5-8055", @session.instance_variable_get("@session_key"))
  end

  def test_desktop_session_uses_secret_api_key_for_hashing_until_user_authenticates
    assert_equal(@secret_key, @desktop_session.secret_for_method('facebook.auth.createToken'))
    establish_session(@desktop_session)
    assert_equal("ohairoflamao12345", @desktop_session.secret_for_method('anyNonAuthMethodName'))
  end

  def test_session_can_get_current_logged_in_user_id_and_will_cache
    establish_session
    flexmock(Net::HTTP).should_receive(:post_form).and_return(example_get_logged_in_user_xml)
    assert_equal(8055, @session.user.id)
  end

  def test_can_get_current_users_friends
    expect_http_posts_with_responses(example_friends_xml)
    assert_equal([222333, 1240079], @session.user.friends.map{|friend| friend.id})
  end

  def test_can_get_current_users_friend_lists
    expect_http_posts_with_responses(example_friend_lists_xml)
    assert_equal([12089150545, 16361710545], @session.user.friend_lists.map{|friend_list| friend_list.flid})
  end

  def test_can_get_info_for_instance_of_user
    populate_user_info
    @session.user.first_name = "Dave"
  end

  def test_can_get_info_for_one_or_more_users
    friends = populate_session_friends
    friend = friends.detect{|f| f.id == 222333}
    assert_equal('This field perpetuates the glorification of the ego.  Also, it has a character limit.',
                 friend.about_me)
    assert_equal('Facebook Developers', friend.affiliations.first.name)
    assert_equal('Friendship', friend.meeting_for.first)
    assert_equal('94303', friend.current_location.zip)
    assert_equal('York', friend.hometown_location.city)
    assert_equal('Harvard', friend.education_history.first.name)
    assert(friend.education_history.first.concentrations.include?("Computer Science"))
    assert_equal('Central York High School', friend.hs_info.hs1_name)
    assert_equal('female', friend.meeting_sex.first)
    assert_equal('I rule', friend.status.message)
  end

  def test_can_get_specific_info_for_one_or_more_users
    friends = populate_session_friends_with_limited_fields
    friend = friends.detect{|f| f.id == 222333}
    assert_equal('I rule', friend.status.message)
    assert_equal(nil, friend.hometown_location)
  end

  def test_can_handle_nil_data
    friends = populate_session_friends_with_nil_data
    friend = friends.detect{|f| f.id ==  222333}
    assert_equal(nil,friend.current_location)
    assert_equal(nil,friend.pic)
  end

  def test_session_can_expire_on_server_and_client_handles_appropriately
    expect_http_posts_with_responses(example_session_expired_error_response)
    assert_raises(Facebooker::Session::SessionExpired) {
      @session.user.friends
    }
  end


  def test_can_publish_story_to_users_feed
    expect_http_posts_with_responses(example_publish_story_xml)
    assert_nothing_raised {
      assert(@session.user.publish_story((s = Facebooker::Feed::Story.new; s.title = 'o hai'; s.body = '4srsly'; s)))
    }
  end


  def test_can_publish_action_to_users_feed
    expect_http_posts_with_responses(example_publish_action_xml)
    assert_nothing_raised {
      assert(@session.user.publish_action((s = Facebooker::Feed::Action.new; s.title = 'o hai'; s.body = '4srsly'; s)))
    }
  end

  def test_can_publish_templatized_action_to_users_feed
    expect_http_posts_with_responses(example_publish_templatized_action_xml)
    assert_nothing_raised {
      action = Facebooker::Feed::TemplatizedAction.new
      action.title_template = "{actor} did something"
      assert(@session.user.publish_templatized_action(action))
    }
  end

  def test_can_publish_templatized_action_to_users_feed_with_params_as_string
    json_data="{\"move\": \"punch\"}"
    action = Facebooker::Feed::TemplatizedAction.new
    action.title_template = "{actor} did something "
    action.title_data=json_data
    assert_equal action.to_params[:title_data],json_data
  end

  def test_can_publish_templatized_action_to_users_feed_with_params_as_hash
    json_data="{\"move\": \"punch\"}"
    hash={:move=>"punch"}
    hash.expects(:to_json).returns(json_data)
    action = Facebooker::Feed::TemplatizedAction.new
    action.title_template = "{actor} did something "
    action.title_data=hash
    assert_equal action.to_params[:title_data],json_data
  end

  def test_can_deactivate_template_bundle_by_id
    expect_http_posts_with_responses(example_deactivate_template_bundle_by_id_xml)
    assert_equal true, @session.post('facebook.feed.deactivateTemplateBundleByID', :template_bundle_id => 123)
  end

  def test_can_get_notifications_for_logged_in_user
    expect_http_posts_with_responses(example_notifications_get_xml)
    assert_equal("1", @session.user.notifications.messages.unread)
    assert_equal("0", @session.user.notifications.pokes.unread)
    assert_equal("1", @session.user.notifications.shares.unread)
  end

  def test_can_send_notifications
    expect_http_posts_with_responses(example_notifications_send_xml)
    assert_nothing_raised {
      user_ids = [123, 321]
      notification_fbml = "O HAI!!!"
      optional_email_fbml = "This would be in the email.  If this is not passed, facebook sends no mailz!"
      assert_equal('http://www.facebook.com/send_email.php?from=211031&id=52', @session.send_notification(user_ids, notification_fbml, optional_email_fbml))
    }
  end

  def test_can_send_emails
    expect_http_posts_with_responses(example_notifications_send_email_xml)
    assert_nothing_raised {
      user_ids = [123, 321]
      text = "Hi I am the text part of the email."
      fbml = "Hi I am the fbml version of the <b>email</a>"
      subject = "Somethign you should really pay attention to."
      assert_equal('123,321', @session.send_email(user_ids, subject,text,fbml ))
    }
  end

  def test_can_find_friends_who_have_installed_app
    expect_http_posts_with_responses(example_app_users_xml)
    assert_equal(2, @session.user.friends_with_this_app.size)
    assert_equal([222333, 1240079], @session.user.friends_with_this_app.map{|f| f.id})
  end

  def test_when_marshaling_a_session_object_only_enough_data_to_stay_authenticated_is_stored
    populate_session_friends
    assert_equal(2, @session.user.friends.size)
    reloaded_session = Marshal.load(Marshal.dump(@session))
    %w(@session_key @uid @expires @secret_from_session @auth_token).each do |iv_name|
      assert_not_nil(reloaded_session.instance_variable_get(iv_name))
    end
    assert_nil(reloaded_session.user.instance_variable_get("@friends"))
  end

  def test_sessions_can_be_infinite_or_can_expire
    establish_session
    assert(@session.expired?, "Session with expiry time #{@session.instance_variable_get('@expires')} occurred in the past and should be expired.")
    @session.instance_variable_set("@expires", 0)
    assert(@session.infinite?)
    assert(!@session.expired?)
  end

  def test_session_can_tell_you_if_it_has_been_secured
    mock = flexmock(Net::HTTP).should_receive(:post_form).and_return(example_auth_token_xml).once.ordered(:posts)
    mock.should_receive(:post_form).and_return(example_get_session_xml.sub(/1173309298/, (Time.now + 60).to_i.to_s)).once.ordered(:posts)
    @session.secure!
    assert(@session.secured?)
  end

  def test_can_get_photos_by_pids
    expect_http_posts_with_responses(example_get_photo_xml)
    photos = @session.get_photos([97503428461115590, 97503428461115573])
    assert_equal 2, photos.size
    assert_equal "Rooftop barbecues make me act funny", photos.first.caption
    assert_equal "97503428461115590", photos[0].id
  end

  def test_can_get_photos_by_subject_and_album
    expect_http_posts_with_responses(example_get_photo_xml)
    photos = @session.get_photos(nil, 22701786, 97503428432802022 )
    assert_equal '97503428432802022', photos.first.aid
  end

  def test_getting_photos_requires_arguments
    mock_http = establish_session
    assert_raise(ArgumentError) { @session.get_photos() }
  end

  def test_can_get_albums_for_user
    expect_http_posts_with_responses(example_user_albums_xml)
    assert_equal('Summertime is Best', @session.user.albums.first.name)
    assert_equal(2, @session.user.albums.size)
  end

  def test_can_get_albums_by_album_ids
    expect_http_posts_with_responses(example_user_albums_xml)
    albums = @session.get_albums([97503428432802022, 97503428432797817] )
    assert_equal('Summertime is Best', albums[0].name)
    assert_equal('Bonofon\'s Recital', albums[1].name)
  end

  def test_can_create_album
    expect_http_posts_with_responses(example_new_album_xml)
    assert_equal "My Empty Album", @session.user.create_album(:name => "My Empty Album", :location => "Limboland").name
  end

  def test_can_upload_photo
    mock_http = establish_session
    mock_http.should_receive(:post_multipart_form).and_return(example_upload_photo_xml).once.ordered(:posts)
    f = Net::HTTP::MultipartPostFile.new("image.jpg", "image/jpeg", "RAW DATA")
    assert_equal "Under the sunset", @session.user.upload_photo(f).caption
  end

  def test_can_get_photo_tags
    expect_http_posts_with_responses(example_photo_tags_xml)
    assert_instance_of Facebooker::Tag, @session.get_tags(:pids => 97503428461115571 ).first
  end

  # TODO: how to test that tags were created properly? Response doesn't contain much
  def test_can_tag_a_user_in_a_photo
    expect_http_posts_with_responses(example_add_tag_xml)
    assert !@session.add_tags(pid = 97503428461115571, x= 30.0, y = 62.5, tag_uid = 1234567890).nil?
  end

  def test_can_add_multiple_tags_to_photos
  end

  def test_can_get_coordinates_for_photo_tags
    expect_http_posts_with_responses(example_photo_tags_xml)
    tag = @session.get_tags([97503428461115571]).first
    assert_equal ['65.4248', '16.8627'], tag.coordinates
  end

  def test_can_upload_video
    mock_http = establish_session
    mock_http.should_receive(:post_multipart_form).and_return(example_upload_video_xml).once
    f = Net::HTTP::MultipartPostFile.new("party.mp4", "video/mpeg", "RAW DATA")
    assert_equal "Some Epic", @session.user.upload_video(f).title
  end

  def test_can_get_app_profile_fbml_for_user
    expect_http_posts_with_responses(example_get_fbml_xml)
    assert_match(/My profile!/, @session.user.profile_fbml)
  end

  def test_can_set_app_profile_fbml_for_user
    expect_http_posts_with_responses(example_set_fbml_xml)
    assert_nothing_raised {
      @session.user.profile_fbml = 'aha!'
    }
  end

  def test_get_logged_in_user
    expect_http_posts_with_responses(example_get_logged_in_user_xml)
    assert_equal 1240077, @session.post('facebook.users.getLoggedInUser', :session_key => @session.session_key)
  end

  def test_pages_get_info
    expect_http_posts_with_responses(example_pages_get_info_xml)
    info = {
      'page_id' => '4846711747',
      'name' => 'Kronos Quartet',
      'website' => 'http://www.kronosquartet.org',
      'company_overview' => ""
    }
    assert_equal [info], @session.post('facebook.pages.getInfo', :fields => ['company_overview', 'website', 'name', 'page_id'].join(','), :page_ids => [4846711747].join(','))
  end

  def test_pages_is_admin_true
    expect_http_posts_with_responses(example_pages_is_admin_true_xml)
    assert_equal true, @session.post('facebook.pages.isAdmin', :page_id => 123)
  end

  def test_pages_is_admin_false
    expect_http_posts_with_responses(example_pages_is_admin_false_xml)
    assert_equal false, @session.post('facebook.pages.isAdmin', :page_id => 123)
  end

  def test_pages_is_fan_true
    expect_http_posts_with_responses(example_pages_is_fan_true_xml)
    assert_equal true, @session.post('facebook.pages.isFan', :page_id => 123)
  end

  def test_pages_is_fan_false
    expect_http_posts_with_responses(example_pages_is_fan_false_xml)
    assert_equal false, @session.post('facebook.pages.isFan', :page_id => 123)
  end

  def test_users_set_status_true
    expect_http_posts_with_responses(example_users_set_status_true_xml)
    assert_equal true, @session.post('facebook.users.setStatus', :uid => 123, :status => 'message')
  end

  def test_users_set_status_false
    expect_http_posts_with_responses(example_users_set_status_false_xml)
    assert_equal false, @session.post('facebook.users.setStatus', :uid => 123, :status => 'message')
  end

  def test_desktop_apps_cannot_request_to_get_or_set_profile_fbml_for_any_user_other_than_logged_in_user
    mock_http = establish_session(@desktop_session)
    mock_http.should_receive(:post_form).and_return(example_friends_xml).once.ordered(:posts)
    assert_raises(Facebooker::NonSessionUser) {
      @desktop_session.user.friends.first.profile_fbml
    }
    assert_raises(Facebooker::NonSessionUser) {
      @desktop_session.user.friends.first.profile_fbml = "O rly"
    }
  end

  def test_revoke_authorization_true
    expect_http_posts_with_responses(example_revoke_authorization_true)
    assert_equal true, @session.post('facebook.auth.revokeAuthorization', :uid => 123)
  end
  
  def test_revoke_authorization_false
    expect_http_posts_with_responses(example_revoke_authorization_false)
    assert_equal false, @session.post('facebook.auth.revokeAuthorization', :uid => 123)
  end
  
  private
  def populate_user_info
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_user_info_xml).once
    @session.user.populate
  end

  def populate_user_info_with_limited_fields
    expect_http_posts_with_responses(example_limited_user_info_xml)
    @session.user.populate(:affiliations, :status, :meeting_for)
  end

  def populate_session_friends
    expect_http_posts_with_responses(example_friends_xml, example_user_info_xml)
    @session.user.friends!
  end

  def populate_session_friends_with_limited_fields
    expect_http_posts_with_responses(example_friends_xml, example_limited_user_info_xml)
    @session.user.friends!(:affiliations, :status, :meeting_for)
  end

  def populate_session_friends_with_nil_data
    expect_http_posts_with_responses(example_friends_xml, example_nil_user_info_xml)
    @session.user.friends!(:name, :current_location, :pic)
  end

  def sample_args_to_post
    {:method=>"facebook.auth.createToken", :sig=>"18b3dc4f5258a63c0ad641eebd3e3930"}
  end

  def example_pages_get_info_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <pages_getInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <page>
        <page_id>4846711747</page_id>
        <name>Kronos Quartet</name>
        <website>http://www.kronosquartet.org</website>
        <company_overview/>
      </page>
    </pages_getInfo_response>
    XML
  end

  def example_pages_is_admin_true_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
      <pages_isAdmin_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</pages_isAdmin_response>
    XML
  end

  def example_pages_is_admin_false_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
      <pages_isAdmin_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">0</pages_isAdmin_response>
    XML
  end

  def example_pages_is_fan_true_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
      <pages_isFan_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</pages_isFan_response>
    XML
  end

  def example_pages_is_fan_false_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
      <pages_isFan_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">0</pages_isFan_response>
    XML
  end

  def example_users_set_status_true_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
      <users_setStatus_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</users_setStatus_response>
    XML
  end

  def example_users_set_status_false_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
      <users_setStatus_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">0</users_setStatus_response>
    XML
  end

  def example_set_fbml_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
      <profile_setFBML_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</profile_setFBML_response>
    XML
  end

  def example_get_fbml_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <profile_getFBML_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
    &lt;fb:if-is-own-profile&gt;My profile!
    &lt;fb:else&gt; Not my profile!&lt;/fb:else&gt;
    &lt;/fb:if-is-own-profile&gt;
    </profile_getFBML_response>
    XML
  end

  def example_notifications_send_xml
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<notifications_send_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">http://www.facebook.com/send_email.php?from=211031&amp;id=52</notifications_send_response>
    XML
  end

	  def example_notifications_send_email_xml
	    <<-XML
	    <?xml version="1.0" encoding="UTF-8"?>
	<notifications_sendEmail_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">123,321</notifications_sendEmail_response>
	    XML
	  end

  def example_request_send_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <notifications_sendRequest_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">http://www.facebook.com/send_req.php?from=211031&id=6</notifications_sendRequest_response>
    XML
  end

  def example_notifications_get_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <notifications_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <messages>
        <unread>1</unread>
        <most_recent>1170644932</most_recent>
      </messages>
      <pokes>
        <unread>0</unread>
        <most_recent>0</most_recent>
      </pokes>
      <shares>
        <unread>1</unread>
        <most_recent>1170657686</most_recent>
      </shares>
      <friend_requests list="true">
        <uid>2231342839</uid>
        <uid>2231511925</uid>
        <uid>2239284527</uid>
      </friend_requests>
      <group_invites list="true"/>
      <event_invites list="true"/>
    </notifications_get_response>
    XML
  end

  def example_publish_story_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed_publishStoryToUser_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</feed_publishStoryToUser_response>
    XML
  end

  def example_publish_action_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed_publishActionOfUser_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</feed_publishActionOfUser_response>
    XML
  end

  def example_publish_templatized_action_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed_publishTemplatizedAction_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <feed_publishTemplatizedAction_response_elt>1</feed_publishTemplatizedAction_response_elt>
    </feed_publishTemplatizedAction_response>
    XML
  end

  def example_deactivate_template_bundle_by_id_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed_deactivateTemplateBundleByID_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/">1</feed_deactivateTemplateBundleByID_response>
    XML
  end

  def example_user_info_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_getInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <user>
        <uid>222333</uid>
        <about_me>This field perpetuates the glorification of the ego.  Also, it has a character limit.</about_me>
        <activities>Here: facebook, etc. There: Glee Club, a capella, teaching.</activities>
        <affiliations list="true">
          <affiliation>
            <nid>50453093</nid>
            <name>Facebook Developers</name>
            <type>work</type>
            <status/>
            <year/>
          </affiliation>
        </affiliations>
        <birthday>November 3</birthday>
        <books>The Brothers K, GEB, Ken Wilber, Zen and the Art, Fitzgerald, The Emporer's New Mind, The Wonderful Story of Henry Sugar</books>
        <current_location>
          <city>Palo Alto</city>
          <state>CA</state>
          <country>United States</country>
          <zip>94303</zip>
        </current_location>
        <education_history list="true">
          <education_info>
            <name>Harvard</name>
            <year>2003</year>
            <concentrations list="true">
              <concentration>Applied Mathematics</concentration>
              <concentration>Computer Science</concentration>
            </concentrations>
            <degree>Masters</degree>
          </education_info>
        </education_history>
        <first_name>Dave</first_name>
         <hometown_location>
           <city>York</city>
           <state>PA</state>
           <country>United States</country>
           <zip>0</zip>
         </hometown_location>
         <hs_info>
           <hs1_name>Central York High School</hs1_name>
           <hs2_name/>
           <grad_year>1999</grad_year>
           <hs1_id>21846</hs1_id>
           <hs2_id>0</hs2_id>
         </hs_info>
         <is_app_user>1</is_app_user>
         <has_added_app>1</has_added_app>
         <interests>coffee, computers, the funny, architecture, code breaking,snowboarding, philosophy, soccer, talking to strangers</interests>
         <last_name>Fetterman</last_name>
         <meeting_for list="true">
           <seeking>Friendship</seeking>
         </meeting_for>
         <meeting_sex list="true">
           <sex>female</sex>
         </meeting_sex>
         <movies>Tommy Boy, Billy Madison, Fight Club, Dirty Work, Meet the Parents, My Blue Heaven, Office Space </movies>
         <music>New Found Glory, Daft Punk, Weezer, The Crystal Method, Rage, the KLF, Green Day, Live, Coldplay, Panic at the Disco, Family Force 5</music>
         <name>Dave Fetterman</name>
         <notes_count>0</notes_count>
         <pic>http://photos-055.facebook.com/ip007/profile3/1271/65/s8055_39735.jpg</pic>
         <pic_big>http://photos-055.facebook.com/ip007/profile3/1271/65/n8055_39735.jpg</pic_big>
         <pic_small>http://photos-055.facebook.com/ip007/profile3/1271/65/t8055_39735.jpg</pic_small>
         <pic_square>http://photos-055.facebook.com/ip007/profile3/1271/65/q8055_39735.jpg</pic_square>
         <political>Moderate</political>
         <profile_update_time>1170414620</profile_update_time>
         <quotes/>
         <relationship_status>In a Relationship</relationship_status>
         <religion/>
         <sex>male</sex>
         <significant_other_id xsi:nil="true"/>
         <status>
           <message>I rule</message>
           <time>0</time>
         </status>
         <timezone>-8</timezone>
         <tv>cf. Bob Trahan</tv>
         <wall_count>121</wall_count>
         <work_history list="true">
           <work_info>
             <location>
               <city>Palo Alto</city>
               <state>CA</state>
               <country>United States</country>
             </location>
             <company_name>Facebook</company_name>
             <position>Software Engineer</position>
             <description>Tech Lead, Facebook Platform</description>
             <start_date>2006-01</start_date>
             <end_date/>
            </work_info>
         </work_history>
       </user>
       <user>
         <uid>1240079</uid>
         <about_me>I am here.</about_me>
         <activities>Party.</activities>
       </user>
    </users_getInfo_response>
    XML
  end

  def example_limited_user_info_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_getInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <user>
        <uid>222333</uid>
        <affiliations list="true">
          <affiliation>
            <nid>50453093</nid>
            <name>Facebook Developers</name>
            <type>work</type>
            <status/>
            <year/>
          </affiliation>
        </affiliations>
         <meeting_for list="true">
           <seeking>Friendship</seeking>
         </meeting_for>
         <status>
           <message>I rule</message>
           <time>0</time>
         </status>
       </user>
       <user>
         <uid>1240079</uid>
         <activities>Party.</activities>
       </user>
    </users_getInfo_response>
    XML
  end


  def example_nil_user_info_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_getInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <user>
        <uid>222333</uid>
        <name>Kevin Lochner</name>
        <current_location xsi:nil="true"/>
        <pic xsi:nil="true"/>
      </user>
    </users_getInfo_response>
    XML
  end


  def example_friends_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <friends_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <uid>222333</uid>
      <uid>1240079</uid>
    </friends_get_response>
    XML
  end

  def example_friend_lists_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <friends_getLists_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <friendlist>
    		<flid>12089150545</flid>
    		<name>Family</name>
  		</friendlist>
  		<friendlist>
    		<flid>16361710545</flid>
    		<name>Entrepreneuer</name>
  		</friendlist>
    </friends_getLists_response>
    XML
  end

  def example_get_logged_in_user_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_getLoggedInUser_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">1240077</users_getLoggedInUser_response>
    XML
  end

  def example_invalid_api_key_error_response
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <error_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <error_code>101</error_code>
      <error_msg>Invalid API key</error_msg>
      <request_args list="true">
        <arg>
          <key>v</key>
          <value>1.0</value>
        </arg>
        <arg>
          <key>method</key>
          <value>facebook.auth.createToken</value>
        </arg>
        <arg>
          <key>sig</key>
          <value>611f5f44e55f3fe17f858a8de84a4b0a</value>
        </arg>
        <arg>
          <key>call_id</key>
          <value>1186088346.82142</value>
        </arg>
      </request_args>
    </error_response>
    XML
  end

  def example_session_expired_error_response
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <error_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <error_code>102</error_code>
      <error_msg>Session Expired</error_msg>
      <request_args list="true">
        <arg>
          <key>v</key>
          <value>1.0</value>
        </arg>
        <arg>
          <key>method</key>
          <value>facebook.auth.createToken</value>
        </arg>
        <arg>
          <key>sig</key>
          <value>611f5f44e55f3fe17f858a8de84a4b0a</value>
        </arg>
        <arg>
          <key>call_id</key>
          <value>1186088346.82142</value>
        </arg>
      </request_args>
    </error_response>
    XML
  end

  def example_app_users_xml
    <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
      <friends_getAppUsers_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <uid>222333</uid>
        <uid>1240079</uid>
      </friends_getAppUsers_response>
    XML
  end

  def example_user_albums_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <photos_getAlbums_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <album>
        <aid>97503428432802022</aid>
        <cover_pid>97503428461115574</cover_pid>
        <owner>22701786</owner>
        <name>Summertime is Best</name>
        <created>1184120648</created>
        <modified>1185465771</modified>
        <description>Happenings on or around Summer '07</description>
        <location>Brooklyn, New York</location>
        <link>http://www.facebook.com/album.php?aid=2011366&amp;id=22701786</link>
        <size>49</size>
      </album>
      <album>
        <aid>97503428432797817</aid>
        <cover_pid>97503428460977993</cover_pid>
        <owner>22701786</owner>
        <name>Bonofon's Recital</name>
        <created>1165356279</created>
        <modified>1165382364</modified>
        <description>The whole Ewing fam flies out to flatland to watch the Bonofon's senior recital.  That boy sure can tinkle them ivories.</description>
        <location>Grinnell College, Grinnell Iowa</location>
        <link>http://www.facebook.com/album.php?aid=2007161&amp;id=22701786</link>
        <size>14</size>
      </album>
    </photos_getAlbums_response>
    XML
  end

  def example_upload_photo_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <photos_upload_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <pid>940915697041656</pid>
      <aid>940915667462717</aid>
      <owner>219074</owner>
      <src>http://ip002.facebook.com/v67/161/72/219074/s219074_31637752_5455.jpg</src>
      <src_big>http://ip002.facebook.com/v67/161/72/219074/n219074_31637752_5455.jpg</src_big>
      <src_small>http://ip002.facebook.com/v67/161/72/219074/t219074_31637752_5455.jpg</src_small>
      <link>http://www.facebook.com/photo.php?pid=31637752&amp;id=219074</link>
      <caption>Under the sunset</caption>
    </photos_upload_response>
    XML
  end

  def example_new_album_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <photos_createAlbum_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <aid>34595963571485</aid>
      <cover_pid>0</cover_pid>
      <owner>8055</owner>
      <name>My Empty Album</name>
      <created>1132553109</created>
      <modified>1132553363</modified>
      <description>No I will not make out with you</description>
      <location>York, PA</location>
      <link>http://www.facebook.com/album.php?aid=2002205&amp;id=8055</link>
      <size>0</size>
    </photos_createAlbum_response>
    XML
  end

  def example_photo_tags_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <photos_getTags_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <photo_tag>
        <pid>97503428461115571</pid>
        <subject>570070524</subject>
        <xcoord>65.4248</xcoord>
        <ycoord>16.8627</ycoord>
      </photo_tag>
    </photos_getTags_response>
    XML
  end

  def example_add_tag_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <photos_addTag_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</photos_addTag_response>
    XML
  end

  def example_get_photo_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <photos_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <photo>
        <pid>97503428461115590</pid>
        <aid>97503428432802022</aid>
        <owner>22701786</owner>
        <src>http://photos-c.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/s22701786_30324934_7816.jpg</src>
        <src_big>http://photos-c.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/n22701786_30324934_7816.jpg</src_big>
        <src_small>http://photos-c.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/t22701786_30324934_7816.jpg</src_small>
        <link>http://www.facebook.com/photo.php?pid=30324934&amp;id=22701786</link>
        <caption>Rooftop barbecues make me act funny</caption>
        <created>1184120987</created>
      </photo>
      <photo>
        <pid>97503428461115573</pid>
        <aid>97503428432802022</aid>
        <owner>22701786</owner>
        <src>http://photos-b.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/s22701786_30324917_4555.jpg</src>
        <src_big>http://photos-b.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/n22701786_30324917_4555.jpg</src_big>
        <src_small>http://photos-b.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/t22701786_30324917_4555.jpg</src_small>
        <link>http://www.facebook.com/photo.php?pid=30324917&amp;id=22701786</link>
        <caption/>
        <created>1184120654</created>
      </photo>
    </photos_get_response>
    XML
  end

  def example_upload_video_xml
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<video_upload_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
    <vid>15943367753</vid>
    <title>Some Epic</title>
    <description>Check it out</description>
    <link>http://www.facebook.com/video/video.php?v=15943367753</link>
  </video_upload_response>
    XML
  end
  
  def example_revoke_authorization_true
    "1"
  end
  
  def example_revoke_authorization_false
    "0"
  end
end
