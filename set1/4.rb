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
      byte.to_s(16)
    end.join
  end
end

def score_candidate(str)
  char_count = str.length.to_f

  whitespace_count = 0
  punctuation_count = 0
  number_count = 0
  caps_count = 0
  letter_count = 0
  other_count = 0

  str.chars.each do |char|
    case char
    when /[A-Z]/
      caps_count += 1
      letter_count += 1
    when /[a-z]/
      letter_count += 1
    when /[0-9]/
      number_count += 1
    when /\s/
      whitespace_count += 1
    when /[.,!?]/
      punctuation_count += 1
    else
      other_count += 1
    end
  end

  whitespace_ratio = whitespace_count / char_count
  number_ratio = number_count / char_count
  caps_ratio = caps_count / char_count
  letter_ratio = letter_count / char_count
  other_ratio = other_count / char_count

  [
    whitespace_ratio > 1 / 10.0,
    whitespace_ratio < 1 / 3.0,
    number_ratio < 1 / 10.0,
    caps_ratio < 1 / 10.0,
    letter_ratio > 3 / 4.0,
    other_ratio < 1 / 10.0
  ]
end

def main
  file = File.open('set1/4.txt')
  candidates = file.readlines.flat_map do |line|
    line = line.strip
    encoded = Hex.new(line)
    encoded_bytes = encoded.to_bytes

    (0..128).map do |ord|
      encoded_bytes.equal_length_xor(Bytes.new([ord] * encoded_bytes.length)).to_bytestr
    end.to_a
  end

  # Jessica's trick
  # puts (candidates.select do |can|
  #   can =~ /.* the .*/
  # end.to_a)

  best_candidates = candidates.map.with_index do |can, i|
    [score_candidate(can).count(true), i / 128, can]
  end.sort_by(&:first)

  puts best_candidates.last.inspect
end

main
