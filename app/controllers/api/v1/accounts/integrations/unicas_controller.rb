class Api::V1::Accounts::Integrations::UnicasController < Api::V1::Accounts::BaseController
  before_action :ensure_configured
  before_action :set_contact

  def memberships
    return render json: empty_payload if @contact.phone_number.blank?

    result = Integrations::Unicas::MembershipLookupService.new(@contact.phone_number).perform
    render json: {
      found: result[:found],
      user: result[:user],
      memberships: result[:memberships]
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def ensure_configured
    return if Integrations::Unicas::MembershipLookupService.configured?

    render json: empty_payload
  end

  def empty_payload
    { found: false, user: nil, memberships: [] }
  end

  def set_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end
end
