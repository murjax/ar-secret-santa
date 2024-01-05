class EmailDomainValidator < ActiveModel::Validator
  VALID_DOMAINS = %w[gmail.com yahoo.com outlook.com example.com]

  def validate(record)
    if VALID_DOMAINS.none? { |domain| record.email.include?(domain) }
      record.errors.add(:email, 'has invalid domain')
    end
  end
end
