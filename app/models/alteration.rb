class Alteration < ActiveRecord::Base
  belongs_to :target_order, class_name: 'Spree::Order'
  belongs_to :working_order, class_name: 'Spree::Order'

  validates :target_order, presence: true
  validates :working_order, presence: true

  def initialize_working_order
    self.working_order = Spree::Order.create(working_attrs)
    target_order.line_items.each do |li|
      working_order.line_items.create(
        variant_id: li.variant_id,
        quantity: li.quantity
      )
    end
  end

  private

  def working_attrs
    target_order.attributes.slice(
      "distributor_id",
      "order_cycle_id"
    )
  end
end
