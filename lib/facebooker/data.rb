module Facebooker
  class Data
    def initialize(session)
      @session = session
    end

    ##
    # ** BETA ***
    # Sets a cookie on Facebook
    # +user+ The user for whom this cookie needs to be set.
    # +name+ Name of the cookie
    # +value+ Value of the cookie
    # Optional:
    # +expires+ Time when the cookie should expire. If not specified, the cookie never expires.
    # +path+ Path relative to the application's callback URL, with which the cookie should be associated. (default value is /?
    def set_cookie(user, name, value, expires=nil, path=nil)
      @session.post('facebook.data.setCookie',
        :uid => User.cast_to_facebook_id(user),
        :name => name,
        :value => value,
        :expires => expires,
        :path => path) {|response| response == '1'}
    end

    ##
    # ** BETA ***
    # Gets a cookie stored on Facebook
    # +user+	The user from whom to get the cookies.
    # Optional:
    # +name+ The name of the cookie. If not specified, all the cookies for the given user get returned.
    def get_cookies(user, name=nil)
      @cookies = @session.post(
        'facebook.data.getCookies', :uid => User.cast_to_facebook_id(user), :name => name) do |response|
          response.map do |hash|
            Cookie.from_hash(hash)
          end
      end
    end

    ##
    # ** BETA ***
    # Gets a preference stored on Facebook
    # +pref_id+	The id of the preference to get
    def get_preference(pref_id)
      @session.post('facebook.data.getUserPreference', :pref_id=>pref_id)
    end

    ##
    # ** BETA ***
    # Sets a preference on Facebook
    # +pref_id+	The id of the preference to set
    # +value+ The value to set for this preference
    def set_preference(pref_id, value)
      @session.post('facebook.data.setUserPreference', :pref_id=>pref_id, :value=>value)
    end
  end
end
