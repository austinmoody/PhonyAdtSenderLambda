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

  logger.info("Sending #{number_messages} messages to #{host}:#{port}")

  t = TCPSocket.new(host, port)

  number_messages.times do
    m = HealthcarePhony::Adt.new
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
