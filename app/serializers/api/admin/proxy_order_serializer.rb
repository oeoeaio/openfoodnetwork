require 'spree/core/url_helpers'

class Api::Admin::ProxyOrderSerializer < ActiveModel::Serializer
  include Spree::Core::UrlHelpers

  attributes :id, :state, :edit_path, :number, :completed_at, :order_cycle_id, :total

  def total
    object.total.to_money.to_s
  end

  def completed_at
    object.completed_at.blank? ? "" : object.completed_at.strftime("%F %T")
  end

  def edit_path
    edit_admin_proxy_order_path(object)
  end
end
