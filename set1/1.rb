require 'base64'

# > Always operate on raw bytes, never on encoded strings. Only use hex and base64 for pretty-printing.

class Hex < String
  def initialize(str)
    @str = str.downcase
    raise ArgumentError, 'String must be hexadecimal' unless @str =~ /^[0-9A-Fa-f]+$/

    super(str)
  end

  def to_bytes
    self.chars.each_slice(2).map do |pair|
      pair.join.to_i(16)
    end
  end

  # Pack the bytes from Array[Integer] into an String. When printed, it will be interpreted as ASCII.
  def to_bytestr
    # C = 8 bit integer, * = arbitrary count
    self.to_bytes.pack("C*")
  end

  def to_base64
    Base64.strict_encode64(self.to_bytestr)
  end
end

def main
  # We want to convert the hex bytes to base 64
  hex = '49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d'
  encoded = Hex.new(hex).to_base64

  if encoded == 'SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t'
    puts '✅ works!'
  else
    puts "doesn't: #{encoded}"
  end
end

main