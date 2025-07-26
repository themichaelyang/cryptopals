require_relative('testing')

class Bytes < Array
  def initialize(bytes)
    @bytes = bytes
    super(bytes)
  end

  def self.from_str(str)
    new(str.chars.map(&:ord))
  end
end

PADDING_BYTE = "\x04".freeze

def pad_pkcs7(text, blocksize, padding = PADDING_BYTE)
  text_bytes = Bytes.from_str(text)
  remainder = text_bytes.length % blocksize

  padding_size = blocksize - remainder

  text + (padding * padding_size)
end

Testing.assert_equals(pad_pkcs7('YELLOW SUBMARINE', 20), "YELLOW SUBMARINE\x04\x04\x04\x04")
