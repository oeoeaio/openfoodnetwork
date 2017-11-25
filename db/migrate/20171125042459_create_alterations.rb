class CreateAlterations < ActiveRecord::Migration
  def change
    create_table :alterations do |t|
      t.references :target_order, null: false
      t.references :working_order, null: false
      t.timestamps
    end

    add_index :alterations, :target_order_id, unique: true
    add_index :alterations, :working_order_id, unique: true

    add_foreign_key :alterations, :spree_orders, column: :target_order_id
    add_foreign_key :alterations, :spree_orders, column: :working_order_id
  end
end
