# Super simple flash policy file server
# See https://github.com/igrigorik/em-websocket/issues/61

require 'eventmachine'

module FlashPolicy
  def post_init
    cross_domain_xml =<<-EOF
    <cross-domain-policy>
       <allow-access-from domain="*" to-ports="*" />
    </cross-domain-policy>  
    EOF

    send_data cross_domain_xml
    close_connection_after_writing
  end
end

EM.run {
  EventMachine::start_server '0.0.0.0', 843, FlashPolicy
}
