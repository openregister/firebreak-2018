class CustomField
  include ActiveModel::Model

  attr_accessor :field_name, :field_description, :datatype
end