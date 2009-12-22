class Facebooker::Attachment
  
  def initialize
    @storage = {}
  end
  
  def self.hash_populating_accessor(*names)
    names.each do |name|
      define_method(name) do
        @storage[name]
      end
      define_method("#{name}=") do |val|
        @storage[name]=val
      end
    end
  end
  
  hash_populating_accessor :name,:href, :comments_xid, :description, :caption
  
  def add_media(hash)
    @storage[:media]||=[]
    @storage[:media] << hash
  end
  
  def add_image(source,href)
    add_media({:type=>"image",:src=>source,:href=>href})
  end
  
  def add_mp3(source,title=nil,artist=nil,album=nil)
    params = {:src=>source,:type=>"mp3"}
    params[:title] =  title unless title.nil?
    params[:artist] =  artist unless artist.nil?
    params[:album] =  album unless album.nil?
    add_media(params)
  end
  
  def add_flash(swfsource, imgsource, width=nil, height=nil, expanded_width=nil, expanded_height=nil)
    params={:type=>"flash",:swfsrc=>swfsource,:imgsrc=>imgsource}
    params[:width] = width unless width.nil?
    params[:height] = height unless height.nil?
    params[:expanded_width] = expanded_width unless expanded_width.nil?
    params[:expanded_height] = expanded_height unless expanded_height.nil?
    add_media(params)
  end
  
  def to_hash
    @storage
  end
  
  
end