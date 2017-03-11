class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  force_ssl if: :ssl_configured?
  before_action :set_locale

  private

  def set_locale
    locale = available_locale_from_param
    if locale
      I18n.locale = locale
    else
      redirect_to home_path(locale: user_preferred_locale)
    end
  end

  def available_locale_from_param
    if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
      params[:locale]
    end
  end

  def user_preferred_locale
    http_accept_language.compatible_language_from(I18n.available_locales) || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def ssl_configured?
    !Rails.env.development?
  end

  def fetch_ip_location
    GeoIpLookup.fetch_location_from_ip(request.remote_ip)
  rescue IPAddr::InvalidAddressError
  end
end
