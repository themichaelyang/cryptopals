require_relative('utils')

partial_key = 'ICE'
stanza = "Burning 'em, if you ain't quick and nimble\nI go crazy when I hear a cymbal"

def xor_unequal(plaintext, partial_key)
  plaintext_bytes = Utils::Bytes.new(plaintext.chars.map(&:ord))
  partial_key_bytes = Utils::Bytes.new(partial_key.chars.map(&:ord))
  repeats = plaintext_bytes.length / partial_key_bytes.length
  trimmed_bytes = plaintext_bytes.length % partial_key_bytes.length

  key = partial_key_bytes * repeats + partial_key_bytes[0...trimmed_bytes]

  plaintext_bytes.equal_length_xor(key)
end

expected = '0b3637272a2b2e63622c2e69692a23693a2a3c6324202d623d63343c2a26226324272765272' \
           'a282b2f20430a652e2c652a3124333a653e2b2027630c692b20283165286326302e27282f'

def assert_equals(actual, expected)
  if actual == expected
    puts '✅ passed'
  else
    puts "😢 failed: got #{actual.inspect}, expected #{expected.inspect}"
  end
end

assert_equals(xor_unequal(stanza, partial_key).to_hex, expected)
