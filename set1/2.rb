class Hex < String
  def initialize(str)
    @str = str.downcase
    raise ArgumentError, 'String must be hexadecimal' unless @str =~ /^[0-9A-Fa-f]+$/

    super(str)
  end

  def to_bytes
    int_arr = self.chars.each_slice(2).map do |pair|
      pair.join.to_i(16)
    end

    Bytes.new(int_arr)
  end

  def to_base64
    Base64.strict_encode64(self.to_bytes.to_bytestr)
  end

  def equal_length_xor(hex)
    self.to_bytes.equal_length_xor(hex.to_bytes).to_hex
  end
end

class Bytes < Array
  def initialize(bytes)
    @bytes = bytes
    super(bytes)
  end

    # Pack the bytes from Array[Integer] into an String. When printed, it will be interpreted as ASCII.
  def to_bytestr
    # C = 8 bit integer, * = arbitrary count
    self.pack("C*")
  end

  def equal_length_xor(their_bytes)
    raise ArgumentError, 'Must be equal length' unless self.length == their_bytes.length

    int_arr = @bytes.zip(their_bytes).map do |our_byte, their_byte|
      our_byte ^ their_byte
    end

    Bytes.new(int_arr)
  end

  def to_hex
    @bytes.map do |byte|
      byte.to_s(16)
    end.join
  end
end

def main
  xored = Hex.new('1c0111001f010100061a024b53535009181c').equal_length_xor(Hex.new('686974207468652062756c6c277320657965'))


  if xored == Hex.new('746865206b696420646f6e277420706c6179')
    puts '✅ works!'
  else
    puts "doesn't: #{xored}"
  end
end

main



