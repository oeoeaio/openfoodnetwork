class Alteration < ActiveRecord::Base
  belongs_to :target_order, class_name: 'Spree::Order'
  belongs_to :working_order, class_name: 'Spree::Order', dependent: :destroy

  before_create :initialize_working_order, unless: :working_order

  validates :target_order, presence: true
  validate :target_order_must_be_complete

  delegate :number, to: :target_order

  def confirm!
    transaction do
      remove_missing_items
      copy_items_between(working_order, target_order)
      return true
    end
    false
  end

  private

  def initialize_working_order
    return if working_order
    self.working_order = Spree::Order.create(working_attrs)
    copy_items_between(target_order, working_order)
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

  def copy_items_between(from_order, to_order)
    from_order.line_items.each do |li|
      scoper.scope(li.variant)
      new_item = to_order.add_variant(li.variant, li.quantity)
      raise ActiveRecord::Rollback unless new_item.valid?
    end
  end

  def scoper
    @scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(target_order.distributor)
  end
end
