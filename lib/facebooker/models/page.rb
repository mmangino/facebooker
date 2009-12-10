require 'facebooker/model'
module Facebooker
  class Page
    
    def initialize(*args)
      if args.size == 1 and (args.first.is_a?(Integer) or args.first.is_a?(String))
        self.page_id=args.first
      else
        super
      end
    end

    class Genre
      include Model
      FIELDS = [ :dance, :party, :relax, :talk, :think, :workout, :sing, :intimate, :raunchy, :headphones ]
      attr_accessor(*FIELDS)

      def initialize(*args)
        super

        # convert '1'/'0' to true/false
        FIELDS.each do |field|
          self.send("#{field}=", self.send(field) == '1')
        end
      end
    end

    include Model
    attr_accessor :page_id,:name,:pic_small,:pic_big,:pic_square,:pic,:pic_large,:type,:website,:has_added_app,:founded,:company_overview,:mission,:products,:location,:parking,:public_transit,:hours,:attire,:payment_options,:culinary_team,:general_manager,:price_range,:restaurant_services,:restaurant_specialties,:release_date,:genre,:starring,:screenplay_by,:directed_by,:produced_by,:studio,:awards,:plot_outline,:network,:season,:schedule,:written_by,:band_members,:hometown,:current_location,:record_label,:booking_agent,:artists_we_like,:influences,:band_interests,:bio,:affiliation,:birthday,:personal_info,:personal_interests,:members,:built,:features,:mpg,:general_info,:fan_count
    attr_reader :genre

    def genre=(value)
      @genre = value.kind_of?(Hash) ? Genre.from_hash(value) : value
    end
    
    def user_is_admin?(user)
      Session.current.post('facebook.pages.isAdmin', :page_id=>self.page_id, :uid=>Facebooker::User.cast_to_facebook_id(user))
    end
    
    def user_is_fan?(user)
      Session.current.post('facebook.pages.isFan', :page_id=>self.page_id, :uid=>Facebooker::User.cast_to_facebook_id(user))
    end
  end
end
