@@registers_client ||= RegistersClient::RegisterClientManager.new(cache_duration: 600)
@@registers_orj_service ||= RegisterORJService.new