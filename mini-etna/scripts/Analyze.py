import os
import json

# Directory containing the files
directory = "test_outputs"
output_file = "output.txt"

def process_file(file_path):
    """Process a single file to compute the time difference."""
    try:
        with open(file_path, "r") as f:
            lines = f.readlines()
            if len(lines) != 2:
                raise ValueError(f"Unexpected format in {file_path}")

            # Extract timestamps from the lines
            start_time = float(lines[0].split()[0].strip("[]"))
            exit_time = float(lines[1].split()[0].strip("[]"))

            # Calculate the difference
            return exit_time - start_time
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")
        return None

def main():
    results = {}

    # Process each file in the directory
    for filename in os.listdir(directory):
        file_path = os.path.join(directory, filename)
        if os.path.isfile(file_path):
            time_diff = process_file(file_path)
            if time_diff is not None:
                results[filename] = time_diff

    # Write results to output file in JSON format
    with open(output_file, "w") as f:
        json.dump(results, f, indent=4)

    print(f"Results written to {output_file}")

if __name__ == "__main__":
    main()
