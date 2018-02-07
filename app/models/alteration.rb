class Alteration < ActiveRecord::Base
  belongs_to :target_order, class_name: 'Spree::Order'
  belongs_to :working_order, class_name: 'Spree::Order'

  before_create :initialize_working_order, unless: :working_order

  validates :target_order, presence: true
  validate :target_order_must_be_complete

  private

  def initialize_working_order
    self.working_order = Spree::Order.create(working_attrs)
    target_order.line_items.each do |li|
      working_order.line_items.create(
        variant_id: li.variant_id,
        quantity: li.quantity
      )
    end
  end

  def working_attrs
    target_order.attributes.slice(
      "distributor_id",
      "order_cycle_id"
    )
  end

  def target_order_must_be_complete
    return unless target_order.present?
    return if target_order.complete?
    errors.add(:target_order, :incomplete)
  end
end
