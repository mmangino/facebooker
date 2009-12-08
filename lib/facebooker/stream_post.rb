class Facebooker::StreamPost
  attr_accessor :user_message, :attachment, :action_links, :target, :actor
  
  def initialize
    self.action_links = []
  end
  
  alias_method :message, :user_message
  alias_method :message=, :user_message=
  
  def action_links(*args)
    if args.blank?
      @action_links
    else
      @action_links = args.first
    end
  end
  
end