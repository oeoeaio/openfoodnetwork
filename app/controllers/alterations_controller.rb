class AlterationsController < BaseController
  layout 'darkswarm'

  def create
    alteration = Alteration.new(target_order_id: params[:target_order_id])
    authorize! :create, alteration
    alteration.initialize_working_order
    if alteration.save
      session[:order_id] = alteration.working_order_id
      redirect_to enterprise_shop_path(current_distributor)
    else
      flash[:error] = alteration.errors.full_messages.join(", ")
      redirect_to spree.order_path(alteration.target_order)
    end
  end
end
