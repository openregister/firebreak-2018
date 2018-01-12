require 'rest-client'

class ORJ
  def initialize(endpoint, auth)
    @endpoint = endpoint
    @auth = auth
  end

  def load_rsf(rsf)
    clear
    RestClient::Request.execute(method: :post, url: "#{@endpoint}/load-rsf", payload: rsf, headers: { content_type: 'application/uk-gov-rsf', authorization: @auth })
  end

  def get_endpoint
    @endpoint
  end

  private

  def clear
    RestClient::Request.execute(method: :delete, url: "#{@endpoint}/delete-register-data", headers: { authorization: @auth })
  end
end