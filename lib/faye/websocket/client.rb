module Faye
  class WebSocket

    class Client
      include API

      def initialize(url, protocols = nil)
        @url    = url
        @uri    = URI.parse(url)
        @driver = ::WebSocket::Driver.client(self, :protocols => protocols)

        super()

        port = @uri.port || (@uri.scheme == 'wss' ? 443 : 80)

        EventMachine.connect(@uri.host, port, Connection) do |conn|
          @stream = conn
          conn.parent = self
        end
      end

    private

      def on_connect
        @stream.start_tls if @uri.scheme == 'wss'
        @driver.start
      end

      module Connection
        attr_accessor :parent

        def connection_completed
          parent.__send__(:on_connect)
        end

        def receive_data(data)
          parent.__send__(:parse, data)
        end

        def unbind
          parent.__send__(:finalize, '', 1006)
        end

        def write(data)
          send_data(data) rescue nil
        end
      end
    end

  end
end
