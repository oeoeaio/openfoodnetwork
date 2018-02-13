require 'spec_helper'

describe Alteration do
  describe "associations" do
    it { expect(subject).to belong_to :target_order }
    it { expect(subject).to belong_to :working_order }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:target_order) }

    describe "validating that target order is complete" do
      let(:alteration) { Alteration.new(target_order: order, working_order: create(:order)) }

      context "when the target_order is incomplete" do
        let(:order) { create(:order) }
        it { expect(alteration).to_not be_valid }
      end

      context "when the target order is complete" do
        let(:order) { create(:completed_order_with_totals) }
        it { expect(alteration).to be_valid }
      end
    end
  end

  describe "before_create callback" do
    let(:enterprise) { create(:enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, coordinator: enterprise) }
    let(:target_order) { create(:completed_order_with_totals, distributor: enterprise, order_cycle: order_cycle) }
    let!(:alteration) { Alteration.new(target_order: target_order) }

    it "initializes a new working order and copies appropriate attributes and line items across" do
      expect(alteration.working_order).to be nil
      alteration.save!
      working_order = alteration.working_order
      expect(working_order).to be_a Spree::Order
      expect(working_order.line_items.count).to eq target_order.line_items.count
      expect(working_order.order_cycle).to eq order_cycle
      expect(working_order.distributor).to eq enterprise
      expect(working_order.state).to eq "cart"
    end
  end

  describe "#confirm!" do
    let(:working_order) { create(:order) }
    let(:target_order) { create(:completed_order_with_totals) }
    let!(:alteration) { create(:alteration, target_order: target_order, working_order: working_order) }

    context "for variants on the working order that already exist on the target order" do
      let(:variant_id) { target_order.line_items.first.variant_id }
      let!(:working_line_item) { working_order.line_items.create(variant_id: variant_id, price: 1.23, quantity: 5) }

      it "updates the price and quantity fields" do
        expect{ alteration.confirm! }.to_not change(Spree::LineItem, :count)
        line_item = target_order.line_items.find_by_variant_id(variant_id)
        expect(line_item.quantity).to eq 5
        expect(line_item.price).to eq 1.23
      end
    end

    context "for variants on the working order that do not exist on the target order" do
      let(:variant1) { target_order.line_items.first.variant }
      let(:variant2) { create(:variant, on_hand: 12) }
      let!(:working_line_item1) { working_order.line_items.create(variant_id: variant1.id)}
      let!(:working_line_item2) { working_order.line_items.create(variant_id: variant2.id, price: 4.56, quantity: 7) }

      it "updates the price and quantity fields" do
        expect{ alteration.confirm! }.to change(Spree::LineItem, :count).by(1)
        line_item = target_order.line_items.find_by_variant_id(variant2.id)
        expect(line_item.quantity).to eq 7
        expect(line_item.price).to eq 4.56
      end
    end


    context "for variants on the target order that do not exist on the working order" do
      let!(:variant) { target_order.line_items.first.variant }

      it "removes such variants from the target order as well" do
        expect{ alteration.confirm! }.to change(Spree::LineItem, :count).by(-1)
        line_item = target_order.line_items.find_by_variant_id(variant.id)
        expect(line_item).to be nil
      end
    end
  end
end
