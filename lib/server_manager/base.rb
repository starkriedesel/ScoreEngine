module ServerManager
  class Base
    include AbstractClass

    abstract_methods :server_list, :get_server
  end
end