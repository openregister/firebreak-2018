require 'openregister'
require 'rubygems'
require 'zip'

class TemporaryRegisterController < ApplicationController
  before_filter :initializeRegisters

  def register_name
    render "register_name"
  end

  def save_register_name
    registerName = params[:register_name].split(':')[0]
    phase = params[:register_name].split(':')[1]

    session[:register] = @registers.select{|r| r.register == registerName && r.phase == phase}[0]

    redirect('register_name')
  end

  def description
    render "description"
  end

  def save_description
    @description = params[:register_description]

    redirect('description')
  end

  def fields()
    @available_fields = @@registers_client.get_register('field', 'beta').get_records.select{
      |r| ['name', 'official-name', 'start-date', 'end-date'].include?(r.item.value['field'])
    }.map{|r| r.item.value}

    render "fields"
  end

  def save_fields
    redirect('fields')
  end

  def linked_registers
    @registers = @@registers_client.get_register('register', 'beta').get_records.select{
      |r| ['register', 'field', 'datatype'].exclude?(r.item.value['register'])
    }.map{|r| r.item.value}

    render "linked_registers"
  end

  def save_linked_registers
    redirect_to controller: 'temporary_register', action: 'upload_data'
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

  def confirmation()
    render "confirmation"
  end

  def summary()
    @register = session[:register]
    @field = session[:fieldName]
    @pickerData = PickerDataService.new().generate(@register['register'], @register['_uri'], @field)

    render "summary"
  end

  def initializeRegisters()
    @registers = OpenRegister.registers :discovery
    @registers.concat(OpenRegister.registers :alpha)
    @registers.concat(OpenRegister.registers :beta)
  end

  private

  def redirect(current_page)
    redirect_page = case current_page
                      when 'register_name'
                        'description'
                      when 'description'
                        'fields'
                      when 'fields'
                        'linked_registers'
                    end

    redirect_to controller: 'temporary_register', action: redirect_page
  end
end
