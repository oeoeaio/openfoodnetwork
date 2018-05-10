describe Api::Admin::SubscriptionCustomerSerializer do
  let(:distributor) { create(:distributor_enterprise) }
  let(:delivery) { create(:shipping_method, require_ship_address: true, distributors: [distributor]) }
  let(:email) { 'some@email.com' }
  let(:address) { create(:address) }
  let(:customer) { create(:customer, email: email) }
  let(:order) { create(:completed_order_with_totals, email: email, user: nil, customer: nil, distributor: distributor) }

  before do
    order.update_attribute(:ship_address_id, address.id)
    order.update_attribute(:shipping_method_id, delivery.id)
  end

  it "serializes a customer " do
    serializer = Api::Admin::SubscriptionCustomerSerializer.new customer
    result = JSON.parse(serializer.to_json)
    expect(result['email']).to eq customer.email
    expect(result['ship_address']['id']).to be nil
    expect(result['ship_address']['address1']).to eq address.address1
    expect(result['ship_address']['firstname']).to eq address.firstname
  end
end
