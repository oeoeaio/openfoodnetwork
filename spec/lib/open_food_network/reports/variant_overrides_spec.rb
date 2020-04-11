require 'spec_helper'
require 'open_food_network/reports/variant_overrides'

module OpenFoodNetwork::Reports
  describe VariantOverrides do
    subject(:variant_overrides) do
      described_class.new(
        line_items: order.line_items,
        distributor_id: distributor.id,
      )
    end

    let(:distributor) { create(:distributor_enterprise) }
    let(:order) do
      create(:completed_order_with_totals, line_items_count: 1,
              distributor: distributor)
    end
    let(:variant) { order.line_items.first.variant }

    describe '#indexed' do
      let(:result) { variant_overrides.indexed }

      context 'when variant overrides exist for variants of specified line items' do
        let!(:variant_override) do
          create(
            :variant_override,
            hub: variant_override_distributor,
            variant: variant,
          )
        end

        context 'when the variant override is for the specified distributor' do
          let(:variant_override_distributor) { distributor }

          it 'includes the variant / variant override mapping in the index' do
            expect(result).to eq(
              variant => variant_override
            )
          end
        end

        context 'when the variant override is not for the specified distributor' do
          it 'does not include the variant / variant override mapping in the index' do
            expect(result).to eq({})
          end
        end
      end

      context 'when variant overrides don\'t exist for variants of specified line items'
        it 'returns an empty hash' do
          expect(result).to eq({})
        end
      end
    end
  end
end
