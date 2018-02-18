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
    let(:shop) { create(:distributor_enterprise) }
    let(:working_order) { create(:order) }
    let(:target_order) { create(:completed_order_with_totals, distributor: shop) }
    let!(:variant) { target_order.line_items.first.variant }
    let!(:alteration) { create(:alteration, target_order: target_order, working_order: working_order) }

    before do
      variant.update_attribute(:on_hand, 5)
      variant.update_attribute(:price, 2.34)
    end

    context "for variants on the working order that already exist on the target order" do
      let!(:working_line_item) { working_order.line_items.create(variant_id: variant.id, quantity: 3) }

      context "when no variant override exists for the item and shop in question" do
        context "when sufficient stock exists to add the item to the target order" do
          it "creates a new item on the target order with a matching quantity" do
            expect{ alteration.confirm! }.to_not change(Spree::LineItem, :count)
            line_item = target_order.line_items.find_by_variant_id(variant.id)
            expect(line_item.quantity).to eq 3
            expect(line_item.price).to eq 10 # NOTE: original price used
          end
        end

        context "when variant stock is insufficient to add the item to the target order" do
          before { variant.update_attribute(:count_on_hand, 1) } # 3 - 1 = 2 required

          it "returns false and does not add an item to the target order" do
            expect do
              expect(alteration.confirm!).to be false
            end.to_not change(Spree::LineItem, :count)
          end
        end
      end

      context "when a variant override exists for the item and shop in question" do
        let!(:override) { create(:variant_override, hub: shop, variant: variant, count_on_hand: 5, price: 3.45) }

        context "when sufficient stock exists to add the item to the target order" do
          it "creates a new item using the override price" do
            expect{ alteration.confirm! }.to_not change(Spree::LineItem, :count)
            line_item = target_order.line_items.find_by_variant_id(variant.id)
            expect(line_item.quantity).to eq 3
            expect(line_item.price).to eq 10 # NOTE: original price used
          end
        end

        context "when override stock is insufficient to add the item to the target order" do
          before { override.update_attribute(:count_on_hand, 1) } # 3 - 1 = 2 required

          it "returns false and does not add an item to the target order" do
            expect do
              expect(alteration.confirm!).to be false
            end.to_not change(Spree::LineItem, :count)
          end
        end
      end
    end

    context "for variants on the working order that do not exist on the target order" do
      let!(:new_variant) { create(:variant, on_hand: on_hand, price: 1.23) }
      let!(:working_line_item1) { working_order.line_items.create(variant_id: variant.id) }
      let!(:working_line_item2) { working_order.line_items.create(variant_id: new_variant.id, quantity: 4) }

      context "when no variant override exists for the item and shop in question" do
        let(:on_hand) { 4 + 4 }

        context "when sufficient stock exists to add the item to the target order" do
          it "creates a new item on the target order with a matching quantity" do
            expect{ alteration.confirm! }.to change(Spree::LineItem, :count).by(1)
            line_item = target_order.line_items.find_by_variant_id(new_variant.id)
            expect(line_item.quantity).to eq 4
            expect(line_item.price).to eq 1.23
          end
        end

        context "when variant stock is insufficient to add the item to the target order" do
          let(:on_hand) { 4 + 3 }

          it "returns false and does not add an item to the target order" do
            expect do
              expect(alteration.confirm!).to be false
            end.to_not change(Spree::LineItem, :count)
          end
        end
      end

      context "when a variant override exists for the variant and shop in question" do
        let!(:override) { create(:variant_override, hub: shop, variant: new_variant, count_on_hand: 9, price: 4.56) }

        context "when sufficient stock exists to add the item to the target order" do
          it "creates a new item using the override price" do
            expect{ alteration.confirm! }.to change(Spree::LineItem, :count).by(1)
            line_item = target_order.line_items.find_by_variant_id(new_variant.id)
            expect(line_item.quantity).to eq 4
            expect(line_item.price).to eq 4.56
          end
        end

        context "when override stock is insufficient to add the item to the target order" do
          before { override.update_attribute(:count_on_hand, 3) }

          it "returns false and does not add an item to the target order" do
            expect do
              expect(alteration.confirm!).to be false
            end.to_not change(Spree::LineItem, :count)
          end
        end
      end
    end

    context "for variants on the target order that do not exist on the working order" do
      it "removes such variants from the target order as well" do
        expect{ alteration.confirm! }.to change(Spree::LineItem, :count).by(-1)
        line_item = target_order.line_items.find_by_variant_id(variant.id)
        expect(line_item).to be nil
      end
    end
  end
end
