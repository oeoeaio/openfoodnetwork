class Api::Admin::ForPos::CustomerSerializer < ActiveModel::Serializer
  attributes :id, :email, :enterprise_id, :user_id, :code
end
