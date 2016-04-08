require 'spec_helper'

describe TagRule::DiscountOrder, type: :model do
  let!(:tag_rule) { create(:tag_rule) }

  describe "determining relevance based on additional requirements" do
    let(:subject) { double(:subject) }

    before do
      tag_rule.set_context(subject,{})
      allow(tag_rule).to receive(:customer_tags_match?) { true }
      allow(subject).to receive(:class) { Spree::Order }
    end

    context "when already_applied? returns false" do
      before { expect(tag_rule).to receive(:already_applied?) { false } }

      it "returns true" do
        expect(tag_rule.send(:relevant?)).to be true
      end
    end

    context "when already_applied? returns true" do
      before { expect(tag_rule).to receive(:already_applied?) { true } }

      it "returns false immediately" do
        expect(tag_rule.send(:relevant?)).to be false
      end
    end
  end

  describe "determining whether a the rule has already been applied to an order" do
    let!(:order) { create(:order) }
    let!(:adjustment) { order.adjustments.create({:amount => 12.34, :source => order, :originator => tag_rule, :label => 'discount' }, :without_protection => true) }

    before do
      tag_rule.set_context(order, nil)
    end

    context "where adjustments originating from the rule already exist" do
      it { expect(tag_rule.send(:already_applied?)).to be true}
    end

    context "where existing adjustments originate from other rules" do
      before { adjustment.update_attribute(:originator_id,create(:tag_rule).id) }
      it { expect(tag_rule.send(:already_applied?)).to be false}
    end
  end

  describe "applying the rule" do
    # Assume that all validation is done by the TagRule base class

    context "in a simple scenario" do
      let!(:line_item) { create(:line_item, price: 100.00) }
      let!(:order) { line_item.order }

      before do
        order.update_distribution_charge!
        tag_rule.calculator.update_attribute(:preferred_flat_percent, -10.00)
        tag_rule.set_context(order, nil)
      end

      let(:adjustment) { order.reload.adjustments.where(originator_id: tag_rule, originator_type: "TagRule").first }

      it "creates a new adjustment on the order" do
        tag_rule.send(:apply!)
        expect(adjustment).to be_a Spree::Adjustment
        expect(adjustment.amount).to eq -10.00
        expect(adjustment.label).to eq "Discount"
        expect(order.adjustment_total).to eq -10.00
        expect(order.total).to eq 90.00
      end
    end

    context "when shipping charges apply" do
      let!(:line_item) { create(:line_item, price: 100.00) }
      let!(:order) { line_item.order }
      let!(:shipping_method) { create(:shipping_method, calculator: Spree::Calculator::FlatRate.new( preferred_amount: 25.00 ) ) }

      before do
        order.update_distribution_charge!
        tag_rule.calculator.update_attribute(:preferred_flat_percent, -10.00)
        tag_rule.set_context(order, nil)
        shipping_method.create_adjustment("Shipping", order, order, true)
      end

      let(:adjustment) { order.reload.adjustments.where(originator_id: tag_rule, originator_type: "TagRule").first }

      it "the adjustment is made on line item total, ie. ignores the shipping amount" do
        tag_rule.send(:apply!)
        expect(adjustment).to be_a Spree::Adjustment
        expect(adjustment.amount).to eq -10.00
        expect(adjustment.label).to eq "Discount"
        expect(order.adjustment_total).to eq 15.00
        expect(order.total).to eq 115.00
      end
    end

    context "complex examples" do
      let!(:zone)            { create(:zone_with_member) }
      let(:tax_rate)         { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, zone: zone, amount: 0.1) }
      let(:tax_category)     { create(:tax_category, tax_rates: [tax_rate]) }

      let(:coordinator)      { create(:distributor_enterprise, charges_sales_tax: true) }
      let(:variant)          { create(:variant, product: create(:product, tax_category: nil)) }
      let(:order_cycle)      { create(:simple_order_cycle, suppliers: [coordinator], coordinator: coordinator, distributors: [coordinator], variants: [variant]) }
      let!(:order)           { create(:order, order_cycle: order_cycle, distributor: coordinator) }
      let!(:line_item)       { create(:line_item, order: order, variant: variant, price: 100.00) }

      before do
        tag_rule.calculator.update_attribute(:preferred_flat_percent, -10.00)
        tag_rule.set_context(order, nil)
      end

      context "when enterprise fees with tax apply to the order" do
        let(:enterprise_fee)   { create(:enterprise_fee, enterprise: coordinator, tax_category: tax_category, calculator: Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)) }
        let!(:exchange_fee)     { ExchangeFee.create!(exchange: order_cycle.exchanges.incoming.first, enterprise_fee: enterprise_fee) }

        before do
          enterprise_fee.update_attribute(:tax_category, tax_category)
          order.update_distribution_charge!
        end

        let(:adjustment) { order.reload.adjustments.where(originator_id: tag_rule, originator_type: "TagRule").first }

        it "adjustment is made on line item total, and enterprise fee amount and included_tax are adjusted" do
          tag_rule.send(:apply!)
          expect(adjustment).to be_a Spree::Adjustment
          expect(adjustment.amount).to eq -11.00
          expect(adjustment.label).to eq "Discount"
          fee_adjustment = order.adjustments.enterprise_fee.first
          expect(fee_adjustment).to be_a Spree::Adjustment
          expect(fee_adjustment.amount).to eq 10.00
          expect(order.adjustment_total).to eq -1.00
          expect(order.total_tax).to eq 0.82
          expect(order.total).to eq 99.00
        end
      end

      context "when tax applies to line items (included in price)" do
        before do
          variant.product.update_attribute(:tax_category, tax_category)
          order.reload.create_tax_charge!
          order.update_distribution_charge!
        end

        let(:adjustment) { order.reload.adjustments.where(originator_id: tag_rule, originator_type: "TagRule").first }

        it "adjustment is made on line item total, and enterprise fee amount and included_tax are adjusted" do
          tag_rule.send(:apply!)
          expect(adjustment).to be_a Spree::Adjustment
          expect(adjustment.amount).to eq -10.00
          expect(adjustment.label).to eq "Discount"
          tax_adjustment = line_item.adjustments.where(originator_type: "Spree::TaxRate").first
          expect(tax_adjustment).to be_a Spree::Adjustment
          expect(tax_adjustment.amount).to eq 8.18
          expect(tax_adjustment.included_tax).to eq 8.18
          expect(order.adjustment_total).to eq -10.00
          expect(order.total_tax).to eq 8.18 # Total is now $90 because it was discounted by 10%
          expect(order.total).to eq 90.00
        end
      end

      context "when tax applies to the order (not included in price)" do
        before do
          tax_rate.update_attribute(:included_in_price, false)
          variant.product.update_attribute(:tax_category, tax_category)
          order.reload.create_tax_charge!
          order.update_distribution_charge!
        end

        let(:adjustment) { order.reload.adjustments.where(originator_id: tag_rule, originator_type: "TagRule").first }

        it "adjustment is made on order subtotal, amount and included tax on order are adjusted" do
          tag_rule.send(:apply!)
          expect(adjustment).to be_a Spree::Adjustment
          expect(adjustment.amount).to eq -10.00
          expect(adjustment.label).to eq "Discount"
          tax_adjustment = order.adjustments.tax.first
          expect(tax_adjustment).to be_a Spree::Adjustment
          expect(tax_adjustment.amount).to eq 9.00
          expect(tax_adjustment.included_tax).to eq 9.00
          expect(order.adjustment_total).to eq 0.00
          expect(order.total_tax).to eq 9.00 # Total is now $90 because it was discounted by 10%
          expect(order.total).to eq 100.00
        end
      end
    end
  end
end
