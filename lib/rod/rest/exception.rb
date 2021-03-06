module Rod
  module Rest
    class MissingResource < RuntimeError; end
    class APIError < RuntimeError; end
    class InvalidData < RuntimeError; end
    class UnknownResource < RuntimeError; end
    class CacheMissed < RuntimeError; end
  end
end
