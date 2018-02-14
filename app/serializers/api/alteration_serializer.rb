module Api
  class AlterationSerializer < ActiveModel::Serializer
    attributes :number, :destroy_path, :confirm_path

    has_one :target_order, serializer: Api::IdSerializer
    has_one :working_order, serializer: Api::IdSerializer

    def destroy_path
      alteration_path(object)
    end

    def confirm_path
      confirm_alteration_path(object)
    end
  end
end
