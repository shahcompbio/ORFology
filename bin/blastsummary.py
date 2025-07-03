#!/usr/bin/env python
import sys
import pandas as pd
import plotly.express as px
import numpy as np
# inputs
blast_res = sys.argv[1]  # path to blast results file
blast_fa = sys.argv[2]  # path to fasta that was blasted in tabular format
all_blast_out = sys.argv[3] # path to annotated blast results
# read in blast results and fasta
blast_df = pd.read_csv(blast_res, sep="\t")
fasta_df = pd.read_csv(blast_fa, sep="\t")
# add on results which had no blast match
fa_proteins = set(fasta_df["protein"])
query_proteins = set(blast_df["qseqid"])
noblastmatch = list(fa_proteins.difference(query_proteins))
# make a dataframe to append
data = []
for protein in noblastmatch:
    data.append({
        "qseqid": protein,
        "sseqid": "none",
        "evalue": 1,
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
    if row[protein_id].startswith("sp|"):
        categories.append("SwissProt")
    elif row[protein_name].startswith("ENST"):
        categories.append("Alt ORF/canonical transcript")
    elif row["gene_name"].startswith("ENSG"):
        categories.append("Alt splice transcript")
    elif not row["gene_name"].startswith("ENSG"):
        categories.append("Neogene")
    else:
        categories.append("Other")
category_df = pd.DataFrame(zip(list(fasta_df["protein"]), categories), columns=["qseqid", "category"])
category_df = category_df.drop_duplicates()
# merge dataframes
blast_df1 = pd.merge(all_blast_df, category_df, on="qseqid", how="left")
blast_df1["log10_bitscore"] = np.log10(blast_df1["bitscore"])
noncanon = blast_df1[blast_df1["category"]!="SwissProt"]
custom_palette = ["#CC3D24", "#F3C558", "#6DAE90", "#30B4CC", "#004F7A"]
fig = px.histogram(noncanon,
                   title = "Bitscore distribution from Diamond BLASTP",
                   x="log10_bitscore", 
                   color="category", marginal="rug", # can be `box`, `violin`
                   width=900,   # width in pixels
                   height=600,   # height in pixels
                   color_discrete_sequence=custom_palette[0:3],
                   hover_data=noncanon.columns)

# Add vertical line at log10(bitscore) = 2 (i.e., bitscore = 100)
fig.add_vline(
    x=2,
    line_width=2,
    line_dash="dash",
    line_color=custom_palette[3],
    annotation_text="S < 100 (weak alignment)",
    annotation_position="top right"
)
fig.update_traces(opacity=0.75)
fig.update_layout(barmode="overlay")
fig.write_html("bitscore_distribution.html")
# export blast results
blast_df1.to_csv(all_blast_out, sep="\t", index=False)