require 'json'

module EventMachine
  module WebSocket
    module JSMethods

      # js_command is a method that produces json data for a javascript command to be run. 
      # It requires a bit of js code in the browser for it to function.
      # look at the example web_socket_commands.js file
      # example 
      
      def js_command(method_name, *args)

        web_socket_command = {:method_name=>"#{method_name}", :vars=>[]}
        args.each do |arg|
          #TODO right now I only thought of a reason to have string and non string types.
          # This could be expanded on for more useful data types.
          web_socket_command[:vars] << {:value=>arg, :type=>arg.is_a?(String) ? 'String' : 'NotString'}
        end
        return web_socket_command.to_json

      end

    end
  end
end