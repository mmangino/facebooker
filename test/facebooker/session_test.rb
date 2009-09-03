require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'active_support'

class Facebooker::SessionTest < Test::Unit::TestCase


  def setup
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'
    Facebooker.current_adapter = nil
    @session = Facebooker::Session.create('whatever', 'doesnotmatterintest')
    Facebooker.use_curl=false
  end

  def teardown
    Facebooker::Session.configuration_file_path = nil
    super
  end

  def test_install_url_escapes_optional_next_parameter
    session = Facebooker::CanvasSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    assert_equal("http://www.facebook.com/install.php?api_key=1234567&v=1.0&next=next_url%3Fa%3D1%26b%3D2", session.install_url(:next => "next_url?a=1&b=2"))
  end

  def test_permission_url_returns_correct_url_and_parameters
    fb_url = "http://www.facebook.com/connect/prompt_permissions.php?api_key=#{ENV['FACEBOOK_API_KEY']}&v=1.0&next=next_url&ext_perm=publish_stream,email"
    url = Facebooker::Session.new(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY']).connect_permission_url('publish_stream,email', {:next => 'next_url'})
    assert_equal url, fb_url
  end

  def test_login_url_skips_all_parameters_when_not_passed_or_false
    session = Facebooker::Session.new(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    url = session.login_url({:fbconnect => false})
    expected_url = Facebooker.login_url_base
    assert_equal url, expected_url
  end

  def test_login_url_adds_all_parameters_when_passed
    login_options = {:skipcookie => true,
                     :hide_checkbox => true,
                     :canvas => true,
                     :fbconnect => true,
                     :req_perms => 'publish_stream',
                     :next => 'http://example.com'}

    session = Facebooker::Session.new(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    url = session.login_url(login_options)
    expected_url = "#{Facebooker.login_url_base}&next=#{CGI.escape(login_options[:next])}&hide_checkbox=true&canvas=true&fbconnect=true&req_perms=publish_stream"
    assert_equal url, expected_url
  end

  def test_can_get_api_and_secret_key_from_environment
    assert_equal('1234567', Facebooker::Session.api_key)
    assert_equal('7654321', Facebooker::Session.secret_key)
  end

  def test_if_keys_are_not_available_via_environment_then_they_are_gotten_from_a_file
    ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'] = nil
    Facebooker.instance_variable_set('@facebooker_configuration', nil)
    flexmock(File).should_receive(:read).with(File.expand_path("~/.facebookerrc")).once.and_return('{:api => "foo"}')
    assert_equal('foo', Facebooker::Session.api_key)
  end

  def test_if_environment_and_file_fail_to_match_then_an_exception_is_raised
    ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'] = nil
    Facebooker.instance_variable_set('@facebooker_configuration', nil)
    flexmock(File).should_receive(:read).with(File.expand_path("~/.facebookerrc")).once.and_return {raise Errno::ENOENT, "No such file"}
    assert_raises(Facebooker::Session::ConfigurationMissing) {
      Facebooker::Session.api_key
    }
  end

  def test_marshal_stores_api_key
    data = Marshal.dump(@session)
    loaded_session = Marshal.load(data)
    assert_equal 'whatever', loaded_session.instance_variable_get("@api_key")
  end

  def test_marshal_stores_secret_key
    data = Marshal.dump(@session)
    loaded_session = Marshal.load(data)
    assert_equal 'doesnotmatterintest', loaded_session.instance_variable_get("@secret_key")
  end

  def test_configuration_file_path_can_be_set_explicitly
    Facebooker::Session.configuration_file_path = '/tmp/foo'
    assert_equal('/tmp/foo', Facebooker::Session.configuration_file_path)
  end

  def test_session_can_be_secured_with_existing_values
    session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    session.secure_with!("a session key", "123456", Time.now.to_i + 60)
    assert(session.secured?)
    assert_equal 'a session key', session.session_key
    assert_equal 123456, session.user.to_i
  end

  def test_session_can_be_secured_with_existing_values_and_a_nil_uid
    flexmock(session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY']))
    session.should_receive(:post).with('facebook.users.getLoggedInUser', :session_key => 'a session key').returns(321)
    session.secure_with!("a session key", nil, Time.now.to_i + 60)
    assert(session.secured?)
    assert_equal 'a session key', session.session_key
    assert_equal 321, session.user.to_i
  end

  # The Facebook API for this is hideous.  Oh well.
  def test_can_ask_session_to_check_friendship_between_pairs_of_users
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_check_friendship_xml).once.ordered(:posts)
    assert_equal({[222332, 222333] => true, [1240077, 1240079] => false}, @session.check_friendship([[222332, 222333], [1240077, 1240079]]))
  end

  def test_facebook_can_claim_ignorance_as_to_friend_relationships
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_check_friendship_with_unknown_result).once.ordered(:posts)
    assert_equal({[1240077, 1240079] => nil}, @session.check_friendship([[1240077, 1240079]]))
  end

  def test_can_query_with_fql
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    expect_http_posts_with_responses(example_fql_for_multiple_photos_xml)
    response = @session.fql_query('Lets be frank. We are not testing the query here')
    assert_kind_of(Facebooker::Photo, response.first)
  end

  def test_anonymous_fql_results_get_put_in_a_positioned_array_on_the_model
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    expect_http_posts_with_responses(example_fql_for_multiple_photos_with_anon_xml)
    response = @session.fql_query('Lets be frank. We are not testing the query here')
    assert_kind_of(Facebooker::Photo, response.first)
    response.each do |photo|
      assert_equal(['first', 'second'], photo.anonymous_fields)
    end
  end
  def test_no_results_returns_empty_array
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    expect_http_posts_with_responses(no_results_fql)
    response = @session.fql_query('Lets be frank. We are not testing the query here')
    assert_equal [],response
  end

  def test_can_fql_query_for_event_members
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    expect_http_posts_with_responses(example_fql_query_event_members_xml)
    response = @session.fql_query("DOES NOT REALLY MATTER FOR TEST")
    assert_kind_of(Facebooker::Event::Attendance, response.first)
    assert_equal('attending', response.first.rsvp_status)
  end

  def test_can_query_for_event_members
    expect_http_posts_with_responses(example_event_members_xml)
    event_attendances = @session.event_members(69)
    assert_equal Facebooker::Event::Attendance, event_attendances.first.class
    assert_equal 'attending', event_attendances.first.rsvp_status
    assert_equal(["1240077", "222332", "222333", "222335", "222336"], event_attendances.map{|ea| ea.uid}.sort)
    assert_equal 5, event_attendances.size
  end

  def test_can_query_for_events
    expect_http_posts_with_responses(example_events_get_xml)
    events = @session.events
    assert_equal 'Technology Tasting', events.first.name
  end

  def test_can_query_for_groups
    expect_http_posts_with_responses(example_groups_get_xml)
    groups = @session.user.groups
    assert_equal 'Donald Knuth Is My Homeboy', groups.first.name
  end

  def test_can_query_for_group_memberships
    expect_http_posts_with_responses(example_group_members_xml)
    example_group = Facebooker::Group.new({:gid => 123, :session => @session})
    group_memberships = example_group.memberships
    assert_equal('officers', group_memberships.last.position)
    assert_equal(123, group_memberships.last.gid)
    assert_equal(1240078, example_group.members.last.id)
  end

  def test_can_fql_query_for_users_and_pictures
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_fql_for_multiple_users_and_pics).once.ordered(:posts)
    response = @session.fql_query('SELECT name, pic FROM user WHERE uid=211031 OR uid=4801660')
    assert_kind_of Array, response
    assert_kind_of Facebooker::User, response.first
    assert_equal "Ari Steinberg", response.first.name
  end

  def test_can_fql_multiquery_for_users_and_pictures
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_fql_multiquery_xml).once.ordered(:posts)
    response = @session.fql_multiquery({:query => 'SELECT name, pic FROM user WHERE uid=211031 OR uid=4801660'})
    assert_kind_of Array, response["query1"]
    assert_kind_of Facebooker::User, response["query1"].first
    assert_equal "Ari Steinberg", response["query1"].first.name
  end

  def test_can_send_notification_with_object
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.expects(:post).with('facebook.notifications.send',{:to_ids=>"1",:notification=>"a",:type=>"user_to_user"},true)
    @session.send(:instance_variable_set,"@uid",3)
    user=flexmock("user")
    user.should_receive(:facebook_id).and_return("1").once
    @session.send_notification([user],"a")
  end
  def test_can_send_notification_with_string
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.send(:instance_variable_set,"@uid",3)
    @session.expects(:post).with('facebook.notifications.send',{:to_ids=>"1",:notification=>"a", :type=>"user_to_user"},true)
    @session.send_notification(["1"],"a")
  end

  def test_can_send_announcement_notification
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.expects(:post).with('facebook.notifications.send',{:to_ids=>"1",:notification=>"a", :type=>"app_to_user"},false)
    @session.send_notification(["1"],"a")
  end

  def test_can_register_template_bundle
    expect_http_posts_with_responses(example_register_template_bundle_return_xml)
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    assert_equal 17876842716, @session.register_template_bundle("{*actor*} did something")
  end

  def test_can_register_template_bundle_with_action_links
    expect_http_posts_with_responses(example_register_template_bundle_return_xml)
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    assert_equal 17876842716, @session.register_template_bundle("{*actor*} did something",nil,nil,[{:text=>"text",:href=>"href"}])
  end
  
  def test_can_register_template_bundle_with_short_story
    one_line = "{*actor*} did something"
    short_story = { :title => 'title', :body => 'body' }
    
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.expects(:post).with(
      'facebook.feed.registerTemplateBundle',
      {:one_line_story_templates => [one_line].to_json, :short_story_templates => [short_story].to_json},
      false
    )
    @session.register_template_bundle(one_line, short_story)
  end
  
  def test_can_register_template_bundle_with_short_story_for_several_templates
    one_line = ["{*actor*} did something", "{*actor*} did something again"]
    short_story = [{ :title => 'title', :body => 'body' }, { :title => 'title2', :body => 'body2' }]
    
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.expects(:post).with(
      'facebook.feed.registerTemplateBundle',
      {:one_line_story_templates => one_line.to_json, :short_story_templates => short_story.to_json},
      false
    )
    @session.register_template_bundle(one_line, short_story)
  end
  
  def test_can_register_template_bundle_with_full_story_for_several_templates
    one_line = ["{*actor*} did something", "{*actor*} did something again"]
    short_story = [{ :title => 'title', :body => 'body' }, { :title => 'title2', :body => 'body2' }]
    full_story = { :title => 'title', :body => 'body' }
    
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.expects(:post).with(
      'facebook.feed.registerTemplateBundle',
      {:one_line_story_templates => one_line.to_json, :short_story_templates => short_story.to_json, :full_story_template => full_story.to_json},
      false
    )
    @session.register_template_bundle(one_line, short_story, full_story)
  end
  
  def test_can_deactivate_template_bundle_by_id
    @session = Facebooker::Session.create(ENV['FACBEOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.expects(:post).with(
      'facebook.feed.deactivateTemplateBundleByID',
      {:template_bundle_id => '999'},
      false
    )
    @session.deactivate_template_bundle_by_id(999)
  end

  def test_can_publish_user_action
    expect_http_posts_with_responses(publish_user_action_return_xml)
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    assert @session.publish_user_action(17876842716,{})
  end

  def test_logs_api_calls
    call_name = 'sample.api.call'
    params = { :param1 => true, :param2 => 'value' }
    flexmock(Facebooker::Logging, :Logging).should_receive(:log_fb_api).once.with(
       call_name, params, Proc)
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.post(call_name, params)
  end

  def test_requests_inside_batch_are_added_to_batch
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    @session.send(:service).expects(:post).once
    @session.batch do
      @session.send_notification(["1"],"a")
      @session.send_notification(["1"],"a")
    end

  end

  def test_parses_batch_response
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    expect_http_posts_with_responses(example_batch_run_xml)
    @session.batch do
      @fql_response = @session.fql_query('SELECT name, pic FROM user WHERE uid=211031 OR uid=4801660')
    end
    assert_kind_of(Facebooker::Event::Attendance, @fql_response.first)
    assert_equal('attending', @fql_response.first.rsvp_status)
  end
  def test_parses_batch_response_sets_exception
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    expect_http_posts_with_responses(example_batch_run_xml)
    Facebooker::FqlQuery.expects(:process).raises(NoMethodError.new)

    @session.batch do
      @fql_response = @session.fql_query('SELECT name, pic FROM user WHERE uid=211031 OR uid=4801660')
    end
    assert_raises(NoMethodError) {
      @fql_response.first
    }
  end

  def test_can_set_and_get_current_batch
    Facebooker::BatchRun.current_batch=4
    assert_equal 4,Facebooker::BatchRun.current_batch
  end

  def test_can_get_stanard_info
    expect_http_posts_with_responses(standard_info_xml)
    result = @session.users_standard([4])
    assert_equal "Mike Mangino",result.first.name
  end

  def test_can_query_for_pages
    expect_http_posts_with_responses(example_pages_xml)
    example_page = Facebooker::Page.new(
      :page_id => 4846711747,
      :name => "Kronos Quartet",
      :website => "http://www.kronosquartet.org",
      :company_overview => "",
      :session => @session)
    pages = @session.pages(:fields => %w[ page_id name website company_overview ])

    assert_equal 1, pages.size

    page = pages.first
    assert_equal "4846711747", page.page_id
    assert_equal "Kronos Quartet", page.name
    assert_equal "http://www.kronosquartet.org", page.website

    # TODO we really need a way to differentiate between hash/list and text attributes
    # assert_equal({}, page.company_overview)

    # sakkaoui : as a fix to the parser, I replace empty text node by "" instead of {}
    # we have child.attributes['list'] == 'true' that let us know that we have a hash/list.
    assert_equal("", page.company_overview)

    genre = page.genre
    assert_equal false, genre.dance
    assert_equal true, genre.party
  end

  private

  def example_fql_multiquery_xml
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<fql_multiquery_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
  <fql_result>
    <name>query1</name>
    <results list="true">
      <user>
        <name>Ari Steinberg</name>
        <uid>46903192</uid>
        <rsvp_status xsi:nil="true"/>
      </user>
    </results>
  </fql_result>
  <fql_result>
    <name>query2</name>
    <results list="true">
      <user>
        <name>Lisa Petrovskaia</name>
        <pic xsi:nil="true"/>
      </user>
    </results>
  </fql_result>
</fql_multiquery_response>
XML
  end

  def example_groups_get_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <groups_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <group>
        <gid>2206609142</gid>
        <name>Donald Knuth Is My Homeboy</name>
        <nid>0</nid>
        <description>Donald Ervin Knuth (born January 10, 1938) is a renowned computer scientist and professor emeritus at Stanford University.

    Knuth is best known as the author of the multi-volume The Art of Computer Programming, one of the most highly respected references in the computer science field. He practically created the field of rigorous analysis of algorithms, and made many seminal contributions to several branches of theoretical computer science. He is also the creator of the TeX typesetting system and of the METAFONT font design system, and pioneered the concept of literate programming.

    That's how he ROLLS, y0.</description>
        <group_type>Just for Fun</group_type>
        <group_subtype>Fan Clubs</group_subtype>
        <recent_news/>
        <pic>http://photos-142.facebook.com/ip006/object/543/95/s2206609142_32530.jpg</pic>
        <pic_big>http://photos-142.facebook.com/ip006/object/543/95/n2206609142_32530.jpg</pic_big>
        <pic_small>http://photos-142.facebook.com/ip006/object/543/95/t2206609142_32530.jpg</pic_small>
        <creator>1240077</creator>
        <update_time>1156543965</update_time>
        <office/>
        <website/>
        <venue>
          <street/>
          <city/>
          <state>CA</state>
          <country>United States</country>
        </venue>
      </group>
    </groups_get_response>
    XML
  end

  def example_events_get_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <events_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <event>
        <eid>1037629024</eid>
        <name>Technology Tasting</name>
        <tagline>Who said Engineering can't be delicious?</tagline>
        <nid>12409987</nid>
        <pic>http://photos-628.facebook.com/ip006/object/1345/48/s1037629024_30775.jpg</pic>
        <pic_big>http://photos-628.facebook.com/ip006/object/1345/48/n1037629024_30775.jpg</pic_big>
        <pic_small>http://photos-628.facebook.com/ip006/object/1345/48/t1037629024_30775.jpg</pic_small>
        <host>Facebook</host>
        <description>Facebook will be hosting technology thought leaders and avid software engineers for a social evening of technology tasting. We invite you to connect with some of our newest technologies and innovative people over hors d'oeuvres and wine. Come share ideas, ask questions, and challenge existing technology paradigms in the spirit of the open source community.</description>
        <event_type>Party</event_type>
        <event_subtype>Cocktail Party</event_subtype>
        <start_time>1172107800</start_time>
        <end_time>1172115000</end_time>
        <creator>1078</creator>
        <update_time>1170096157</update_time>
        <location>Facebook's New Office</location>
        <venue>
          <city>Palo Alto</city>
          <state>CA</state>
          <country>United States</country>
        </venue>
      </event>
    </events_get_response>
    XML
  end

  def example_fql_query_event_members_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <fql_query_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" list="true">
      <event_member>
        <uid>517961878</uid>
        <eid>2454827764</eid>
        <rsvp_status>attending</rsvp_status>
      </event_member>
      <event_member>
        <uid>744961110</uid>
        <eid>2454827764</eid>
        <rsvp_status>declined</rsvp_status>
      </event_member>
    </fql_query_response>
    XML
  end
  def example_check_friendship_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <friends_areFriends_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <friend_info>
        <uid1>222332</uid1>
        <uid2>222333</uid2>
        <are_friends>1</are_friends>
      </friend_info>
      <friend_info>
        <uid1>1240077</uid1>
        <uid2>1240079</uid2>
        <are_friends>0</are_friends>
      </friend_info>
    </friends_areFriends_response>
    XML
  end

  def example_check_friendship_with_unknown_result
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <friends_areFriends_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <friend_info>
        <uid1>1240077</uid1>
        <uid2>1240079</uid2>
        <are_friends xsi:nil="true"/>
      </friend_info>
    </friends_areFriends_response>
    XML
  end

  def example_fql_for_multiple_users_and_pics
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <fql_query_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" list="true">
      <user>
        <name>Ari Steinberg</name>
        <pic>http://profile.ak.facebook.com/profile2/1805/47/s211031_26434.jpg</pic>
      </user>
      <user>
        <name>Ruchi Sanghvi</name>
        <pic>http://profile.ak.facebook.com/v52/870/125/s4801660_2498.jpg</pic>
      </user>
    </fql_query_response>
    XML
  end

  def example_fql_for_multiple_photos_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <fql_query_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" list="true">
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sf2p/v108/212/118/22700225/s22700225_30345986_2713.jpg</src>
        <caption>Nottttt. get ready for some museumz</caption>
        <caption>Nottttt. get ready for some museumz</caption>
      </photo>
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/s22701786_30324934_7816.jpg</src>
        <caption>Rooftop barbecues make me act funny</caption>
        <caption>Rooftop barbecues make me act funny</caption>
      </photo>
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sctm/v96/154/56/22700188/s22700188_30321538_17.jpg</src>
        <caption>An epic shot of Patrick getting ready for a run to second.</caption>
        <caption>An epic shot of Patrick getting ready for a run to second.</caption>
      </photo>
    </fql_query_response>
    XML
  end

  def example_fql_for_multiple_photos_with_anon_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <fql_query_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" list="true">
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sf2p/v108/212/118/22700225/s22700225_30345986_2713.jpg</src>
        <caption>Nottttt. get ready for some museumz</caption>
        <caption>Nottttt. get ready for some museumz</caption>
        <anon>first</anon>
        <anon>second</anon>
      </photo>
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/s22701786_30324934_7816.jpg</src>
        <caption>Rooftop barbecues make me act funny</caption>
        <caption>Rooftop barbecues make me act funny</caption>
        <anon>first</anon>
        <anon>second</anon>
      </photo>
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sctm/v96/154/56/22700188/s22700188_30321538_17.jpg</src>
        <caption>An epic shot of Patrick getting ready for a run to second.</caption>
        <caption>An epic shot of Patrick getting ready for a run to second.</caption>
        <anon>first</anon>
        <anon>second</anon>
      </photo>
    </fql_query_response>
    XML
  end

  def no_results_fql
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <fql_query_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" list="true">
    </fql_query_response>
    XML

  end

  def example_group_members_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <groups_getMembers_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <members list="true">
        <uid>1240077</uid>
        <uid>1240078</uid>
        <uid>222332</uid>
        <uid>222333</uid>
      </members>
      <admins list="true">
        <uid>1240077</uid>
        <uid>222333</uid>
      </admins>
      <officers list="true">
        <uid>1240078</uid>
      </officers>
      <not_replied list="true"/>
    </groups_getMembers_response>
    XML
  end

  def example_batch_run_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <batch_run_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <batch_run_response_elt>
      #{CGI.escapeHTML(example_fql_query_event_members_xml)}
      </batch_run_response_elt>
    </batch_run_response>
    XML
  end

  def example_event_members_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <events_getMembers_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <attending list="true">
        <uid>222332</uid>
        <uid>222333</uid>
      </attending>
      <unsure list="true">
        <uid>1240077</uid>
      </unsure>
      <declined list="true"/>
      <not_replied list="true">
        <uid>222335</uid>
        <uid>222336</uid>
      </not_replied>
    </events_getMembers_response>
    XML
  end

  def example_register_template_bundle_return_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed_registerTemplateBundle_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/">
         17876842716
    </feed_registerTemplateBundle_response>
    XML
  end

  def example_pages_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <pages_getInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <page>
        <page_id>4846711747</page_id>
        <name>Kronos Quartet</name>
        <website>http://www.kronosquartet.org</website>
        <company_overview/>
        <genre>
          <dance>0</dance>
          <party>1</party>
        </genre>
      </page>
    </pages_getInfo_response>
    XML
  end

  def publish_user_action_return_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed_publishUserAction_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <feed_publishUserAction_response_elt>1</feed_publishUserAction_response_elt>
    </feed_publishUserAction_response>
    XML
  end

  def standard_info_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <?xml version="1.0" encoding="UTF-8"?>

    <users_getStandardInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <standard_user_info>
        <uid>12451752</uid>
        <name>Mike Mangino</name>
      </standard_user_info>
    </users_getStandardInfo_response>
    XML
  end
end


class CanvasSessionTest < Test::Unit::TestCase
  def setup
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'
  end

  def test_login_url_will_display_callback_url_in_canvas
    session = Facebooker::CanvasSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    assert_equal("http://www.facebook.com/login.php?api_key=1234567&v=1.0&canvas=true", session.login_url)
  end
end
