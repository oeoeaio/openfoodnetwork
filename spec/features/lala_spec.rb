require 'spec_helper'

feature "Lala", js: true do
  before do
    allow(Stripe).to receive(:publishable_key) { "some_token" }
  end

  it "shows a card interface" do
    visit "/lala"

    # Shows the interface for adding a card
    expect(page).to have_selector '#card-element.StripeElement'
  end
end
