local arguments = { ... }

print("Number of command-line arguments received:", #arguments)

print("Dumping command line arguments (only those after the -- delimiter)...")
dump(arguments)

-- Alternatively, access the full arguments vector (argv in C) passed to the runtime
print("Dumping command line arguments (the full C arguments vector)...")
print("Full arguments count:", #arg)
dump(arg)
