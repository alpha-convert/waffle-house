import os
import shutil
import subprocess
import random

def prepare_output_directory(directory):
    """
    Prepares the output directory by deleting its contents if it exists
    and recreating it as an empty directory.
    """
    if os.path.exists(directory):
        shutil.rmtree(directory)  # Remove the directory and its contents
    os.makedirs(directory)  # Create a fresh, empty directory

def parse_time_and_seed(output_file):
    """
    Parses the output file to find the time difference and seed.
    Returns (time_diff, seed).
    """
    try:
        with open(output_file, "r") as f:
            lines = f.readlines()
            if len(lines) < 2:
                return None, None
            
            # Extract start time
            start_line = lines[0]
            start_time = float(start_line.split()[0].strip("[]"))
            
            # Extract exit time
            exit_line = lines[1]
            exit_time = float(exit_line.split()[0].strip("[]"))
            
            # Extract seed: find "start", get the token after it, and strip the trailing bracket
            tokens = start_line.split()
            seed_index = tokens.index("start") + 1
            seed = int(tokens[seed_index].strip("]"))
            
            return (exit_time - start_time, seed)
    except Exception as e:
        print(f"Error parsing file {output_file}: {e}")
        return None, None

def run_tests(num_repeats):
    # Directory for storing output files
    output_directory = "test_outputs"

    # Prepare the output directory
    prepare_output_directory(output_directory)

    # List of strategies
    strategies = ["type", "type_staged"]

    # Property to test
    property_name = "prop_DeleteDelete"

    # Results file
    results_file = "results.txt"

    with open(results_file, "w") as results:
        results.write("Difference (type - type_staged) with Seed\n")
        results.write("=========================================\n")

        # Run tests `num_repeats` times
        for repeat in range(num_repeats):
            print(f"Run {repeat + 1}/{num_repeats}")
            
            # Generate a single random seed for this repeat
            seed = random.randint(0, 1_000_000)

            execution_times = {}
            seeds = {}

            for strategy in strategies:
                output_file = os.path.join(output_directory, f"{property_name}_{strategy}_{repeat}.txt")
                command = ["dune", "exec", "RBT", "--", "base", property_name, strategy, output_file, str(seed)]

                print(f"Running: {' '.join(command)}")

                try:
                    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    if result.returncode == 0:
                        time_diff, parsed_seed = parse_time_and_seed(output_file)
                        if time_diff is not None and parsed_seed is not None:
                            execution_times[strategy] = time_diff
                            seeds[strategy] = parsed_seed
                    else:
                        print(f"FAILURE: {property_name} with strategy {strategy}")
                        print(f"STDERR: {result.stderr}")
                except FileNotFoundError:
                    print("Error: 'dune' command not found. Make sure it is installed and in your PATH.")
                    return
                except Exception as e:
                    print(f"An unexpected error occurred: {e}")
                    return

            # Ensure seeds are the same for both strategies
            if seeds.get("type") != seeds.get("type_staged"):
                raise ValueError(
                    f"Seed mismatch between strategies for run {repeat + 1}: "
                    f"type seed = {seeds.get('type')}, type_staged seed = {seeds.get('type_staged')}"
                )

            # Calculate the difference if both strategies have recorded times
            if "type" in execution_times and "type_staged" in execution_times:
                diff = execution_times["type"] - execution_times["type_staged"]
                results.write(f"Run {repeat + 1}: {diff:.6f} seconds (Seed: {seed})\n")
                print(f"Run {repeat + 1} difference: {diff:.6f} seconds (Seed: {seed})")
            else:
                results.write(f"Run {repeat + 1}: Incomplete results (Seed: {seed})\n")
                print(f"Run {repeat + 1}: Incomplete results (Seed: {seed})")

    print(f"Results written to {results_file}")

if __name__ == "__main__":
    num_repeats = 100
    run_tests(num_repeats)
