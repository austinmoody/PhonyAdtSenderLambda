# frozen_string_literal: true

require 'healthcare_phony'
require 'logger'
require 'socket'

def lambda_handler(event:, context:)

  return_message = ''

  logger = Logger.new($stdout)
  logger.info('## ENVIRONMENT VARIABLES')
  logger.info(ENV.to_a)
  logger.info('## EVENT')
  logger.info(event)
  event.to_a

  number_messages = ENV['NUMBER_MESSAGES'].to_i
  host = ENV['HOST']
  port = ENV['PORT']
  mllp_start = '0b'
  mllp_end = '1c0d'

  message_parameters = {}
  message_parameters[:message_sending_facility] = ENV['SENDING_FACILITY'] unless ENV['SENDING_FACILITY'].nil?
  message_parameters[:message_sending_application] = ENV['SENDING_APPLICATION'] unless ENV['SENDING_APPLICATION'].nil?
  message_parameters[:message_receiving_application] = ENV['RECEIVING_APPLICATION'] unless ENV['RECEIVING_APPLICATION'].nil?
  message_parameters[:message_receiving_facility] = ENV['RECEIVING_FACILITY'] unless ENV['RECEIVING_FACILITY'].nil?
  message_parameters[:message_version] = ENV['MESSAGE_VERSION'] unless ENV['MESSAGE_VERSION'].nil?
  message_parameters[:patient_class] = ENV['PATIENT_CLASS'] unless ENV['PATIENT_CLASS'].nil?
  message_parameters[:adt_events] = ENV['ADT_EVENTS'] unless ENV['ADT_EVENTS'].nil?
  message_parameters[:message_control_id_pattern] = ENV['CONTROL_ID_PATTERN'] unless ENV['CONTROL_ID_PATTERN'].nil?
  message_parameters[:message_processing_id] = ENV['PROCESSING_ID'] unless ENV['PROCESSING_ID'].nil?

  logger.info("Sending #{number_messages} messages to #{host}:#{port}")

  t = TCPSocket.new(host, port)

  number_messages.times do
    m = HealthcarePhony::Adt.new(message_parameters)
    t.send "#{[mllp_start].pack("H*")}#{m.to_s}#{[mllp_end].pack("H*")}", 0

    logger.info("Message With ID #{m.hl7_message.message_control_id} sent...")

    reading_response = true
    ack_response = ''
    prev_read = ''
    while reading_response
      current_read = t.read(1)
      ack_response += current_read unless current_read.nil?
      reading_response = false if (prev_read+current_read == [mllp_end].pack("H*"))
      prev_read = current_read
    end

    logger.info("ACK: #{ack_response}")
  end

  t.close

  return_message
end
