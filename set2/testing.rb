module Testing
  def self.assert_equals(actual, expected)
    if actual == expected
      puts '✅ passed'
    else
      puts "😢 Failed: got #{actual.inspect}\n\nExpected: #{expected.inspect}"
    end
  end
end
