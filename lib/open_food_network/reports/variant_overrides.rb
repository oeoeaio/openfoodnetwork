# frozen_string_literal: true

module OpenFoodNetwork
  module Reports
    class VariantOverrides
      def initialize(line_items:, distributor_id:)
        @line_items = line_items
        @distributor_id = @distributor_id
      end

      def indexed
        Hash[
          variant_overrides.map do |variant_override|
            [variant_override.variant, variant_override]
          end
        ]
      end

      private

      attr_reader :line_items

      def variant_overrides
        VariantOverride
          .joins(:variant)
          .preload(:variant)
          .where(
            hub_id: distributor_id,
            variant_id: line_items.select(:variant_id),
          )
      end
    end
  end
end
