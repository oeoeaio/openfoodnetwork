class Alteration < ActiveRecord::Base
  belongs_to :target_order, class_name: 'Spree::Order'
  belongs_to :working_order, class_name: 'Spree::Order', dependent: :destroy

  before_create :initialize_working_order, unless: :working_order

  validates :target_order, presence: true
  validate :target_order_must_be_complete

  def confirm!
    remove_missing_items
    create_or_update_items
  end

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

  def remove_missing_items
    missing_variants.find_each do |variant|
      target_order.remove_variant(variant)
    end
  end

  def missing_variants
    target = target_order.line_items.pluck(:variant_id)
    working = working_order.line_items.pluck(:variant_id)
    Spree::Variant.where(id: target - working)
  end

  def create_or_update_items
    working_order.line_items.all? do |line_item|
      create_or_update_item_from(line_item)
    end
  end

  def create_or_update_item_from(line_item)
    variant_id = line_item.variant_id
    target_item = find_or_initialize_item_for(variant_id)
    target_item.update_attributes(line_item.attributes.slice("price", "quantity"))
  end

  def find_or_initialize_item_for(variant_id)
    existing = target_order.line_items.find_by_variant_id(variant_id)
    existing || target_order.line_items.new(variant_id: variant_id)
  end
end
