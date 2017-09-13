require 'spec_helper'
require 'open_food_network/incomplete_orders'

module OpenFoodNetwork
  describe IncompleteOrders do
    let!(:user) { create(:user) }

    describe "#incomplete_orders" do
      let!(:other_user) { create(:user) }
      let!(:order1) { create(:order, user: user, created_at: 15.days.ago) }
      let!(:order2) { create(:order, user: user, created_at: 13.days.ago) }
      let!(:order3) { create(:order, user: user, state: 'address') }
      let!(:order4) { create(:order, user: other_user) }
      let!(:order5) { create(:order, user_id: nil) }
      let!(:order6) { create(:order, user: user, completed_at: Time.zone.now) }
      let(:incomplete_orders) { OpenFoodNetwork::IncompleteOrders.new(user).send(:incomplete_orders) }

      it "ignores orders created more than a fortnight ago" do
        expect(incomplete_orders).to_not include order1
        expect(incomplete_orders).to include order2
      end

      it "ignores orders with a state that is not 'cart'" do
        expect(incomplete_orders).to_not include order3
        expect(incomplete_orders).to include order2
      end

      it "ignores orders associated with other users and those without a user" do
        expect(incomplete_orders).to_not include order4, order5
        expect(incomplete_orders).to include order2
      end

      it "ignores completed orders" do
        expect(incomplete_orders).to_not include order6
        expect(incomplete_orders).to include order2
      end
    end

    describe "#last" do
      let(:last_incomplete_order) { OpenFoodNetwork::IncompleteOrders.new(user).last }

      context "where an incomplete order exists" do
        let!(:order) { create(:order, user: user, created_at: 10.days.ago) }

        context "where an account_invoice exists" do
          let!(:invoice_order) { create(:order, user: user, created_at: 5.days.ago) }
          let!(:account_invoice) { create(:account_invoice, user: user, order: invoice_order) }

          it "ignores orders accociated with account invoices" do
            # Note that invoice_order is created more recently than order
            expect(last_incomplete_order).to eq order
          end
        end

        context "where no account_invoices exist" do
          let!(:recent_order) { create(:order, user: user, created_at: 5.days.ago) }

          # Note that recent_order is created more recently than order
          it "returns the most recent incomplete order" do
            expect(last_incomplete_order).to eq recent_order
          end
        end
      end

      context "where no incomplete orders exist" do
        it "returns nil" do
          expect(last_incomplete_order).to be_nil
        end
      end
    end
  end
end
