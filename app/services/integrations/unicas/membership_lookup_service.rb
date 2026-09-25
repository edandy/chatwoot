class Integrations::Unicas::MembershipLookupService
  TIMEOUT_SECONDS = 5

  def self.configured?
    base_url.present? && token.present?
  end

  def self.base_url
    ENV.fetch('UNICAS_API_BASE_URL', '').to_s.chomp('/')
  end

  def self.token
    ENV.fetch('UNICAS_API_TOKEN', '').to_s
  end

  def initialize(phone_number)
    @phone_number = phone_number
  end

  def perform
    return empty_result if @phone_number.blank? || !self.class.configured?

    response = HTTParty.post(
      "#{self.class.base_url}/api/v1/internal/chatwoot/memberships",
      headers: {
        'Authorization' => "Bearer #{self.class.token}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      },
      body: { phone: @phone_number }.to_json,
      timeout: TIMEOUT_SECONDS
    )

    raise StandardError, lookup_error_message(response) unless response.success?

    data = response.parsed_response.is_a?(Hash) ? response.parsed_response['data'] : nil
    data ||= {}

    {
      found: data['found'] == true,
      user: data['user'],
      memberships: data['memberships'] || []
    }
  end

  private

  def empty_result
    { found: false, user: nil, memberships: [] }
  end

  def lookup_error_message(response)
    parsed = response.parsed_response
    return parsed['message'] if parsed.is_a?(Hash) && parsed['message'].present?

    'Unicas lookup failed'
  end
end
