require 'openssl'
require 'base64'
require_relative('utils')

lines = File.read('8.txt').split

ciphertexts = lines.map do |line|
  [Utils::Bytes.from_str(Base64.decode64(line)), line]
end

# Because of ECB mode, there can be repeated cipher blocks if there are repeated plaintext blocks.
#
# The problem is worded kind of funny, but the key is to remember that they provide special input and
# this won't work on arbitrary inputs.
ciphertexts_unique_blocks = ciphertexts.map do |bytes, text|
  [bytes.each_slice(16).map.uniq.length, text]
end

puts ciphertexts_unique_blocks.min[1]
