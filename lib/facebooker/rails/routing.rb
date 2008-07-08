module Facebooker
  module Rails
    module Routing
      module RouteSetExtensions
        def self.included(base)
          base.alias_method_chain :extract_request_environment, :facebooker
        end

        def extract_request_environment_with_facebooker(request)
          env = extract_request_environment_without_facebooker(request)
          env.merge :canvas => (request.parameters[:fb_sig_in_canvas]=="1")
        end
      end 
      module MapperExtensions

        # Generates pseudo-resource routes. Since everything is a POST, routes can't be identified
        # using HTTP verbs. Therefore, the action is appended to the beginning of each named route,
        # except for index.
        #
        # Example: 
        #   map.facebook_resources :profiles
        #
        # Generates the following routes:
        #
        #     new_profile POST /profiles/new         {:controller=>"profiles", :action=>"new"}
        #        profiles POST /profiles/index       {:controller=>"profiles", :action=>"index"}
        #    show_profile POST /profiles/:id/show    {:controller=>"profiles", :action=>"show"}
        #  create_profile POST /profiles/create      {:controller=>"profiles", :action=>"create"}
        #    edit_profile POST /profiles/:id/edit    {:controller=>"profiles", :action=>"edit"}
        #  update_profile POST /profiles/:id/update  {:controller=>"profiles", :action=>"update"}
        # destroy_profile POST /profiles/:id/destroy {:controller=>"profiles", :action=>"destroy"}
        #
        def facebook_resources(name_sym)
          name = name_sym.to_s

          with_options :controller => name, :conditions => { :method => :post } do |map|
            map.named_route("new_#{name.singularize}",     "#{name}/new",         :action => 'new')
            map.named_route(name,                          "#{name}/index",       :action => 'index')
            map.named_route("show_#{name.singularize}",    "#{name}/:id/show",    :action => 'show',    :id => /\d+/)
            map.named_route("create_#{name.singularize}",  "#{name}/create",      :action => 'create')
            map.named_route("edit_#{name.singularize}",    "#{name}/:id/edit",    :action => 'edit',    :id => /\d+/)
            map.named_route("update_#{name.singularize}",  "#{name}/:id/update",  :action => 'update',  :id => /\d+/)
            map.named_route("destroy_#{name.singularize}", "#{name}/:id/destroy", :action => 'destroy', :id => /\d+/)            
          end
        end
      end
    end
  end      
end