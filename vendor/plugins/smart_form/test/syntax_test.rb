require 'test/unit'
class SyntaxTest < Test::Unit::TestCase 
  def test_syntax
    puts "[i] Checking syntax..."
    Dir["**/*.rb"].each do |script|
      print "\t#{script}..."
      assert_equal("Syntax OK\n", `ruby -cw #{script}`)
      puts " ok"
    end
  end
end

