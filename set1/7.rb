require 'openssl'
require 'base64'
require_relative('utils')

cipher = OpenSSL::Cipher::AES.new(128, :ECB)
cipher.decrypt
cipher.key = 'YELLOW SUBMARINE'

def read_file(filename)
  Base64.decode64(File.read(filename))
end

encrypted = read_file('7.txt')

puts cipher.update(encrypted) + cipher.final
