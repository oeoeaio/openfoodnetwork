class TagRule::DiscountOrder < TagRule
  calculated_adjustments

  private

  # Warning: this should only EVER be called via TagRule#apply
  def apply!
    create_adjustment(I18n.t("discount"), subject, subject)
    discount_taxes!
  end

  def subject_class_matches?
    subject.class == Spree::Order
  end

  def additional_requirements_met?
    return false if already_applied?
    true
  end

  def already_applied?
    subject.adjustments.where(originator_id: id, originator_type: "TagRule").any?
  end

  def compute_amount(calculable)
    super(calculable) + compute_discount_on_fees(calculable)
  end

  def compute_discount_on_fees(calculable)
    fee_total = (discountable_adjustments(calculable).enterprise_fee).sum &:amount
    value = fee_total * BigDecimal(calculator.preferred_flat_percent.to_s) / 100.0
    (value * 100).round.to_f / 100
  end

  def discount_taxes!
    tax_adjustments = discountable_adjustments.where(originator_type: "Spree::TaxRate")
    discountable_adjustments.update_all("included_tax = included_tax + ROUND(included_tax * #{calculator.preferred_flat_percent/100},2)")
    tax_adjustments.update_all("amount = amount + ROUND(amount * #{calculator.preferred_flat_percent/100},2)")
  end

  def discountable_adjustments(calculable=subject)
    ids = (calculable.adjustments + calculable.price_adjustments - non_discountable_adjustments(calculable)).map(&:id)
    Spree::Adjustment.where(id: ids)
  end

  def non_discountable_adjustments(calculable)
    calculable.adjustments.where("(originator_id = (?) AND originator_type = (?)) OR originator_type = (?)", id, 'TagRule', 'Spree::ShippingMethod')
  end
end
