import polars as pl 

pl.read_csv("archivo.csv", separator=";",
            encoding="latin-1")