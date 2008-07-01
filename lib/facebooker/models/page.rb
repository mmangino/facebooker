require 'facebooker/model'
module Facebooker
  class Page

    class Genre
      include Model
      FIELDS = [ :dance, :party, :relax, :talk, :think, :workout, :sing, :intimate, :raunchy, :headphones ]
      attr_accessor *FIELDS

      def initialize(*args)
        super

        # convert '1'/'0' to true/false
        FIELDS.each do |field|
          self.send("#{field}=", self.send(field) == '1')
        end
      end
    end

    include Model
    attr_accessor :page_id, :name, :pic_small, :pic_big, :pic_square, :pic_large, :type, :type, :website, :location, :hours, :band_members, :bio, :hometown, :genre, :record_label, :influences, :has_added_app, :founded, :company_overview, :mission, :products, :release_date, :starring, :written_by, :directed_by, :produced_by, :studio, :awards, :plot_outline, :network, :season, :schedule

    def genre=(value)
      @genre = value.kind_of?(Hash) ? Genre.from_hash(value) : value
    end
  end
end
