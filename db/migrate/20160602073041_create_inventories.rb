class CreateInventories < ActiveRecord::Migration
  def change
    create_table :inventories do |t|
      t.references :enterprise, null: false, index: true
      t.string :name, null: false

      t.timestamps
    end

    add_foreign_key :inventories, :enterprises, column: "enterprise_id"
    add_index "inventories", [:enterprise_id, :name], unique: true
  end
end
