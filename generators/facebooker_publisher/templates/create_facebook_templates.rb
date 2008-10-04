class CreateFacebookTemplates < ActiveRecord::Migration
  def self.up
    create_table :facebook_templates, :force => true do |t|
      t.string :bundle_id,:template_name
      t.timestamps
    end
  end

  def self.down
    drop_table :facebook_templates
  end
end
