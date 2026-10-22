import pandas as pd

src = r"C:\path\to\train.csv"            # edit
out = r"C:\path\to\train_sample.csv"     # edit

first, rows = True, 0
for chunk in pd.read_csv(src, chunksize=2_000_000):
    s = chunk[chunk["Agencia_ID"] % 20 == 0]   # about 5% of depots, full history kept
    s.to_csv(out, mode="w" if first else "a", header=first, index=False)
    first, rows = False, rows + len(s)

print("Rows in sample:", rows)
