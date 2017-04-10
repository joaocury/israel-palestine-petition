class Signature < ApplicationRecord
  PENDING_STATE = 'pending'.freeze
  INVALID_STATE = 'invalid'.freeze
  CONFIRMED_STATE = 'confirmed'.freeze
  MAX_PLACES_FOR_COUNTRY = 25.freeze
  COUNTRY_CODES = ISO3166::Country.all.map(&:alpha2)

  ## scopes ##
  scope :confirmed, -> { where(state: CONFIRMED_STATE) }
  scope :pending, -> { where(state: PENDING_STATE) }

  ## validations ##
  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, email: true, uniqueness: { case_sensitive: false }, on: :create
  validates :place, presence: true, length: { maximum: 50 }
  validates :country_code, presence: true, inclusion: { in: COUNTRY_CODES }
  validates :state, inclusion: { in: [PENDING_STATE, INVALID_STATE, CONFIRMED_STATE] }

  ## callbacks ##
  before_create :set_signing_token

  def confirm!
    return unless state == PENDING_STATE
    update_attributes!(state: CONFIRMED_STATE, signing_token: nil)

    # TODO: use a cache
    country = Country.find_by(country_code: country_code)
    if country && !country.has_confirmed_signatures?
      country.update_attributes!(has_confirmed_signatures: true)
    end
  end

  def confirmed?
    state == CONFIRMED_STATE
  end

  def self.count_by_country_code
    confirmed.group(:country_code).count
  end

  def self.count_for_country_code(country_code)
    confirmed.where(country_code: country_code).count if country_code.present?
  end

  def self.count_by_place_for_country(country_code)
    top_places = confirmed.where(country_code: country_code).group(:place).order('count(*) DESC')
    top_places = top_places.limit(MAX_PLACES_FOR_COUNTRY).count
    top_places.sort { |a, b| a[1] <=> b[1] }
  end

  private

  def set_signing_token
    # taken from Devise.friendly_token
    rlength = (20 * 3) / 4
    self.signing_token = SecureRandom.urlsafe_base64(rlength).tr('lIO0', 'sxyz')
  end
end

# == Schema Information
#
# Table name: signatures
#
#  id            :integer          not null, primary key
#  name          :string           not null
#  email         :string           not null
#  place         :string
#  country_code  :string           not null
#  state         :string           default("pending"), not null
#  signing_token :string
#  ip_address    :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
