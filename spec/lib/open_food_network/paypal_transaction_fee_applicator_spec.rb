require 'spec_helper'
require 'open_food_network/paypal_transaction_fee_applicator'

module OpenFoodNetwork
  describe PayPalTransactionFeeApplicator do
    describe "applying fees" do
      let(:line_item) { create(:line_item, quantity: 3, price: 5.00) }
      let(:order) { line_item.order }
      let(:payment_method) { Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress", distributor_ids: [create(:distributor_enterprise).id] ) }
      let(:applicator) { OpenFoodNetwork::PayPalTransactionFeeApplicator.new(order, payment_method) }

      before do
        order.reload.update_totals
      end

      context "with a flat percent calculator" do
        let(:calculator) { Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

        before do
          payment_method.calculator = calculator
          payment_method.save!
        end

        it "adds a transaction fee adjustment to the order" do
          expect(order.total).to eq 15.0
          expect{ applicator.apply_fees }.to change(order.adjustments, :count).by(1)
          expect(order.adjustments.eligible.count).to eq 1
          order.update_totals
          expect(order.total).to eq 16.5
        end
      end

      context "with a flat rate calculator" do
        let(:calculator) { Spree::Calculator::FlatRate.new(preferred_amount: 0.85) }

        before do
          payment_method.calculator = calculator
          payment_method.save!
        end

        it "adds a transaction fee adjustment to the order" do
          expect(order.total).to eq 15.0
          expect{ applicator.apply_fees }.to change(order.adjustments, :count).by(1)
          expect(order.adjustments.eligible.count).to eq 1
          order.update_totals
          expect(order.total).to eq 15.85
        end
      end
    end
  end
end
