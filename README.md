# CUA_Academic_detailing_and_naloxone
Cost-effectiveness of academic detailing on naloxone distribution

This respository contains data files for the CUA study on academic detailing's impact on naloxone distribution.

# Generate the parameters for the survival curve
We estimated the survival curve parameters by digitizing the Kaplan-Meier curves from a previous publication.

We then exported the data into a CSV file (KM_tierney3.csv). 

We used the Excel file from Tierney and colleagues to esitmate the number at risk. I used the paper by Walley and colleagues to input into Tierney and colleagues Excel sheet to properly estimate the number at risk in the Kaplan-Meier table. 

Then, we used the R code by Guyot and collagues to fit into the `flexsurvreg` command to estimate the parameters for the survival function. 



We used the methods by Hoyle and Henley, which was provided as a publication
(citation: [Hoyle MW, Henley W. Improved curve fits to summary survival data: application to economic evaluation of health technologies. BMC Med Res Methodol. 2011 Oct 10;11:139. doi: 10.1186/1471-2288-11-139. PMID: 21985358; PMCID: PMC3198983.](https://pubmed.ncbi.nlm.nih.gov/21985358/))

We also used Tierney and colleagues paper to estimate the number at risk for the Kaplan-Meier table. 
(citation: [Tierney JF, Stewart LA, Ghersi D, Burdett S, Sydes MR. Practical methods for incorporating summary time-to-event data into meta-analysis. Trials. 2007 Jun 7;8:16. doi: 10.1186/1745-6215-8-16. PMID: 17555582; PMCID: PMC1920534.](https://pubmed.ncbi.nlm.nih.gov/17555582/))

We used Guyot and colleagues excellent R code to estimate the parameters for the survival functions. 
(citation: []()
