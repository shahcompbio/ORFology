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
meta_id = sys.argv[4]
# read in info table
info_df = pd.read_csv(info_path, sep="\t")
# drop any rows which are just coming from the SwissProt database (if it was included in the samplesheet)
info_df = info_df[(info_df["samples"] != "SwissProt") | (info_df["conditions"] != "SwissProt")]
# sort into categories
categories = []
multicategories = [] # in case the ORF fits into multiple categories
for _, row in info_df.iterrows():
    category = []
    # if there is a swissprot protein included, we categorize this ORF as SwissProt
    if row[protein_id].str.contains("sp|"):
        category.append("SwissProt")
    # else if there is an ensembl transcript included, we categorize as alt ORF
    # from canonical transcript
    elif row[protein_id].str.contains("|ENST"):
        category.append("Alt ORF from canonical transcript")
    # else if a splice isoform is included, we categorize as alt splice
    elif row["gene_name"].startswith("ENSG"):
        category.append("ORF from alt splice transcript")
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
plt.savefig(f"{meta_id}.counts_by_category_mqc.svg", dpi=300, bbox_inches="tight")
# output a table of counts
count_df = pd.DataFrame(counts["sequence"])
count_df.columns = ["count"]
count_df.to_csv(f"{meta_id}.counts_by_category.csv")
# also output annotated info table
info_df.to_csv(f"{meta_id}.annotated_info_table.tsv", sep="\t", index=False)
