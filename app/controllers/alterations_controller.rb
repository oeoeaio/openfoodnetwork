class AlterationsController < BaseController
  layout 'darkswarm'

  # POST /alterations
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

  # PUT /alterations/:id/confirm
  def confirm
    @alteration = Alteration.find(params[:id])
    authorize! :confirm, @alteration

    if @alteration.confirm!
      redirect_to spree.order_path(@alteration.target_order)
    else
      flash[:error] = @alteration.errors.full_messages.join(", ")
      redirect_to enterprise_shop_path(@alteration.target_order.distributor)
    end
  end

  # DELETE /alterations/:id
  def destroy
    @alteration = Alteration.find(params[:id])
    authorize! :destroy, @alteration

    if @alteration.destroy
      redirect_to spree.order_path(@alteration.target_order)
    else
      flash[:error] = t("alterations.destroy.failure")
      redirect_to enterprise_shop_path(@alteration.target_order.distributor)
    end
  end

  private

  def find_or_initialize_alteration
    @alteration = Alteration.find_by_target_order_id(params[:target_order_id])
    @alteration ||= Alteration.new(target_order_id: params[:target_order_id])
    authorize! :create, @alteration
  end
end
