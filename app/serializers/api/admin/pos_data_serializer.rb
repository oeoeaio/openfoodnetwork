class Api::Admin::PosDataSerializer < ActiveModel::Serializer
  has_many :addresses, serializer: Api::Admin::AddressSerializer
  has_many :customers, serializer: Api::Admin::ForPos::CustomerSerializer
  has_many :line_items, serializer: Api::Admin::ForPos::LineItemSerializer
  has_many :orders, serializer: Api::Admin::ForPos::OrderSerializer
  has_many :payment_methods, serializer: Api::Admin::IdNameSerializer
  has_many :products, serializer: Api::Admin::ForPos::ProductSerializer
  has_many :variants, serializer: Api::Admin::ForPos::VariantSerializer
end
