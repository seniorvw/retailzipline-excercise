require 'csv'

class PersonMatcher
  attr_reader :input_file, :matching_type

  def initialize(input_file, matching_type)
    @input_file = input_file
    @matching_type = matching_type
    validate_inputs
  end

  def process
    # Read the CSV file
    data = read_csv
    
    # Group records and assign person IDs
    grouped_data = group_records(data)
    
    # Create output directory if it doesn't exist
    Dir.mkdir('output') unless Dir.exist?('output')
    
    # Write the output file
    output_file = File.join('output', "output_#{File.basename(input_file)}")
    write_output(grouped_data, output_file)
    
    puts "Processing complete. Output written to: #{output_file}"
    output_file
  end

  private

  def validate_inputs
    unless File.exist?(input_file)
      raise ArgumentError, "Input file '#{input_file}' does not exist"
    end

    valid_types = ['same_email', 'same_phone', 'same_email_or_phone']
    unless valid_types.include?(matching_type)
      raise ArgumentError, "Invalid matching type: '#{matching_type}'. Valid types are: #{valid_types.join(', ')}"
    end
  end

  def read_csv
    CSV.read(input_file, headers: true)
  rescue CSV::MalformedCSVError => e
    raise "Error reading CSV file: #{e.message}"
  end

  def group_records(data)
    # Create a mapping of keys to person IDs
    key_to_person_id = {}
    next_person_id = 1
    
    # First pass: assign person IDs
    data.each do |row|
      # Generate keys based on matching type
      keys = generate_keys(row)
      
      # Check if any of the keys already have a person ID
      existing_person_ids = keys.map { |key| key_to_person_id[key] }.compact.uniq
      
      if existing_person_ids.empty?
        # Assign a new person ID
        person_id = next_person_id
        next_person_id += 1
      else
        # Use the first existing person ID
        person_id = existing_person_ids.first
        
        # If there are multiple existing person IDs, we need to merge them
        if existing_person_ids.size > 1
          # Update all keys with any of the existing IDs to use the first ID
          existing_person_ids[1..-1].each do |old_id|
            key_to_person_id.each do |k, v|
              key_to_person_id[k] = person_id if v == old_id
            end
          end
        end
      end
      
      # Assign person ID to all keys
      keys.each { |key| key_to_person_id[key] = person_id }
      
      # Directly assign person_id to the row
      row['person_id'] = person_id
    end
    
    data
  end

  def generate_keys(row)
    keys = []
    keys << row['email'] if matching_type.include?('email') && row['email']
    keys << row['phone'] if matching_type.include?('phone') && row['phone']
    keys
  end

  def write_output(data, output_file)
    CSV.open(output_file, 'w') do |csv|
      # Write header row with person_id first
      csv << ['person_id'] + data.headers
      
      # Write data rows
      data.each do |row|
        person_id = row.delete('person_id')
        csv << [person_id] + row.fields
      end
    end
  end
end