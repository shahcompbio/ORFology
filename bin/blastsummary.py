#!/usr/bin/env python
import sys
import pandas as pd
import plotly.express as px
import numpy as np
# inputs
blast_res = sys.argv[1]  # path to blast results file
blast_fa = sys.argv[2]  # path to fasta that was blasted in tabular format
histogram_out = sys.argv[3]
all_blast_out = sys.argv[4] # path to annotated blast results
# read in blast results and fasta
blast_df = pd.read_csv(blast_res, sep="\t")
fasta_df = pd.read_csv(blast_fa, sep="\t")
# add on results which had no blast match
fa_proteins = set(fasta_df["protein"])
query_proteins = set(blast_df["qseqid"])
noblastmatch = list(fa_proteins.difference(query_proteins))
if len(noblastmatch) == 0:
    print("all proteins had blast matches")
    all_blast_df = blast_df
else:
    # make a dataframe to append
    data = []
    for protein in noblastmatch:
        data.append({
            "qseqid": protein,
            "sseqid": "none",
            "evalue": 10,
            "bitscore": 10
        })
    noblast_df = pd.DataFrame(data)
    noblast_df = noblast_df[~noblast_df["qseqid"].str.startswith("sp|")]
    print(len(noblast_df))
    all_blast_df = pd.concat([blast_df, noblast_df])
    all_blast_df = all_blast_df.reset_index(drop=True)
# sort into categories
# categorize for plotting ....
protein_id = "protein"
protein_name = "entry_name"
categories = []
for _, row in fasta_df.iterrows():
    if "sp|" in row[protein_id]:
        categories.append("SwissProt")
    elif "|ENST" in row[protein_id]:
        categories.append("Alt ORF from canonical transcript")
    elif row["gene_name"].startswith("ENSG"):
        categories.append("ORF from alt splice transcript")
    elif not row["gene_name"].startswith("ENSG") and row["gene_name"] != "unknown":
        categories.append("ORF from neogene")
    else:
        categories.append("Uncategorized")
category_df = pd.DataFrame(zip(list(fasta_df["protein"]), categories), columns=["qseqid", "category"])
category_df = category_df.drop_duplicates()
# merge dataframes
blast_df1 = pd.merge(all_blast_df, category_df, on="qseqid", how="left")
blast_df1["-log10_evalue"] = np.log10(blast_df1["evalue"])
# add a unique identifier column for merge with pgtools results
blast_df1["unique_identifier"] = blast_df1["qseqid"].str.split("|").str[1]
noncanon = blast_df1[blast_df1["category"]!="SwissProt"]
custom_palette = ["#CC3D24", "#F3C558", "#6DAE90", "#30B4CC", "#004F7A"]
fig = px.histogram(noncanon,
                   title = "Bitscore distribution from Diamond BLASTP",
                   x="-log10_evalue",
                   color="category", marginal="rug", # can be `box`, `violin`
                   width=900,   # width in pixels
                   height=600,   # height in pixels
                   color_discrete_sequence=custom_palette[0:3],
                   hover_data=noncanon.columns)

fig.update_traces(opacity=0.75)
fig.update_layout(barmode="overlay")
fig.write_html(histogram_out)
# export blast results
blast_df1.to_csv(all_blast_out, sep="\t", index=False)
