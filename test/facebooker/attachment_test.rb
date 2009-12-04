require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class Facebooker::AttachmentTest < Test::Unit::TestCase
  
  def setup
    super
    @attachment = Facebooker::Attachment.new
  end
  
  def test_can_create_attachment
    attachment = Facebooker::Attachment.new
  end
  
  def test_can_set_name
    @attachment.name = "my name"
    assert_equal({:name=>"my name"},@attachment.to_hash)
  end
  
  def test_can_set_href
    @attachment.href="my href"
    assert_equal({:href=>"my href"},@attachment.to_hash)
  end
  
  def test_can_set_caption
    @attachment.caption="my caption"
    assert_equal({:caption=>"my caption"},@attachment.to_hash)
  end
  
  def test_can_set_description
    @attachment.description="my description"
    assert_equal({:description=>"my description"},@attachment.to_hash)
  end
  
  def test_can_set_comments_xid
    @attachment.comments_xid="my xid"
    assert_equal({:comments_xid=>"my xid"},@attachment.to_hash)    
  end
  
  def test_can_add_media
    @attachment.add_media(:type=>"image",:src=>"http://www.google.com",:href=>"http://www.bing.com")
    assert_equal({:media=>[{:type=>"image",:src=>"http://www.google.com",:href=>"http://www.bing.com"}]},@attachment.to_hash)
  end
  
  def test_can_add_image
    @attachment.add_image("image_source","image_url")
    assert_equal({:media=>[{:type=>"image",:src=>"image_source",:href=>"image_url"}]},@attachment.to_hash)
  end
  
  def test_can_add_mp3_with_only_required_params
    @attachment.add_mp3("required_source")
    assert_equal({:media=>[{:type=>"mp3",:src=>"required_source"}]},@attachment.to_hash)
  end
  
  def test_only_includes_mp3_optional_params_that_are_provided
    @attachment.add_mp3("required_source","seven nation army","white stripes")
    assert_equal({:media=>[{:type=>"mp3",:src=>"required_source",:title=>"seven nation army",:artist=>"white stripes"}]},@attachment.to_hash)
  end
  
  def test_can_add_flash_with_only_required_params
    @attachment.add_flash("swf_source","img_source")
    assert_equal({:media=>[{:type=>"flash",:swfsrc=>"swf_source",:imgsrc=>"img_source"}]},@attachment.to_hash)
  end
  def test_can_add_flash_with_optional_params
    @attachment.add_flash("swf_source","img_source",100,80,160)
    assert_equal({:media=>[{:type=>"flash",
                            :swfsrc=>"swf_source",
                            :imgsrc=>"img_source",
                            :width=>100,
                            :height=>80,
                            :expanded_width=>160}]},@attachment.to_hash)
  end
end