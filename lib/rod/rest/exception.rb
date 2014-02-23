module Rod
  module Rest
    class MissingResource < RuntimeError; end
    class APIError < RuntimeError; end
    class InvalidData < RuntimeError; end
  end
end
