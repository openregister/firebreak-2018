require 'openregister'
require 'rubygems'
require 'zip'
require 'aws-sdk'
require 'json'
require 'rest-client'
require 'tempfile'

class TemporaryRegisterController < ApplicationController
  before_filter :initialize_data

  def register_name
    session.clear()

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
    unless (session.has_key?(:custom_fields))
      session[:custom_fields] = []
      session[:custom_fields] << { "field" => session[:register_name], "text" => "Primary key field for #{session[:register_name]} register", "datatype" => 'string' }
    end

    @available_fields.concat(custom_fields_for_view)
    @included_fields = session[:included_fields] || [session[:register_name]]
    @register_name = session[:register_name]

    render "fields"
  end

  def save_fields
    unless (session.has_key?(:included_fields))
      session[:included_fields] = []
    end

    session[:included_fields] = params[:included_fields]

    redirect_from('fields')
  end

  def create_custom_field
    @datatypes = @@registers_client.get_register('datatype', 'beta').get_records.map{|r| r.item.value}
    @custom_field = CustomField.new

    render "custom_field"
  end

  def save_custom_field
    session[:custom_fields] << CustomField.new(params.require(:custom_field).permit(:field, :text, :datatype))

    redirect_from('create_custom_field')
  end

  def linked_registers
    @registers = @@registers_client.get_register('register', 'beta').get_records.select{
      |r| ['register', 'field', 'datatype'].exclude?(r.item.value['register'])
    }.map{|r| r.item.value}
    @linked_registers = session[:linked_registers] || []

    render "linked_registers"
  end

  def save_linked_registers
    session[:linked_registers] = params[:included_registers] || []

    redirect_from('linked_registers')
  end

  def upload_data
    render "upload_data"
  end

  def save_upload_data
    file = params[:register_data]

    upload_register_data_to_s3(@s3Client, session[:unique_register_id], file)

    session[:register_data] = { original_filename: file.original_filename, path: file.path }

    redirect_from('upload_data')
  end

  def summary()
    @register_name = session[:register_name]
    @register_description = session[:register_description]
    @linked_registers = @@registers_client.get_register('register', 'beta').get_records
                            .select{|r| session[:linked_registers].include?(r.item.value['register'])}
                            .map{|r| r.item.value}
    @included_fields = @@registers_client.get_register('field', 'beta').get_records
                           .select{|f| session[:included_fields].include?(f.item.value['field'])}
                           .map{|f| f.item.value}
    @included_fields.concat(custom_fields_for_view)
    @uploaded_file = session[:register_data]['original_filename']
    @upload_file_name = session[:register_data]['path']

    render "summary"
  end

  def create_register
    register_id = session[:unique_register_id]

    upload_field_definition_to_s3(@s3Client, register_id)
    upload_register_defintion_to_s3(@s3Client, register_id)

    lambda_client = Aws::Lambda::Client.new(region: 'eu-west-1')
    lambda_payload = JSON.generate({register_name: session[:register_name], phase: "experiment", register_id: session[:unique_register_id], register_data_file: session[:register_data]['original_filename'], custodian: "John Smith"})

    lambda_response = lambda_client.invoke({
        function_name: 'tsv_to_rsf',
        invocation_type: 'RequestResponse',
        log_type: 'None',
        payload: lambda_payload
    })

    result = JSON.parse(lambda_response.payload.string)
    rsf_data = Tempfile.new('data')
    rsf_data << result['rsf']
    rsf_data.flush

    register_endpoint = @@registers_orj_service.get_next_available_register

    load_rsf_response = RestClient::Request.execute(method: :post, url: "#{register_endpoint}/load-rsf", payload: File.open(rsf_data.path, 'r'), headers: { content_type: 'application/uk-gov-rsf', authorization: 'Basic b3BlbnJlZ2lzdGVyOmZpcmVicmVhaw==' })

    rsf_data.close

    # objects_to_delete = @s3Client.bucket('firebreak-register-data').objects({prefix: register_id})
    # objects_to_delete.batch_delete!({request_payer: "requester"})
    # objects_to_delete = s3Client.bucket('firebreak-register-data').object({prefix: register_id})
    # delete_register_files_from_s3(@s3Client, register_id, session[:register_name])

    redirect_from('create_register')
  end

  def confirmation
    # Delete uploaded files from S3

    render "congratulations"
  end

  def initialize_data()
    @available_fields = @@registers_client.get_register('field', 'beta').get_records.select{
        |r| ['name', 'official-name', 'start-date', 'end-date'].include?(r.item.value['field'])
    }.map{|r| r.item.value}

    @s3Client = Aws::S3::Resource.new(region:'eu-west-1');

    unless (session.has_key?(:unique_register_id))
      session[:unique_register_id] = Time.now.to_i.to_s
    end
  end

  private

  def upload_field_definition_to_s3(s3Client, register_id)
    session[:included_fields].each do |field_name|
      fields_location = session[:custom_fields].select{|f| f['field'] == field_name}.length == 1 ? session[:custom_fields] : @available_fields
      field = fields_location.select{|f| f['field'] == field_name}.first
      register = field_name == session[:register_name] ? session[:register_name] : '';
      field_yaml = { "cardinality" => '1', "datatype" => field['datatype'], "field" => field['field'], "phase" => 'experiment', "register" => register, "text" => field['text']}.to_yaml

      obj = s3Client.bucket('firebreak-register-data').object("#{ register_id }/field/#{ field['field'] }.yaml")
      obj.put(body: field_yaml)
    end
  end

  def upload_register_defintion_to_s3(s3Client, register_id)
    register_yaml = { "fields" => session[:included_fields], "phase" => 'experiment', "register" => session[:register_name], "registry" => "government-digital-service", "text" => session[:register_description] }.to_yaml
    obj = s3Client.bucket('firebreak-register-data').object("#{ register_id }/register/#{ session[:register_name] }.yaml")
    obj.put(body: register_yaml)
  end

  def upload_register_data_to_s3(s3Client, register_id, file)
    obj = s3Client.bucket('firebreak-register-data').object("#{ register_id }/data/#{ file.original_filename }")
    obj.upload_file(file.path)
  end

  def delete_register_files_from_s3(s3Client, register_id, register_name)
    session[:included_fields].each do |field_name|
      obj = s3Client.bucket('firebreak-register-data').object("#{ register_name }/field/#{ field_name }.yaml")
      obj.delete
    end

    obj = s3Client.bucket('firebreak-register-data').object("#{ register_id }/register/#{ register_name }.yaml")
    obj.delete

    obj = s3Client.bucket('firebreak-register-data').object("#{ register_id }/data/#{ session[:register_data]['original_filename'] }")
    obj.delete
  end

  def custom_fields_for_view
    session[:custom_fields].map{|cf| {'field' => cf['field'], 'text' => cf['text'], 'datatype' => cf['datatype']}}
  end

  def redirect_from(current_page)
    redirect_page = case current_page
                      when 'register_name'
                        'description'
                      when 'description'
                        'fields'
                      when 'create_custom_field'
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
