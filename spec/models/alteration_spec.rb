require 'spec_helper'

describe Alteration do
  describe "associations" do
    it { expect(subject).to belong_to :target_order }
    it { expect(subject).to belong_to :working_order }
  end

  describe "#initialize_working_order" do
    let(:enterprise) { create(:enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, coordinator: enterprise) }
    let(:target_order) { create(:completed_order_with_totals, distributor: enterprise, order_cycle: order_cycle) }
    let!(:alteration) { Alteration.new(target_order: target_order) }
    let(:working_order) { alteration.working_order }

    before do
      alteration.initialize_working_order
    end

    it "initializes a new working order and copies appropriate attributes and line items across" do
      expect(working_order).to be_a Spree::Order
      expect(working_order.line_items.count).to eq target_order.line_items.count
      expect(working_order.order_cycle).to eq order_cycle
      expect(working_order.distributor).to eq enterprise
      expect(working_order.state).to eq "cart"
    end
  end
end
