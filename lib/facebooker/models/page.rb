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
    attr_accessor :page_id, :name, :pic_small, :pic_big, :pic_square, :pic_large, :page_url, :type, :website, :location, :hours, :band_members, :bio, :hometown, :record_label, :influences, :has_added_app, :founded, :company_overview, :mission, :products, :release_date, :starring, :written_by, :directed_by, :produced_by, :studio, :awards, :plot_outline, :network, :season, :schedule
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
