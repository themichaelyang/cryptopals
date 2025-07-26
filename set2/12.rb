require_relative 'testing'
require 'openssl'
require 'base64'

BLOCKSIZE = 128
BLOCKSIZE_BYTES = BLOCKSIZE / 8

# 1. Feed identical bytes of your-string to the function 1 at a time --- 
# start with 1 byte ("A"), then "AA", then "AAA" and so on. 
# Discover the block size of the cipher. You know it, but do this step anyway.
def discover_block_size(encrypt)
  plaintext = 'aa'
  cipher = encrypt.call(plaintext * 2)

  until repeated_blocks?(cipher, plaintext.length)
    plaintext += 'a'
    # repeat the plaintext to get repeated blocks
    cipher = encrypt.call(plaintext * 2)
  end

  plaintext.length
end

def repeated_blocks?(string, blocksize)
  counts = string.chars.each_slice(blocksize).tally
  counts.select { |_k, v| v > 1 }.any?
end

def generate_plaintext
  'a' * BLOCKSIZE * 4
end

# 2. Detect that the function is using ECB. You already know, but do this step anyways.
# - ECB = Electronic Codebook mode (e.g. not using a block cipher)
# - CBC = Cipher Block Chaining (e.g. using a block cipher)
# 
# mostly from 11.rb, but changed to accept a function
def detect_mode(oracle)
  ciphertext = oracle.call(generate_plaintext)

  seen_blocks = []
  ciphertext.chars.each_slice(BLOCKSIZE_BYTES) do |block|
    if seen_blocks.include?(block)
      return :ECB
    else
      seen_blocks.append(block)
    end
  end

  :CBC
end

# 3. Knowing the block size, craft an input block that is exactly 1 byte short 
# (for instance, if the block size is 8 bytes, make "AAAAAAA"). 
# Think about what the oracle function is going to put in that last byte position.
def make_one_byte_short(blocksize)
  'a' * (blocksize - 1)
end

# 4. Make a dictionary of every possible last byte by feeding different strings to the oracle; 
# for instance, "AAAAAAAA", "AAAAAAAB", "AAAAAAAC", remembering the first block of each invocation.
def make_dictionary_of_last_bytes(blocksize, oracle)
  one_byte_short = make_one_byte_short(blocksize)
  encrypted_block_to_plaintext = {}

  ('A'..'z').each do |last_byte|
    plaintext_block = one_byte_short + last_byte
    
    # Only add first block of encrypted bytes
    encrypted_block_to_plaintext[oracle.call(plaintext_block)[...blocksize]] = plaintext_block
  end

  encrypted_block_to_plaintext
end

# 5. Match the output of the one-byte-short input to one of the entries in your dictionary. 
# You've now discovered the first byte of unknown-string.
def discover_last_byte(blocksize, oracle)
  possible_last_bytes = make_dictionary_of_last_bytes(blocksize, oracle)
  encrypted_one_byte_short = oracle.call(make_one_byte_short(blocksize))

  first_block = encrypted_one_byte_short[...blocksize]
  possible_last_bytes[first_block].chars.last
end

# 6. Repeat for the next byte.

# Okay, let's put it all together and make it generic:
def make_payload(blocksize, known_last_bytes: nil)
  'a' * (block_size - 1 - known_last_bytes.length)
end

UNKNOWN_STRING = Base64.decode64('Um9sbGluJyBpbiBteSA1LjAKV2l0aCBteSByYWctdG9wIGRvd24gc28gbXkgaGFpciBjYW4gYmxvdwpUaGUgZ2lybGllcyBvbiBzdGFuZGJ5IHdhdmluZyBqdXN0IHRvIHNheSBoaQpEaWQgeW91IHN0b3A/IE5vLCBJIGp1c3QgZHJvdmUgYnkK')

# mode is one of :ECB or :CBC
def encrypt_aes(text, key, mode)
  cipher = OpenSSL::Cipher::AES.new(BLOCKSIZE, mode)
  # Need to call .encrypt first for some reason when using this library.
  # See: https://gist.github.com/tcaddy/c2282fb795581d560fb7a42ff1f5e8d6
  cipher.encrypt
  cipher.key = key
  cipher.update(text) + cipher.final
end

def random_aes_key
  Random.bytes(BLOCKSIZE_BYTES)
end

def make_append_and_encrypt_with_consistent_key(unknown_string)
  consistent_random_key = Random.bytes(BLOCKSIZE_BYTES)

  lambda do |plaintext|
    encrypt_aes(plaintext + unknown_string, consistent_random_key, :ECB)
  end
end

def make_encryption_oracle
  make_append_and_encrypt_with_consistent_key(UNKNOWN_STRING)
end

def test_discover_block_size
  Testing.assert_equals(BLOCKSIZE_BYTES, discover_block_size(make_encryption_oracle))
end

def test_detect_mode
  Testing.assert_equals(detect_mode(make_encryption_oracle), :ECB)
end

def test_discover_last_byte
  Testing.assert_equals(discover_last_byte(BLOCKSIZE_BYTES, make_encryption_oracle), "R")
end

def test
  test_discover_block_size
  test_detect_mode
  test_discover_last_byte
  # # encrypt_with_unknown_string = make_encrypt_with_unknown_string
  # decrypt_unknown_string(encrypt)
end

test
