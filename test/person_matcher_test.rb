require 'minitest/autorun'
require_relative '../lib/person_matcher'
require 'csv'
require 'tempfile'
require 'fileutils'

class PersonMatcherTest < Minitest::Test
  def setup
    # Create temporary test files
    @test_file = Tempfile.new(['test', '.csv'])
    @test_file.write(<<~CSV)
      email,phone,name,address
      john@example.com,555-1234,John Doe,123 Main St
      jane@example.com,555-5678,Jane Smith,456 Oak Ave
      john@example.com,555-8765,John D,789 Pine Rd
      bob@example.com,555-5678,Bob Johnson,101 Elm St
      sarah@example.com,555-4321,Sarah Lee,202 Maple Dr
    CSV
    @test_file.close
    
    # Create output directory if it doesn't exist
    FileUtils.mkdir_p('output') unless Dir.exist?('output')
  end

  def teardown
    @test_file.unlink
    # Clean up output files
    Dir.glob("output/output_*").each do |file|
      File.delete(file) if File.basename(file).include?("test")
    end
  end

  def test_same_email_matching
    matcher = PersonMatcher.new(@test_file.path, 'same_email')
    output_file = matcher.process
    
    results = CSV.read(output_file, headers: true)
    
    # Check that rows with the same email have the same person_id
    assert_equal results[0]['person_id'], results[2]['person_id']
    refute_equal results[0]['person_id'], results[1]['person_id']
    refute_equal results[1]['person_id'], results[3]['person_id']
  end

  def test_same_phone_matching
    matcher = PersonMatcher.new(@test_file.path, 'same_phone')
    output_file = matcher.process
    
    results = CSV.read(output_file, headers: true)
    
    # Check that rows with the same phone have the same person_id
    assert_equal results[1]['person_id'], results[3]['person_id']
    refute_equal results[0]['person_id'], results[1]['person_id']
    refute_equal results[0]['person_id'], results[2]['person_id']
  end

  def test_same_email_or_phone_matching
    matcher = PersonMatcher.new(@test_file.path, 'same_email_or_phone')
    output_file = matcher.process
    
    results = CSV.read(output_file, headers: true)
    
    # Check that rows with the same email OR phone have the same person_id
    assert_equal results[0]['person_id'], results[2]['person_id']  # Same email
    assert_equal results[1]['person_id'], results[3]['person_id']  # Same phone
    refute_equal results[0]['person_id'], results[1]['person_id']
    refute_equal results[0]['person_id'], results[4]['person_id']
  end

  def test_transitive_matching
    # Create a test file with transitive relationships
    test_file = Tempfile.new(['test_transitive', '.csv'])
    test_file.write(<<~CSV)
      email,phone,name,address
      a@email.com,111,Person A1,Address A1
      b@email.com,111,Person B,Address B
      a@email.com,222,Person A2,Address A2
    CSV
    test_file.close
    
    begin
      matcher = PersonMatcher.new(test_file.path, 'same_email_or_phone')
      output_file = matcher.process
      
      results = CSV.read(output_file, headers: true)
      
      # All three records should have the same person_id
      assert_equal results[0]['person_id'], results[1]['person_id']
      assert_equal results[1]['person_id'], results[2]['person_id']
      assert_equal results[0]['person_id'], results[2]['person_id']
    ensure
      test_file.unlink
      File.delete(output_file) if File.exist?(output_file)
    end
  end

  def test_invalid_matching_type
    assert_raises(ArgumentError) do
      PersonMatcher.new(@test_file.path, 'invalid_type')
    end
  end

  def test_nonexistent_file
    assert_raises(ArgumentError) do
      PersonMatcher.new('nonexistent_file.csv', 'same_email')
    end
  end
end