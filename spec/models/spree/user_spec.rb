require 'spec_helper'

describe Spree.user_class do
  describe "associations" do
    it { should have_many(:owned_enterprises) }

    describe "addresses" do
      let(:user) { create(:user, bill_address: create(:address)) }

      it 'updates billing address with new address' do
        old_bill_address = user.bill_address
        new_bill_address = create(:address, firstname: 'abc')

        user.update_attributes(bill_address_attributes: new_bill_address.clone.attributes.merge('id' => old_bill_address.id))

        expect(user.bill_address.id).to eq old_bill_address.id
        expect(user.bill_address.firstname).to eq new_bill_address.firstname
      end

      it 'creates new shipping address' do
        new_ship_address = create(:address, firstname: 'abc')

        user.update_attributes(ship_address_attributes: new_ship_address.clone.attributes)

        expect(user.ship_address.id).not_to eq new_ship_address.id
        expect(user.ship_address.firstname).to eq new_ship_address.firstname
      end
    end

    describe "enterprise ownership" do
      let(:u1) { create(:user, enterprise_limit: 2) }
      let(:u2) { create(:user, enterprise_limit: 1) }
      let!(:e1) { create(:enterprise, owner: u1) }
      let!(:e2) { create(:enterprise, owner: u1) }

      it "provides access to owned enterprises" do
        expect(u1.owned_enterprises(:reload)).to include e1, e2
      end

      it "enforces the limit on the number of enterprise owned" do
        expect(u2.owned_enterprises(:reload)).to eq []
        u2.owned_enterprises << e1
        expect { u2.save! }.to_not raise_error
        expect do
          u2.owned_enterprises << e2
          u2.save!
        end.to raise_error ActiveRecord::RecordInvalid, "Validation failed: #{u2.email} is not permitted to own any more enterprises (limit is 1)."
      end
    end

    describe "group ownership" do
      let(:u1) { create(:user) }
      let(:u2) { create(:user) }
      let!(:g1) { create(:enterprise_group, owner: u1) }
      let!(:g2) { create(:enterprise_group, owner: u1) }
      let!(:g3) { create(:enterprise_group, owner: u2) }

      it "provides access to owned groups" do
        expect(u1.owned_groups(:reload)).to match_array([g1, g2])
        expect(u2.owned_groups(:reload)).to match_array([g3])
      end
    end

    it "loads a user's customer representation at a particular enterprise" do
      u = create(:user)
      e = create(:enterprise)
      c = create(:customer, user: u, enterprise: e)

      u.customer_of(e).should == c
    end
  end

  context "#create" do
    it "should send a confirmation email" do
      expect do
        create(:user, confirmed_at: nil)
      end.to enqueue_job Delayed::PerformableMethod
      expect(Delayed::Job.last.payload_object.method_name).to eq(:send_on_create_confirmation_instructions_without_delay)
    end

    context "with the the same email as existing customers" do
      let(:email) { Faker::Internet.email }
      let(:enterprise1) { create(:enterprise) }
      let(:enterprise2) { create(:enterprise) }
      let!(:customer1) { create(:customer, user: nil, email: email, enterprise: enterprise1) }
      let!(:customer2) { create(:customer, user: nil, email: email, enterprise: enterprise2) }
      let!(:user) { create(:user, email: email) }

      it "should associate these customers with the created user" do
        expect(user.customers.reload).to include customer1, customer2
        expect(user.customer_of(enterprise1)).to be_truthy
        expect(user.customer_of(enterprise2)).to be_truthy
      end
    end
  end

  context "confirming email" do
    it "should send a welcome email" do
      expect do
        create(:user, confirmed_at: nil).confirm!
      end.to enqueue_job ConfirmSignupJob
    end
  end

  describe "known_users" do
    let!(:u1) { create(:user) }
    let!(:u2) { create(:user) }
    let!(:u3) { create(:user) }
    let!(:e1) { create(:enterprise, owner: u1, users: [u1, u2]) }

    describe "as an enterprise user" do
      it "returns a list of users which manage shared enterprises" do
        expect(u1.known_users).to include u1, u2
        expect(u1.known_users).to_not include u3
        expect(u2.known_users).to include u1, u2
        expect(u2.known_users).to_not include u3
        expect(u3.known_users).to_not include u1, u2, u3
      end
    end

    describe "as admin" do
      let(:admin) { create(:admin_user) }

      it "returns all users" do
        expect(admin.known_users).to include u1, u2, u3
      end
    end
  end

  describe "default_card" do
    let(:user) { create(:user) }

    context "when the user has no credit cards" do
      it "returns nil" do
        expect(user.default_card).to be nil
      end
    end

    context "when the user has one credit card" do
      let!(:card) { create(:credit_card, user: user) }

      it "it should be assigned as the default and be returned" do
        expect(card.reload.is_default).to be true
        expect(user.default_card.id).to be card.id
      end
    end

    context "when the user has more than one card" do
      let!(:card1) { create(:credit_card, user: user) }
      let!(:card2) { create(:credit_card, user: user, is_default: true) }

      it "it returns the card which is specified as the default" do
        expect(user.default_card.id).to be card2.id
      end
    end
  end
end
