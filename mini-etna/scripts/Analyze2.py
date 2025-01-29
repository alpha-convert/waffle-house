import os
def parse_file(filepath):
    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()
            if len(lines) < 2:
                raise ValueError(f"File {filepath} has fewer than 2 lines.")
            try:
                start_time = float(lines[0].split()[0].strip('[]'))
                end_time = float(lines[1].split()[0].strip('[]'))
                # Strip the trailing bracket and convert to int
                seed = int(lines[0].split()[-1].strip('[]'))
                elapsed_time = end_time - start_time
                return elapsed_time, seed
            except (IndexError, ValueError) as e:
                raise ValueError(f"File {filepath} contains invalid data: {e}")
    except FileNotFoundError:
        raise FileNotFoundError(f"File {filepath} not found.")
    except Exception as e:
        raise RuntimeError(f"Unexpected error while reading file {filepath}: {e}")

def main():
    folder = "/Users/lapwing/wf2/mini-etna/test_outputs"
    results = []
    errors = []
    n = 30  # Replace with the maximum number for your use case

    for i in range(n + 1):
        type_file = os.path.join(folder, f"prop_DeleteDelete_type_{i}.txt")
        type_staged_file = os.path.join(folder, f"prop_DeleteDelete_type_staged_{i}.txt")

        # Check if files exist
        if not os.path.exists(type_file):
            errors.append(f"Missing file: {type_file}")
            continue
        if not os.path.exists(type_staged_file):
            errors.append(f"Missing file: {type_staged_file}")
            continue

        try:
            type_data = parse_file(type_file)
            type_staged_data = parse_file(type_staged_file)

            # Check if seeds match
            if type_data[1] != type_staged_data[1]:
                errors.append(f"Seed mismatch for index {i}: {type_file} vs {type_staged_file}")
                continue

            type_time, seed = type_data
            type_staged_time, _ = type_staged_data
            results.append((i, type_time, type_staged_time, type_time - type_staged_time, seed))
        except Exception as e:
            errors.append(str(e))

    # Write results to output file
    output_file = "results_analyzed.txt"
    with open(output_file, "w") as out:
        out.write("Index\tType Time\tType Staged Time\tDifference\tSeed\n")
        for index, type_time, type_staged_time, diff, seed in results:
            out.write(f"{index}\t{type_time:.6f}\t{type_staged_time:.6f}\t{diff:.6f}\t{seed}\n")
    print(f"Results written to {output_file}")

    # Write errors to log file
    error_log = "error_log.txt"
    with open(error_log, "w") as log:
        for error in errors:
            log.write(f"{error}\n")
    print(f"Error log written to {error_log}")

if __name__ == "__main__":
    main()
