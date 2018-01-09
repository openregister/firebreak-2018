require 'openregister'
require 'rubygems'
require 'zip'

class TemporaryRegisterController < ApplicationController
  before_filter :initializeRegisters

  def register_name
    @register_name = session[:register_name]

    render "register_name"
  end

  def save_register_name
    session[:register_name] = params[:register_name]

    redirect_from('register_name')
  end

  def description
    @register_description = session[:register_description]

    render "description"
  end

  def save_description
    session[:register_description] = params[:register_description]

    redirect_from('description')
  end

  def fields()
    @available_fields = @@registers_client.get_register('field', 'beta').get_records.select{
      |r| ['name', 'official-name', 'start-date', 'end-date'].include?(r.item.value['field'])
    }.map{|r| r.item.value}
    @included_fields = session[:included_fields] || []

    render "fields"
  end

  def save_fields
    session[:included_fields] = params[:included_fields]

    redirect_from('fields')
  end

  def custom_field
    @datatypes = @@registers_client.get_register('datatype', 'beta').get_records.map{|r| r.item.value}

    render "custom_field"
  end

  def save_custom_field
    redirect_from('custom_field')
  end

  def linked_registers
    @registers = @@registers_client.get_register('register', 'beta').get_records.select{
      |r| ['register', 'field', 'datatype'].exclude?(r.item.value['register'])
    }.map{|r| r.item.value}
    @linked_registers = session[:linked_registers] || []

    render "linked_registers"
  end

  def save_linked_registers
    session[:linked_registers] = params[:included_registers]

    redirect_from('linked_registers')
  end

  def upload_data
    render "upload_data"
  end

  def save_upload_data
    redirect_from('upload_data')
  end

  def summary()
    @register_name = session[:register_name]
    @register_description = session[:register_description]
    # @field = session[:fieldName]
    # @pickerData = PickerDataService.new().generate(@register['register'], @register['_uri'], @field)
    @linked_registers = []
    @included_fields = session[:included_fields]

    render "summary"
  end

  def create_register
    redirect_from('create_register')
  end

  def confirmation
    render "congratulations"
  end

  def saveField
    session[:fieldName] = params[:fieldName]
    @register = session[:register]
    @field = session[:fieldName]
    @pickerData = PickerDataService.new().generate(@register['register'], @register['_uri'], @field)

    redirect_to controller: 'temporary_register', action: 'preview'
  end

  def download()
    @pickerHtml = File.read(Rails.root.join("app", "assets", "static", "picker.html"))
    @pickerData = File.read(Rails.root.join("app", "assets", "static", "picker-data.json"))

    render "download"
  end

  def downloadZip()
    filesToZip = ["picker.html", "picker-data.json"]
    source = "/Users/karlbaker/RubymineProjects/Firebreak/app/assets/static"
    zipFileName = "code.zip"
    file = Tempfile.new(zipFileName)

    Zip::File.open(file.path, Zip::File::CREATE) do |zipFile|
      filesToZip.each do |filename|
        zipFile.add(filename, source + '/' + filename)
      end
    end

    zip_data = File.read(file.path)
    send_data(zip_data, :type => 'application/zip', :filename => zipFileName)
  end

  def initializeRegisters()
    @registers = OpenRegister.registers :discovery
    @registers.concat(OpenRegister.registers :alpha)
    @registers.concat(OpenRegister.registers :beta)
  end

  private

  def redirect_from(current_page)
    redirect_page = case current_page
                      when 'register_name'
                        'description'
                      when 'description'
                        'fields'
                      when 'custom_field'
                        'fields'
                      when 'fields'
                        'linked_registers'
                      when 'linked_registers'
                        'upload_data'
                      when 'upload_data'
                        'summary'
                      when 'create_register'
                        'confirmation'
                    end

    redirect_to controller: 'temporary_register', action: redirect_page
  end
end
