module Utils
  class Hex < String
    def initialize(str)
      @str = str.downcase
      raise ArgumentError, 'String must be hexadecimal' unless @str =~ /^[0-9A-Fa-f]+$/

      super(str)
    end

    def to_bytes
      int_arr = chars.each_slice(2).map do |pair|
        pair.join.to_i(16)
      end

      Bytes.new(int_arr)
    end

    def to_base64
      Base64.strict_encode64(to_bytes.to_bytestr)
    end

    def equal_length_xor(hex)
      to_bytes.equal_length_xor(hex.to_bytes).to_hex
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
      pack('C*')
    end

    def equal_length_xor(their_bytes)
      raise ArgumentError, 'Must be equal length' unless length == their_bytes.length

      int_arr = @bytes.zip(their_bytes).map do |our_byte, their_byte|
        our_byte ^ their_byte
      end

      Bytes.new(int_arr)
    end

    def to_hex
      @bytes.map do |byte|
        # Because we want hexadecimal, every byte should be represented by two hex digits.
        # For example, .to_s(16) will only give a single hex digit for 0-9.
        # Thanks team (Charmaine and Catherine)!
        byte.to_s(16).rjust(2, '0')
      end.join
    end

    def self.from_str(str)
      new(str.chars.map(&:ord))
    end
  end
end
