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

        context "when an alteration already exists for the target order" do
          let(:order) { create(:completed_order_with_totals, distributor: enterprise) }
          let(:working_order) { create(:order, distributor: enterprise) }
          let!(:alteration) { Alteration.create(target_order: order, working_order: working_order) }

          it "sets the current order and redirects to the relevant shop, but does not create an Alteration" do
            expect{ post :create, params }.to_not change(Alteration, :count)
            expect(controller.current_order).to eq working_order
            expect(response).to redirect_to enterprise_shop_path(enterprise)
          end
        end

        context "when no alteration already exists for the target order" do
          context "when no errors are encountered while creating the alteration" do
            let(:order) { create(:completed_order_with_totals, distributor: enterprise) }

            it "creates an Alteration, sets the current order and redirects to the relevant shop" do
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

  describe "confirm" do
    let(:params) { { id: 1 } }
    let(:enterprise) { create(:enterprise) }
    let(:order) { create(:completed_order_with_totals, distributor: enterprise) }
    let(:alteration) { create(:alteration, target_order: order) }

    before do
      allow(Alteration).to receive(:find) { alteration }
    end

    context "when no user logged in" do
      it "redirects to the login path" do
        put :confirm, params
        expect(response).to redirect_to spree.login_path
      end
    end

    context "when a user is logged in" do
      let(:user) { create(:user) }

      before do
        allow(controller).to receive(:spree_current_user) { user }
      end

      context "but they do not own the target order" do
        it "redirects to unauthorized" do
          put :confirm, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "and they own the target order" do
        before do
          order.update_attribute(:user_id, user.id)
        end

        context "when the alteration is successfully confirmed" do
          before do
            allow(alteration).to receive(:confirm!) { true }
          end

          it "redirects to the order confirmation page" do
            put :confirm, params
            expect(response).to redirect_to spree.order_path(order)
          end
        end

        context "when the alteration is not successfully confirmed" do
          before do
            allow(alteration).to receive(:confirm!) { false }
            allow(alteration).to receive(:errors) { double(:errors, full_messages: ["some error"]) }
          end

          it "adds a flash message and redirects to the enterprise shop path" do
            put :confirm, params
            expect(response).to redirect_to enterprise_shop_path(enterprise)
          end
        end
      end
    end
  end

  describe "#destroy" do
    let(:params) { { id: 1 } }
    let(:enterprise) { create(:enterprise) }
    let(:order) { build(:completed_order_with_totals, distributor: enterprise) }
    let(:alteration) { create(:alteration, target_order: order) }

    before do
      allow(Alteration).to receive(:find) { alteration }
    end

    context "when no user logged in" do
      it "redirects to the login path" do
        delete :destroy, params
        expect(response).to redirect_to spree.login_path
      end
    end

    context "when a user is logged in" do
      let(:user) { create(:user) }

      before do
        allow(controller).to receive(:spree_current_user) { user }
      end

      context "but they do not own the target order" do
        it "redirects to unauthorized" do
          delete :destroy, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "and they own the target order" do
        before do
          order.update_attribute(:user_id, user.id)
        end

        context "when the destroy action succeeds" do
          it "redirects to the order confirmation page" do
            delete :destroy, params
            expect(response).to redirect_to spree.order_path(order)
          end
        end

        context "when the destroy action fails" do
          before do
            allow(alteration).to receive(:destroy) { false }
          end

          it "adds a flash message and redirects to the enterprise shop path" do
            delete :destroy, params
            expect(flash[:error]).to eq I18n.t('alterations.destroy.failure')
            expect(response).to redirect_to enterprise_shop_path(enterprise)
          end
        end
      end
    end
  end
end
