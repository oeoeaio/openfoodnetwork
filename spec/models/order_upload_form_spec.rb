require 'spec_helper'

describe OrderUploadForm do
  let(:csv) { Tempfile.new(['upload','csv']) }
  let(:shipping_method) { create(:shipping_method, name: 'Pickup')}
  let(:customer) { create(:customer, email: "customer@gmail.com")}
  let(:product) { create(:product) }
  let(:variant) { products.variants.first }
  let(:shop) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, coordinator: shop) }
  let(:user) { shop.owner }

  after { csv.delete }

  describe "validating files" do
    context "when not all required headers exist" do
      before do
        csv.write(CSV.generate { |csv| csv << ["Product", "Variant", "Quantity", "Shipping Method"] })
        csv.close
      end

      it "returns false" do
        form = OrderUploadForm.new(csv, user, shop, order_cycle)
        expect(form.valid?).to be false
      end
    end

    context "when all required headers exist" do
      before do
        csv.write(CSV.generate { |csv| csv << ["Customer Email", "Product", "Variant", "Quantity", "Shipping Method"] })
        csv.write(CSV.generate { |csv| csv << ["customer1@email.com", "Veggie Box", "Large (1 box)", "1", "Pickup"] })
        csv.write(CSV.generate { |csv| csv << ["customer2@email.com", "Veggie Box", "Small (1 box)", "2", "Delivery"] })
        csv.close
      end

      context "and some customers don't exist" do
        let(:customer1) { create(:customer, enterprise: shop) }

        it "returns false" do
          form = OrderUploadForm.new(csv, user, shop, order_cycle)
          expect(form.valid?).to be true
        end
      end

      context "and all customers exist" do
        before do
          csv.write(CSV.generate { |csv| csv << ["Customer Email", "Product", "Variant", "Quantity", "Shipping Method"] })
          csv.close
        end

        it "returns true" do
          form = OrderUploadForm.new(csv, user, shop, order_cycle)
          expect(form.valid?).to be true
        end
      end
    end
  end
end
