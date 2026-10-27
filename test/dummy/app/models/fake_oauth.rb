# frozen_string_literal: true

class FakeOauth
  CLIENTS = {
    "dummy-google-drive" => "dummy-google-drive-secret",
    "dummy-dropbox" => "dummy-dropbox-secret"
  }.freeze

  class << self
    def call(url, params)
      if url.to_s.include?("revoke")
        [200, {}]
      elsif params["grant_type"] == "refresh_token"
        refresh(params)
      else
        redeem(params)
      end
    end

    def issue_code(access_token:, refresh_token:, user_id:, email:, expires_in: 3600, scope: "files.read",
                   code_challenge: nil)
      code = SecureRandom.urlsafe_base64(32)
      store_code(
        code,
        {
          "access_token" => access_token,
          "refresh_token" => refresh_token,
          "user_id" => user_id,
          "email" => email,
          "expires_in" => expires_in,
          "scope" => scope
        },
        code_challenge
      )
      code
    end

    def valid_client?(client_id)
      CLIENTS.key?(client_id.to_s)
    end

    def reset!
      issued_codes.clear
    end

    private

    def redeem(params)
      return [401, { "error" => "invalid_client" }] unless credentials_match?(params)

      entry = take_code(params["code"].to_s)
      return [400, { "error" => "invalid_grant" }] if entry.nil?
      return [400, { "error" => "invalid_grant" }] unless verifier_matches?(params["code_verifier"], entry[:challenge])

      [200, entry[:payload]]
    end

    def refresh(params)
      return [401, { "error" => "invalid_client" }] unless credentials_match?(params)

      [
        200,
        {
          "access_token" => "refreshed-access-#{SecureRandom.hex(8)}",
          "refresh_token" => params["refresh_token"].to_s,
          "expires_in" => 3600,
          "scope" => "files.read"
        }
      ]
    end

    def credentials_match?(params)
      CLIENTS[params["client_id"].to_s] == params["client_secret"].to_s
    end

    def verifier_matches?(verifier, challenge)
      RecordingStudioOauth::Pkce.s256_matches?(verifier, challenge)
    end

    def store_code(code, payload, challenge)
      issued_codes[code] = { payload: payload, challenge: challenge.to_s }
    end

    def take_code(code)
      issued_codes.delete(code)
    end

    def issued_codes
      @issued_codes ||= {}
    end
  end
end
