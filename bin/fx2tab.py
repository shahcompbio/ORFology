
#!/usr/bin/env python
import pandas as pd
import sys
# paths
fasta_path = sys.argv[1]
sample_name = sys.argv[2]
def fasta2df(uniprotfastapath, sample="swissprot"):
    """
    fasta to pandas dataframe
    """
    with open(uniprotfastapath, "r") as file:
        uniprotfasta = file.readlines()
    ### make it a dataframe ...
    seqs = []
    data = []
    for line in uniprotfasta:
        if line.startswith(">"):
            terms = line.split(" ")
            ID = terms[0]
            _, ID = ID.split(">")
            # extract protein info
            id_terms = ID.split("|")
            if len(id_terms) == 3:
                db, UniqueID, EntryName = id_terms
            else:
                db, UniqueID, EntryName = "", "", ""
            # extract gene name
            geneName = ""
            for term in terms:
                if term.startswith("GN="):
                    _, geneName = term.split("=")
                    break
            data.append({
                "db": db,
                "protein": ID.strip(),
                "accession_number": UniqueID,
                "entry_name": EntryName,
                "gene_name": geneName.strip(),
                "sample": sample,
                "header": line
            })
        else:
            seqs.append(line.strip())
    seqdat = pd.DataFrame(data)
    seqdat["seq"] = seqs
    seqdat.reset_index(drop=True, inplace=True)
    return seqdat
# convert fasta to dataframe
fasta2df(fasta_path, sample_name)
