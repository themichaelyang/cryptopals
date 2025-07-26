module Testing
  def self.assert_equals(actual, expected)
    if actual == expected
      puts "✅ passed"
    else
      puts "😢 failed: got #{actual.inspect}, expected #{expected.inspect}"
    end
  end
end
