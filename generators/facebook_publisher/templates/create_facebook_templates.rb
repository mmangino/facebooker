class CreateFacebookTemplates < ActiveRecord::Migration
  def self.up
    create_table :facebook_templates, :force => true do |t|      
      t.string :name, :null => false
      t.string :content_hash, :null => false
      t.string :template_bundle_id, :null => true
    end
    add_index :facebook_templates, :name, :unique => true
  end

  def self.down
    remove_index :facebook_templates, :name
    drop_table :facebook_templates
  end
end
