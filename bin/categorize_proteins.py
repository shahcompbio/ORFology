#!/usr/bin/env python
import pandas as pd
import marsilea as ma
import marsilea.plotter as mp
import matplotlib.pyplot as plt
import sys
# paths
info_path = sys.argv[1]
protein_id = sys.argv[2]
protein_name = sys.argv[3]
# read in info table
info_df = pd.read_csv(info_path, sep="\t")
# sort into categories
categories = []
for _, row in info_df.iterrows():
    if row[protein_id].startswith("sp"):
        categories.append("SwissProt")
    elif row[protein_name].startswith("ENST"):
        categories.append("Alt ORF from canonical transcript")
    elif row["gene_name"].startswith("ENSG"):
        categories.append("ORF from alt splice transcript")
    elif not row["gene_name"].startswith("ENSG"):
        categories.append("ORF from neogene")
    else:
        categories.append("Other")
info_df["category"] = categories
# count number of proteins in each category
info_df = info_df.drop_duplicates()
counts = info_df.groupby("category").count()
counts = counts.sort_values(by="sequence", ascending=False)
# plot counts
c = ma.ZeroWidth(2)
c.add_left(mp.Labels(counts.index), pad=0.1)
c.add_right(mp.Numbers(data=counts["sequence"], label="Counts", color="#009FBD"))
c.render()
plt.savefig("proteoform_counts_by_category.svg", dpi=300, bbox_inches="tight")
# output a table of counts
count_df = pd.DataFrame(counts["sequence"])
count_df.columns = ["count"]
count_df.to_csv("counts_by_category.csv")
# also output annotated info table
info_df.to_csv("annotated_info_table.tsv", sep="\t", index=False)