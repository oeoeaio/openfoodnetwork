require 'spec_helper'

feature 'Multilingual', js: true do
  include AuthenticationWorkflow
  include WebHelper
  include CookieHelper

  it 'has two locales available' do
    expect(Rails.application.config.i18n[:default_locale]).to eq 'en'
    expect(Rails.application.config.i18n[:locale]).to eq 'en'
    expect(Rails.application.config.i18n[:available_locales]).to eq ['en', 'es']
  end

  it '18n-js fallsback to default language' do # in backend it doesn't until we change enforce_available_locales to `true`
    visit root_path
    set_i18n_locale('it')
    expect(get_i18n_translation('label_shops')).to eq 'Shops'
  end

  it 'can switch language by params' do
    visit root_path
    expect(get_i18n_locale).to eq 'en'
    expect(get_i18n_translation('label_shops')).to eq 'Shops'
    expect(cookie_named('locale')).to be_nil
    expect(page).to have_content 'Interested in getting on the Open Food Network?'
    expect(page).to have_content 'SHOPS'

    visit root_path(locale: 'es')
    expect(get_i18n_locale).to eq 'es'
    expect(get_i18n_translation('label_shops')).to eq 'Tiendas'
    expect(cookie_named('locale')[:value]).to eq 'es'
    expect(page).to have_content '¿Estás interesada en entrar en Open Food Network?'
    expect(page).to have_content 'TIENDAS'

    # it is not in the list of available of available_locales
    visit root_path(locale: 'it')
    expect(get_i18n_locale).to eq 'es'
    expect(get_i18n_translation('label_shops')).to eq 'Tiendas'
    expect(cookie_named('locale')[:value]).to eq 'es'
    expect(page).to have_content '¿Estás interesada en entrar en Open Food Network?'
    expect(page).to have_content 'TIENDAS'
  end

  context 'with user' do
    let(:user) { create(:user) }

    it 'updates user locale from cookie if it is empty' do
      visit root_path(locale: 'es')

      expect(cookie_named('locale')[:value]).to eq 'es'
      expect(user.locale).to be_nil
      quick_login_as user
      visit root_path

      expect(cookie_named('locale')[:value]).to eq 'es'
    end

    it 'updates user locale and stays in cookie after logout' do
      quick_login_as user
      visit root_path(locale: 'es')
      user.reload

      expect(user.locale).to eq 'es'

      logout

      expect(cookie_named('locale')[:value]).to eq 'es'
      expect(page).to have_content '¿Estás interesada en entrar en Open Food Network?'
      expect(page).to have_content 'TIENDAS'
    end
  end

  describe "using the language switcher UI" do
    context "when there is only one language available" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("LOCALE").and_return("en")
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return("en")
      end

      it "hides the dropdown language menu" do
        visit root_path
        expect(page).to_not have_css 'ul.right li.language-switcher.has-dropdown'
      end
    end

    context "when there are multiple languages available" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("LOCALE").and_return("en")
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return("en,es")
      end

      it "allows switching language via the main navigation" do
        visit root_path

        expect(page).to have_content 'SHOPS'

        find('ul.right li.language-switcher').click
        within'ul.right li.language-switcher ul.dropdown' do
          expect(page).to have_link I18n.t('language_name', locale: :en), href: '?locale=en'
          expect(page).to have_link I18n.t('language_name', locale: :es, default: 'Language Name'), href: '?locale=es'

          find('li a[href="?locale=es"]').click
        end

        expect(cookie_named('locale')[:value]).to eq 'es'
        expect(page).to have_content 'TIENDAS'
      end
    end
  end
end
