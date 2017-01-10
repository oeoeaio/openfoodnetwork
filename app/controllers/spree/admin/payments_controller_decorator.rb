Spree::Admin::PaymentsController.class_eval do
  append_before_filter :filter_payment_methods

  respond_to :json

  respond_override create: { json: { success: lambda {
    if request.referrer == main_app.admin_pos_url
      @payment.capture!
      order = Api::Admin::ForPos::OrderSerializer.new(@order.reload).serializable_hash
      render json: { order: order }
    else
      render_as_json @payment.reload
    end
  },
  failure: lambda {
    binding.pry
  } } }

  # When a user fires an event, take them back to where they came from
  # (we can't use respond_override because Spree no longer uses respond_with)
  def fire
    event = params[:e]
    return unless event && @payment.payment_source

    # Because we have a transition method also called void, we do this to avoid conflicts.
    event = "void_transaction" if event == "void"
    if @payment.send("#{event}!")
      flash[:success] = t(:payment_updated)
    else
      flash[:error] = t(:cannot_perform_operation)
    end
  rescue Spree::Core::GatewayError => ge
    flash[:error] = ge.message
  ensure
    redirect_to request.referer
  end

  def update
    if @line_item.update_attributes(params[:line_item])
      respond_with(@line_item) do |format|
        format.html { render :partial => 'spree/admin/orders/form', :locals => { :order => @order.reload } }
      end
    else
      respond_with(@line_item) do |format|
        format.html { render :partial => 'spree/admin/orders/form', :locals => { :order => @order.reload } }
      end
    end
  end

  private

  # Only show payments for the order's distributor
  def filter_payment_methods
    @payment_methods = @payment_methods.select{ |pm| pm.has_distributor? @order.distributor}
    @payment_method ||= @payment_methods.first
  end
end
