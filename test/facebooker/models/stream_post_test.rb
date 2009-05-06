require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class Facebooker::StreamPostTest < Test::Unit::TestCase

  def test_should_parse_body
    stream_posts = Facebooker::StreamGet.process(stream_post_xml_response)
    assert_equal Facebooker::StreamPost,stream_posts.first.class
  end
  def test_should_set_message
    stream_posts = Facebooker::StreamGet.process(stream_post_xml_response)
    assert_equal "is testing facebooker",stream_posts.first.message
  end
  
  def test_should_set_permalink
    stream_posts = Facebooker::StreamGet.process(stream_post_xml_response)
    assert_equal "http://www.facebook.com/profile.php?id=12451752&v=feed&story_fbid=22",stream_posts.first.permalink
  end

  def test_should_set_actor
    stream_posts = Facebooker::StreamGet.process(stream_post_xml_response)
    actor = stream_posts.first.actor
    assert_equal Facebooker::User,actor.class
    assert_equal "Mike Mangino",actor.name
    assert_equal 12451752,actor.uid
    assert_equal "http://profile.ak.facebook.com/v223/1819/34/n12451752_9533.jpg",actor.pic_square
    assert_equal "http://www.facebook.com/s.php?k=100000080&id=12451752",actor.profile_url
  end

  def test_should_set_viewer
    stream_posts = Facebooker::StreamGet.process(stream_post_xml_response)
    viewer = stream_posts.first.viewer
    assert_equal Facebooker::User,viewer.class
    assert_equal 563710619,viewer.uid
  end

  def test_should_set_updated_time
    stream_posts = Facebooker::StreamGet.process(stream_post_xml_response)
    assert_equal Time.at(1241558190),stream_posts.first.updated_time
  end

  def test_should_set_created_time
    stream_posts = Facebooker::StreamGet.process(stream_post_xml_response)
    assert_equal Time.at(1241558190),stream_posts.first.created_time
  end

  def stream_post_xml_response
   <<-EOX
      <stream_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
        <posts list="true">
          <stream_post>
            <post_id>762879027_78455789092</post_id>
            <viewer_id>563710619</viewer_id>
            <source_id>762879027</source_id>
            <type>46</type>
            <app_id>2231777543</app_id>
            <actor_id>12451752</actor_id>
            <message>is testing facebooker</message>
            <attachment/>
            <app_data/>
            <comments>
              <can_remove>0</can_remove>
              <can_post>1</can_post>
              <count>0</count>
              <posts list="true"/>
            </comments>
            <likes>
              <href>http://www.facebook.com/s.php?k=100000004&amp;id=11&amp;gr=22</href>
              <count>0</count>
              <sample list="true"/>
              <friends list="true"/>
              <user_likes>0</user_likes>
              <can_like>1</can_like>
            </likes>
            <privacy>
              <value>NOT_EVERYONE</value>
            </privacy>
            <updated_time>1241558190</updated_time>
            <created_time>1241558190</created_time>
            <filter_key/>
            <permalink>http://www.facebook.com/profile.php?id=12451752&amp;v=feed&amp;story_fbid=22</permalink>
          </stream_post>
        </posts>
        <profiles>
          <profile>
            <id>12451752</id>
            <url>http://www.facebook.com/s.php?k=100000080&amp;id=12451752</url>
            <name>Mike Mangino</name>
            <pic_square>http://profile.ak.facebook.com/v223/1819/34/n12451752_9533.jpg</pic_square>
          </profile>
          <profile>
            <id>563710619</id>
            <url>http://www.facebook.com/s.php?k=100000080&amp;id=563710619</url>
            <name>Alberto Tucci</name>
            <pic_square>http://profile.ak.facebook.com/v230/380/95/n563710619_5272.jpg</pic_square>
          </profile>
        </profiles>
        <albums list="true"/>
      </stream_get_response>
    EOX
  end
end
    