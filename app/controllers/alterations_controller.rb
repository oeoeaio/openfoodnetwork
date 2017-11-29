class AlterationsController < BaseController
  layout 'darkswarm'

  def create
    find_or_initialize_alteration
    if @alteration.save
      session[:order_id] = @alteration.working_order_id
      redirect_to enterprise_shop_path(current_distributor)
    else
      flash[:error] = @alteration.errors.full_messages.join(", ")
      redirect_to spree.order_path(@alteration.target_order)
    end
  end

  private

  def find_or_initialize_alteration
    @alteration = Alteration.find_by_target_order_id(params[:target_order_id])
    unless @alteration
      @alteration = Alteration.new(target_order_id: params[:target_order_id])
      @alteration.initialize_working_order
    end
    authorize! :create, @alteration
  end
end
