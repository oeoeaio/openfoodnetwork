require 'spec_helper'

feature "Lala", js: true do
  before do
    allow(Stripe).to receive(:publishable_key) { "some_token" }
  end

  it "shows a card interface" do
    visit "/lala"
    expect(page).to have_content "SHOPS"
    expect(page).to have_content "MAP"
    expect(page).to have_content "ABOUT"
    sleep 5
    click_button "lalala"
    # Shows the interface for adding a card
    expect(page).to have_selector '#card-element.StripeElement'
  end
end
