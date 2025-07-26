require 'openssl'
require 'base64'
require_relative 'testing'

BLOCKSIZE = 128
BLOCKSIZE_BYTES = BLOCKSIZE / 8

def encrypt_block_aes(textblock, key)
  cipher = OpenSSL::Cipher::AES.new(BLOCKSIZE, :ECB)
  # Need to call .encrypt first for some reason when using this library.
  # See: https://gist.github.com/tcaddy/c2282fb795581d560fb7a42ff1f5e8d6
  cipher.encrypt
  cipher.padding = 0
  cipher.key = key
  cipher.update(textblock) + cipher.final
end

def decrypt_block_aes(textblock, key)
  cipher = OpenSSL::Cipher::AES.new(BLOCKSIZE, :ECB)
  # No clue why I need to set padding, but is important for cipher.final to work properly.
  cipher.padding = 0
  cipher.key = key
  cipher.decrypt
  cipher.update(textblock) + cipher.final
end

# Assumes equal length
def char_array_xor_to_str(arr1, arr2)
  raise "#{arr1.length} != #{arr2.length}" unless arr1.length == arr2.length

  bytearray_to_str(array_xor(arr1.map(&:ord), arr2.map(&:ord)))
end

def array_xor(arr1, arr2)
  raise "#{arr1.length} != #{arr2.length}" unless arr1.length == arr2.length

  arr1.zip(arr2).map { |a, b| a ^ b }
end

def bytearray_to_str(arr)
  arr.pack('C*')
end

# CBC mode = XOR the previous block ciphertext with the current block plaintext. Then AES that block to encrypt.
# For the first block, XOR with the initialization vector.

# Assume everything is an ASCII string
def decrypt_aes_cbc_mode(ciphertext, key, init)
  raise "#{init.length} != #{BLOCKSIZE_BYTES}" unless init.length == BLOCKSIZE_BYTES

  cbc_block = init.chars

  plain_blocks = ciphertext.chars.each_slice(BLOCKSIZE_BYTES).map do |cipherblock|
    aes_decrypted_block = decrypt_block_aes(cipherblock.join, key).chars
    plainblock = char_array_xor_to_str(aes_decrypted_block, cbc_block)

    cbc_block = cipherblock

    plainblock
  end

  plain_blocks.join
end

# Combine the ciphertext of previous block with plaintext of current block by XOR before AES'ing
# XOR the first plaintext with an an initialization block.
def encrypt_aes_cbc_mode(plaintext, key, init)
  raise "#{init.length} != #{BLOCKSIZE_BYTES}" unless init.length == BLOCKSIZE_BYTES

  cbc_block = init.chars

  cipher_blocks = plaintext.chars.each_slice(BLOCKSIZE_BYTES).map do |plainblock|
    mixed_block = char_array_xor_to_str(plainblock, cbc_block)
    cipherblock = encrypt_block_aes(mixed_block, key)

    cbc_block = cipherblock.chars

    cipherblock
  end

  cipher_blocks.join
end

lines = File.read('10.txt')
ciphertext = Base64.decode64(lines)

lyrics = decrypt_aes_cbc_mode(ciphertext, 'YELLOW SUBMARINE', "\x00" * BLOCKSIZE_BYTES)
puts lyrics

Testing.assert_equals(
  encrypt_aes_cbc_mode(lyrics, 'YELLOW SUBMARINE', "\x00" * BLOCKSIZE_BYTES),
  ciphertext
)

def encrypt_then_decrypt(plaintext, key, padding)
  decrypt_aes_cbc_mode(encrypt_aes_cbc_mode(plaintext, key, padding), key, padding)
end

Testing.assert_equals(
  encrypt_then_decrypt('YELLOW SUBMARINE', 'YELLOW SUBMARINE', "\x00" * BLOCKSIZE_BYTES),
  'YELLOW SUBMARINE'
)
