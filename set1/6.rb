require_relative('utils')
require_relative('testing')
require 'base64'

def binary_ham(a, b)
  raise Exception, 'not same length' if a.length != b.length

  Utils::Bytes.from_str(a).zip(Utils::Bytes.from_str(b)).sum do |a_ord, b_ord|
    binary_ham_int(a_ord, b_ord)
  end
end

def binary_ham_ords(a, b)
  raise Exception, 'not same length' if a.length != b.length

  a.zip(b).sum do |a_ord, b_ord|
    binary_ham_int(a_ord, b_ord)
  end
end

# Catherine used XOR and count 1's to get the binary hamming distance!
def binary_ham_int(a, b)
  small, big = [a, b].sort

  0.upto(big.bit_length).sum do |i|
    big[i] != small[i] ? 1 : 0
  end
end

def average_normalized_distance(bytes, key_size)
  seq_normalized_hamming = bytes.each_slice(key_size).each_cons(2).map do |slices|
    slice, next_slice = slices

    if next_slice.length != key_size
      nil
    else
      binary_ham_ords(slice, next_slice) / key_size.to_f
    end
  end.compact

  seq_normalized_hamming.sum / seq_normalized_hamming.length
end

def test_binary_ham
  Testing.assert_equals(binary_ham('this is a test', 'wokka wokka!!!'), 37)
  Testing.assert_equals(binary_ham_ords(Utils::Bytes.from_str('this is a test'), Utils::Bytes.from_str('wokka wokka!!!')), 37)
end

def get_best_key_size(bytes, min, max)
  key_size_distances = (min..max).map do |key_size|
    [average_normalized_distance(bytes, key_size), key_size]
  end

  key_size_distances.min[1]
end

def transpose_blocks(bytes, key_size)
  blocks = bytes.each_slice(key_size).to_a

  key_size.times.map do |i|
    blocks.map { |b| b[i] }
  end
end

# it is base 64 encoded
def read_file(filename)
  Utils::Bytes.from_str(Base64.decode64(File.read(filename)))
end

def test_best_key_size
  Testing.assert_equals(get_best_key_size(read_file('./6.txt'), 2, 40), 29)
end

def test_transpose_blocks
  Testing.assert_equals(transpose_blocks(read_file('./6.txt'), 20).length, 20)
end

def solve_xor_single_block(block)
  (0...255).map do |ord|
    candidate = Utils::Bytes.new(block).equal_length_xor(Utils::Bytes.new([ord] * block.length)).to_bytestr

    [score_candidate(candidate), ord.chr]
  end.max[1]
end

def score_candidate(str)
  by_freq = 'ETAONRISHDLFCMUGYPWBVKJXZQ'.downcase
  # For some reason, str.downcase produces the key in all lowercase?
  str.chars.sum do |c|
    by_freq.length - (by_freq.index(c) || by_freq.length)
  end
end

def test_solve_xor_single_block
  Testing.assert_equals(solve_xor_single_block(Utils::Bytes.from_str('abc')).length, 1)
end

def solve_xor(bytes)
  best_key_size = get_best_key_size(bytes, 2, 40)
  transposed = transpose_blocks(bytes, best_key_size)

  transposed.map do |block|
    solve_xor_single_block(block.compact)
  end.join
end

def xor_unequal(plaintext_bytes, partial_key)
  partial_key_bytes = Utils::Bytes.new(partial_key.chars.map(&:ord))
  repeats = plaintext_bytes.length / partial_key_bytes.length
  trimmed_bytes = plaintext_bytes.length % partial_key_bytes.length

  key = partial_key_bytes * repeats + partial_key_bytes[0...trimmed_bytes]

  plaintext_bytes.equal_length_xor(key)
end

def main
  test_binary_ham
  test_best_key_size
  test_transpose_blocks
  test_solve_xor_single_block

  bytes = read_file('./6.txt')

  partial_key = solve_xor(bytes)
  puts partial_key

  plaintext = xor_unequal(bytes, partial_key)
  puts plaintext.to_bytestr
end

main
