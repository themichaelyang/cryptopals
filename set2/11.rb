require_relative 'testing'
require 'openssl'

BLOCKSIZE = 128
BLOCKSIZE_BYTES = BLOCKSIZE / 8

def random_aes_key
  Random.bytes(BLOCKSIZE_BYTES)
end

def encryption_oracle(plaintext)
  mode = if Random.rand(2) == 1
           # Each block independently
           :ECB
         else
           # Chained block cipher
           :CBC
  end

  [encrypt_aes(random_padding + plaintext + random_padding, random_aes_key, mode), mode]
end

def random_padding
  length = Random.rand(5..9)

  Random.bytes(length)
end

# mode is one of :ECB or :CBC
def encrypt_aes(text, key, mode)
  cipher = OpenSSL::Cipher::AES.new(BLOCKSIZE, mode)
  # Need to call .encrypt first for some reason when using this library.
  # See: https://gist.github.com/tcaddy/c2282fb795581d560fb7a42ff1f5e8d6
  cipher.encrypt
  cipher.key = key
  cipher.update(text) + cipher.final
end

# Key idea from Jessica and Alec: we can choose the plaintext!
# With ECB, blocks that are repeated will be encrypted the same way.
def detect_mode(ciphertext)
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

def generate_plaintext
  'a' * BLOCKSIZE * 4
end

def test_detect_mode
  10.times.each do
    ciphertext, mode = encryption_oracle(generate_plaintext)
    Testing.assert_equals(detect_mode(ciphertext), mode)
  end
end

test_detect_mode
