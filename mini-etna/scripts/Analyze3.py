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
                return end_time - start_time
            except (IndexError, ValueError) as e:
                raise ValueError(f"File {filepath} contains invalid data: {e}")
    except FileNotFoundError:
        raise FileNotFoundError(f"File {filepath} not found.")
    except Exception as e:
        raise RuntimeError(f"Unexpected error while reading file {filepath}: {e}")

def main():
    folder = "/Users/lapwing/wf2/mini-etna/test_outputs"
    type_times = []
    type_staged_times = []
    errors = []
    n = 100  # Replace with the maximum number for your use case

    for i in range(n + 1):
        type_file = os.path.join(folder, f"prop_DeleteDelete_type_{i}.txt")
        type_staged_file = os.path.join(folder, f"prop_DeleteDelete_type_staged_{i}.txt")

        if not os.path.exists(type_file):
            errors.append(f"Missing file: {type_file}")
            continue
        if not os.path.exists(type_staged_file):
            errors.append(f"Missing file: {type_staged_file}")
            continue

        try:
            type_time = parse_file(type_file)
            type_staged_time = parse_file(type_staged_file)

            type_times.append(type_time)
            type_staged_times.append(type_staged_time)
        except Exception as e:
            errors.append(str(e))

    print(f"type = {type_times}")
    print(f"type_staged = {type_staged_times}")

    # Log errors if any
    if errors:
        error_log = "error_log.txt"
        with open(error_log, "w") as log:
            for error in errors:
                log.write(f"{error}\n")
        print(f"Error log written to {error_log}")

if __name__ == "__main__":
    main()
