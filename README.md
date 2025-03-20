# Person Matcher

This program identifies rows in a CSV file that may represent the same person based on a provided matching type.

## Requirements

- Ruby 2.5 or higher
- No external gems required (uses only Ruby standard library)

## Installation

No installation required. Simply clone or download the repository.

## Usage

ruby person_matcher.rb <input_file> <matching_type>


### Parameters

- `input_file`: Path to the CSV file to process
- `matching_type`: One of the following:
  - `same_email`: Matches records with the same email address
  - `same_phone`: Matches records with the same phone number
  - `same_email_or_phone`: Matches records with the same email address OR the same phone number

### Example

ruby person_matcher.rb sample_data.csv same_email


## Output

The program creates a new CSV file with the prefix "output_" added to the input filename. The output file contains all the original columns plus a new "person_id" column at the beginning, which identifies which person each row represents.

## Testing

Run the tests with:

ruby person_matcher_test.rb


## Design Decisions

1. **No External Dependencies**: The solution uses only Ruby's standard library to minimize setup requirements.

2. **Transitive Grouping**: For the "same_email_or_phone" matching type, the solution implements transitive grouping. For example, if record A and B share an email, and record B and C share a phone number, all three records (A, B, and C) will be assigned the same person ID.

3. **Error Handling**: The program validates inputs and provides clear error messages.

4. **Testing**: Comprehensive tests cover the main functionality and edge cases.