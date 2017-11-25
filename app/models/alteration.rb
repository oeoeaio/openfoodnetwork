class Alteration < ActiveRecord::Base
  belongs_to :target_order, class_name: 'Spree::Order'
  belongs_to :working_order, class_name: 'Spree::Order'
end
