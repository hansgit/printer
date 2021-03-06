module Printer::BackendServer
  autoload :Base,     "printer/backend_server/base"
  autoload :Preview,  "printer/backend_server/preview"
  autoload :Print,    "printer/backend_server/print"
  autoload :Polling,  "printer/backend_server/polling"
  autoload :Pages,    "printer/backend_server/pages"
  autoload :Settings, "printer/backend_server/settings"
  autoload :Archive,  "printer/backend_server/archive"

  App = Rack::Builder.new do
    map("/printer")    { run Printer::BackendServer::Polling  }
    map("/preview")    { run Printer::BackendServer::Preview  }
    map("/print")      { run Printer::BackendServer::Print    }
    map("/my-printer") { run Printer::BackendServer::Settings }
    map("/archive")    { run Printer::BackendServer::Archive  }
    map("/")           { run Printer::BackendServer::Pages    }
  end
end
