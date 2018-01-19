require 'rest-client'

class RegisterORJService
  def initialize
    @availableRegisters = [
        "7307392fed6e40c0bb153999317f742b",
        "72ed97d95eba4e61b6a996a976fbe71f",
        "b28520b8d0db4442a2b2aee302b311dd",
        "5bb345d6db9d41898a50b46493be0580",
        "9cb1b41f6f7c4cd699c9a067dbb828df",
        "d8406c96a9bf4fe29e62a81e36e7934d",
        "a2f6bfbb23b54317aab4e75f04b84595",
        "4868c21e1f0744868486686b7a6baf92"
    ]
    @current_register = 0
  end

  def get_all_registers
    @availableRegisters.map { |register| get_register_endpoint(register) }
  end

  def get_deployment_slot(register_endpoint)
    @availableRegisters.index { |host| register_endpoint.include?(host) } + 1
  end

  def get_register_for_deployment_slot(deployment_slot)
    register_name = @availableRegisters[deployment_slot]
    register_endpoint = get_register_endpoint(register_name)

    ORJ.new(register_endpoint, ENV['REGISTERS_AUTH'])
  end

  def get_next_available_register
    if (@current_register == @availableRegisters.length)
      @current_register = 1
    else
      @current_register += 1
    end

    register_name = @availableRegisters[@current_register - 1]
    register_endpoint = get_register_endpoint(register_name)

    ORJ.new(register_endpoint, ENV['REGISTERS_AUTH'])
  end

  private

  def get_register_endpoint(register_name)
    "https://#{register_name}.cloudapps.digital"
  end
end
