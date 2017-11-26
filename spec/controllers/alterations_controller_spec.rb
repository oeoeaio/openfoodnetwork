require 'spec_helper'

describe AlterationsController, type: :controller do

  describe "#create" do
    let(:enterprise) { create(:enterprise) }
    let(:user) { create(:user) }
    let(:order) { create(:order, distributor: enterprise) }
    let(:params) { { target_order_id: order.id } }

    context "when no user logged in" do
      it "redirects to the login path" do
        post :create, params
        expect(response).to redirect_to spree.login_path
      end
    end

    context "when a user is logged in" do
      before{ allow(controller).to receive(:spree_current_user) { user } }

      context "but they do not own the target order" do
        it "redirects to unauthorized" do
          post :create, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "and they own the target order" do
        before { order.user = user; order.save! }

        context "when no errors are encountered while creating the alteration" do
          let(:order) { create(:completed_order_with_totals, distributor: enterprise) }

          it "creates an OrderAmendment, sets the current order and redirects to the relevant shop" do
            expect{ post :create, params }.to change(Alteration, :count).by(1)
            alteration = Alteration.last
            expect(controller.current_order).to eq alteration.working_order
            expect(response).to redirect_to enterprise_shop_path(enterprise)
          end
        end

        context "when an error is encountered while creating the alteration" do
          it "creates an Alteration, sets the current order and redirects to the relevant shop" do
            expect{ post :create, params }.to_not change(Alteration, :count)
            expect(controller.current_order).to be nil
            expect(flash[:error]).to include I18n.t('activerecord.errors.models.alteration.attributes.target_order.incomplete')
            expect(response).to redirect_to spree.order_path(order)
          end
        end
      end
    end
  end
end
