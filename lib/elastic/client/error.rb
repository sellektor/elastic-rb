require 'json'

module Elastic
  class Client
    module Error
      def status
        return @status if defined?(@status)

        if captures = message.match(/^\[(?<status>\d+)\]/)
          @status = captures[:status].to_i
        end
      end

      def response
        return @response if defined?(@response)

        if captures = message.match(/(?<response>\{.+\})$/)
          @response = JSON.parse(captures[:response])
        end
      end
    end
  end
end
