class AddFiltersToDrills < ActiveRecord::Migration[8.0]
  def change
    add_column :drills, :filters, :json, default: {}
  end
end
