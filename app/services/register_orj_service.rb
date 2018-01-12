require 'rest-client'

class RegisterORJService
  def initialize
    @availableRegisters = [
        "7307392fed6e40c0bb153999317f742b",
        "e4de542bbc5e45a88b681708aaf9c5f7",
        "72ed97d95eba4e61b6a996a976fbe71f",
        "b28520b8d0db4442a2b2aee302b311dd"
    ]
    @current_register = 1
  end

  def get_next_available_register
    if (@current_register == @availableRegisters.length)
      @current_register = 1
    else
      @current_register += 1
    end

    register_name = @availableRegisters[@current_register - 1]
    register_endpoint = get_register_endpoint(register_name)

    ORJ.new(register_endpoint, 'Basic <AUTH_HERE>')
  end

  private

  def get_register_endpoint(register_name)
    "https://#{register_name}.cloudapps.digital"
  end
end
