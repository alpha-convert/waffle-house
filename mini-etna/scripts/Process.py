import os
import json
import subprocess

# Configuration
directory = "test_outputs"
output_file = "output.txt"
average_output_file = "output2.txt"
repetitions = 100

# Script paths
script1 = "/Users/lapwing/wf2/mini-etna/scripts/Run.py"  # Replace with the actual filename of the first script
script2 = "/Users/lapwing/wf2/mini-etna/scripts/Analyze.py"  # Replace with the actual filename of the second script

def run_script(script_name):
    """Run the specified Python script."""
    subprocess.run(["python3", script_name], check=True)

def read_json_file(file_path):
    """Read JSON data from a file."""
    try:
        with open(file_path, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return {}

def write_json_file(file_path, data):
    """Write JSON data to a file."""
    try:
        with open(file_path, "w") as f:
            json.dump(data, f, indent=4)
    except Exception as e:
        print(f"Error writing to {file_path}: {e}")

def main():
    # Initialize cumulative results dictionary
    cumulative_results = {}

    for i in range(repetitions):
        print(f"Iteration {i + 1}/{repetitions}")

        # Run the first script
        run_script(script1)

        # Run the second script
        run_script(script2)

        # Read the output of the second script
        results = read_json_file(output_file)

        # Add results to the cumulative total
        for key, value in results.items():
            if key in cumulative_results:
                cumulative_results[key] += value
            else:
                cumulative_results[key] = value

    # Calculate the averages
    average_results = {key: value / repetitions for key, value in cumulative_results.items()}

    # Write the averages to the average output file
    write_json_file(average_output_file, average_results)

    print(f"Averages written to {average_output_file}")

if __name__ == "__main__":
    main()
