require 'open_food_network/pos_data'

class Admin::PosController < Spree::Admin::BaseController
  layout 'admin/bare_foundation'

  before_filter :ensure_shop_and_oc_selected, only: :data

  def data
    data = OpenFoodNetwork::PosData.new(@shop, @order_cycle)
    render json: data, serializer: Api::Admin::PosDataSerializer
  end

  private

  def ensure_shop_and_oc_selected
    @shop = Enterprise.find_by_id(params[:shop_id])
    @order_cycle = OrderCycle.find_by_id(params[:order_cycle_id])
    unless @shop && @order_cycle
      render json: { error: 'Please select a shop and order cycle' }, status: 400
    end
  end

  def model_class
    # Slightly hacky way of getting correct authorisation for actions
    :pos
  end
end
