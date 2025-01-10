import os
import shutil
import subprocess

def prepare_output_directory(directory):
    """
    Prepares the output directory by deleting its contents if it exists
    and recreating it as an empty directory.
    """
    if os.path.exists(directory):
        shutil.rmtree(directory)  # Remove the directory and its contents
    os.makedirs(directory)  # Create a fresh, empty directory

def run_tests():
    # Directory for storing output files
    output_directory = "test_outputs"

    # Prepare the output directory
    prepare_output_directory(output_directory)

    # List of strategies
    strategies = ["bespoke", "type", "staged"]

    # List of properties
    properties = [
        "prop_InsertValid",
        # "prop_DeleteValid",
        # "prop_UnionValid",
        "prop_InsertPost",
        # "prop_DeletePost",
        # "prop_UnionPost",
        # "prop_InsertModel",
        # "prop_DeleteModel",
        # "prop_UnionModel",
        "prop_InsertInsert",
        # "prop_InsertDelete",
        # "prop_InsertUnion",
        # "prop_DeleteInsert",
        # "prop_DeleteDelete",
        # "prop_DeleteUnion",
        # "prop_UnionDeleteInsert",
        # "prop_UnionUnionIdem",
        # "prop_UnionUnionAssoc",
    ]

    # Run tests for each property and strategy
    for property_name in properties:
        for strategy in strategies:
            output_file = os.path.join(output_directory, f"{property_name}_{strategy}.txt")
            command = ["dune", "exec", "BST", "--", "base", property_name, strategy, output_file]

            print(f"Running: {' '.join(command)}")

            try:
                result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

                if result.returncode == 0:
                    print(f"SUCCESS: {property_name} with strategy {strategy}")
                    print(f"Output written to {output_file}")
                else:
                    print(f"FAILURE: {property_name} with strategy {strategy}")
                    print(f"STDERR: {result.stderr}")
            except FileNotFoundError:
                print("Error: 'dune' command not found. Make sure it is installed and in your PATH.")
                return
            except Exception as e:
                print(f"An unexpected error occurred: {e}")
                return

if __name__ == "__main__":
    run_tests()
