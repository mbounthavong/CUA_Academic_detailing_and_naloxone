# Cost-utility analysis of academic detailing on naloxone distribution among opioid users in the United States
Cost-effectiveness of academic detailing on naloxone distribution

This respository contains data files for the CUA study on academic detailing's impact on naloxone distribution.

# Generate the parameters for the survival curve
### Step 1: Digitize the data from Walley and colleagues
We estimated the survival curve parameters by digitizing the Kaplan-Meier curves from a previous publication.

### Step 2: Saved data as CSV file
We then exported the data into a CSV file ([`KM_tierney3.csv`](https://raw.githubusercontent.com/mbounthavong/CUA_Academic_detailing_and_naloxone/main/KM_tierney3.csv)). 

### Step 3: Estimate the number at risk for the Kaplan-Meier table
The digitized KM curve provided survival estimates at months 1 to 12. 

```ruby
### Load Data
data1 <- "https://raw.githubusercontent.com/mbounthavong/CUA_Academic_detailing_and_naloxone/main/KM_tierney3.csv"
km.data <- read_csv(data1)
km.data <- data.frame(km.data)
````

We inputted these into an Excel file from Tierney and colleagues to esitmate the number at risk. I used the paper by Walley and colleagues to input into Tierney and colleagues Excel sheet to properly estimate the number at risk in the Kaplan-Meier table. 

<img src = 'https://github.com/mbounthavong/CUA_Academic_detailing_and_naloxone/blob/main/Figures/tierney excel.png' width = 40%>

### Step 4: Extrapolate survival to estimate the parameters for the survival functions
Then, we used [R code by Guyot and colleagues - `Guyot_survival_fit_code.R`](https://raw.githubusercontent.com/mbounthavong/CUA_Academic_detailing_and_naloxone/refs/heads/main/R%20codes/Guyot_survival_fit_code.R) to create individual patient data (IPD). 

We have to hard code this into the [R script - `Guyot_survival_fit_code.R`](https://raw.githubusercontent.com/mbounthavong/CUA_Academic_detailing_and_naloxone/refs/heads/main/R%20codes/Guyot_survival_fit_code.R):

```ruby
### n.risk is manually inputted from Tierney's Excel calculation at timepoints:
### 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, and 12 months
n.risk<-c(9386, 9382, 9367, 9355, 9342, 9333, 9321, 9308, 9294, 9278, 9261, 9255, 9250)
```

Next, we used the IPD for survival curve fitting using the `flexsurvreg` command to estimate the parameters for the survival function. 

Ultimately, we opted to use the Weibull, which had the best fit compared to the other survival functions. We compared fit using AIC. 

```ruby
### Weibull curve fit
## https://stats.stackexchange.com/questions/259625/meaning-of-weibull-scale-and-shape-from-flexsurvreg
we <- flexsurvreg(Surv(IPD[,1], IPD[,2])~1, dist="weibull")
we$coefficients   ### Use the negative "shape" (it is presented as a (+), but use the (-) value
exp(we$coefficients)
lambda <- we$res[2]
gamma <- we$res[1]
lambda
gamma
we


### Plot KM curve and the other survival fits
plot(survfit(Surv(IPD[,1], IPD[,2])~1), ylim = c(0.97, 1))
plot(we, ylim = c(0.97, 1))           ### Weibull
```
<img src = 'https://github.com/mbounthavong/CUA_Academic_detailing_and_naloxone/blob/main/Figures/weibull.png' width = 50%>

Here is a comparison of survival curve extrapolations for the various curve fitting models. 

<img src = 'https://github.com/mbounthavong/CUA_Academic_detailing_and_naloxone/blob/main/Figures/Figure_survival.png' width = 60%>

# References and Sources
Data for the Kaplan-Meier curve was based on a paper by Walley and colleagues.
(citation: [Walley AY, Lodi S, Li Y, Bernson D, Babakhanlou-Chase H, Land T, Larochelle MR. Association between mortality rates and medication and residential treatment after in-patient medically managed opioid withdrawal: a cohort analysis. Addiction. 2020 Aug;115(8):1496-1508. doi: 10.1111/add.14964. Epub 2020 Feb 25. PMID: 32096908; PMCID: PMC7854020.](https://pubmed.ncbi.nlm.nih.gov/32096908/))

We used Tierney and colleagues paper to estimate the number at risk for the Kaplan-Meier table. 
(citation: [Tierney JF, Stewart LA, Ghersi D, Burdett S, Sydes MR. Practical methods for incorporating summary time-to-event data into meta-analysis. Trials. 2007 Jun 7;8:16. doi: 10.1186/1745-6215-8-16. PMID: 17555582; PMCID: PMC1920534.](https://pubmed.ncbi.nlm.nih.gov/17555582/))

We used Guyot and colleagues excellent R code to estimate the parameters for the survival functions. 
(citation: [Guyot P, Ades AE, Ouwens MJ, Welton NJ. Enhanced secondary analysis of survival data: reconstructing the data from published Kaplan-Meier survival curves. BMC Med Res Methodol. 2012 Feb 1;12:9. doi: 10.1186/1471-2288-12-9. PMID: 22297116; PMCID: PMC3313891.](https://pubmed.ncbi.nlm.nih.gov/22297116/)

We used the methods by Hoyle and Henley, which was provided as a publication
(citation: [Hoyle MW, Henley W. Improved curve fits to summary survival data: application to economic evaluation of health technologies. BMC Med Res Methodol. 2011 Oct 10;11:139. doi: 10.1186/1471-2288-11-139. PMID: 21985358; PMCID: PMC3198983.](https://pubmed.ncbi.nlm.nih.gov/21985358/))


