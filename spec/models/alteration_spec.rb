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
end
