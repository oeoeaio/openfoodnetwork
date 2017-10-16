class Api::Admin::ForPos::VariantSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :name_to_display

  has_one :product, serializer: Api::Admin::IdSerializer
end