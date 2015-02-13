describe Api::Admin::ProductSerializer do
  let(:product) { create(:product) }
  it "serializes a product" do
    serializer = Api::Admin::ProductSerializer.new product
    serializer.to_json.should match product.name
  end
end
