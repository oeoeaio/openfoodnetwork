require 'spec_helper'

describe OrderUploadForm do
  let(:csv) { Tempfile.new(['upload','csv']) }
  let(:shipping_method) { create(:shipping_method, name: 'Pickup')}
  let(:customer) { create(:customer, email: "customer@gmail.com")}
  let(:product) { create(:product) }
  let(:variant) { products.variants.first }

  after { csv.delete }

  describe "validating files" do
    context "when not all required headers exist" do
      before do
        csv.write(CSV.generate { |csv| csv << ["Product", "Variant", "Quantity", "Shipping Method"] })
        csv.close
      end

      it "returns false" do
        form = OrderUploadForm.new(csv)
        expect(form.valid?).to be false
      end
    end

    context "when all required headers exist" do
      before do
        csv.write(CSV.generate { |csv| csv << ["Customer Email", "Product", "Variant", "Quantity", "Shipping Method"] })
        csv.close
      end

      it "returns true" do
        form = OrderUploadForm.new(csv)
        expect(form.valid?).to be true
      end
    end
  end
end
