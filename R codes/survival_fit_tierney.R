################################################################################
## Title:       Survival curve fitting for opioid users using Tierney's sheet
## Programmer:  Mark Bounthavong
## Date:        12 February 2023
## Program:     R
## Version:     4.2.2.
## Updated:     NA
## Updated by:  NA
################################################################################


################################################################################
## Note: 02-12-2023
## I used the Tierney's excel sheet to calculate the number at risk
## Citation: Tierney JF, Stewart LA, Ghersi D, Burdett S, Sydes MR. Practical methods for incorporating summary time-to-event data into meta-analysis. Trials. 2007 Jun 7;8:16. doi: 10.1186/1745-6215-8-16. PMID: 17555582; PMCID: PMC1920534.
## Walley et al (2020) does not provide the number at risk
## Consequently, I have to use the KM data from Walley (2020) to input into
## Tierney's Excel sheet to estimate the number at risk
## Then, we use the code by Guyot et al to create the individual patient data (IPD)
## which is used to fit into the flexsurvreg command.
################################################################################



###############################################
## LOAD DATA and FUNCTION INPUTS
###############################################


### Clear work environment
rm(list=ls())


### Load libraries
library("MASS")
library("splines")
library("survival")
library("flexsurv")
library("readr")
library("knitr")


### Load RAW data from the KM digitized extraction (I have uploaded this on my GitHub page)
data1 <- "https://raw.githubusercontent.com/mbounthavong/CUA_Academic_detailing_and_naloxone/main/KM_tierney3.csv"


### Read CSV file
km.data <- read_csv(data1)
km.data <- data.frame(km.data)
km.data

#Read in survival times read by digizeit
digizeit <- km.data
t.S<-digizeit[,1]
S<-digizeit[,2]


#Algorithm to create a raw dataset from DigizeIt readings from a Kaplan-Meier curve
tot.events<-"NA" #tot.events = total no. of events reported. If not reported, then tot.events="NA"
arm.id<-1 #arm indicator



###############################################
### BEGIN GUYOT's FUNCTION
###############################################
#Read in published numbers at risk, n.risk, at time, t.risk, lower and upper
# indexes for time interval
t.risk<-seq(0, 13, by = 1)
lower<-purrr::map_dbl(t.risk, 
                      function(x) min(which(t.S >= x)))
upper<-purrr::map_dbl(c(t.risk[-1], Inf), 
                      function(x) max(which(t.S < x)))

### n.risk is manually inputted from Tierney's Excel calculation at timepoints:
### 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, and 12 months
n.risk<-c(9386, 9382, 9367, 9355, 9342, 9333, 9321, 9308, 9294, 9278, 9261, 9255, 9250)
  
  
n.int<-length(n.risk)
n.t<- upper[n.int]

### Initialise vectors
arm<-rep(arm.id,n.risk[1])
n.censor<- rep(0,(n.int-1))
n.hat<-rep(n.risk[1]+1,n.t)
cen<-rep(0,n.t)
d<-rep(0,n.t)
KM.hat<-rep(1,n.t)
last.i<-rep(1,n.int)
sumdL<-0
if (n.int > 1){
  #Time intervals 1,...,(n.int-1)
  for (i in 1:(n.int-1)){
    #First approximation of no. censored on interval i
    n.censor[i]<- round(n.risk[i]*S[lower[i+1]]/S[lower[i]]- n.risk[i+1])
    #Adjust tot. no. censored until n.hat = n.risk at start of interval (i+1)
    while((n.hat[lower[i+1]]>n.risk[i+1])||((n.hat[lower[i+1]]<n.risk[i+1])&&(n.censor[i]>0))){
      if (n.censor[i]<=0){
        cen[lower[i]:upper[i]]<-0
        n.censor[i]<-0
      }
      if (n.censor[i]>0){
        cen.t<-rep(0,n.censor[i])
        for (j in 1:n.censor[i]){
          cen.t[j]<- t.S[lower[i]] +
            j*(t.S[lower[(i+1)]]-t.S[lower[i]])/(n.censor[i]+1)
        }
        #Distribute censored observations evenly over time. Find no. censored on each time interval.
        cen[lower[i]:upper[i]]<-hist(cen.t,breaks=t.S[lower[i]:lower[(i+1)]],
                                     plot=F)$counts
      }
      #Find no. events and no. at risk on each interval to agree with K-M estimates read from curves
      n.hat[lower[i]]<-n.risk[i]
      last<-last.i[i]
      for (k in lower[i]:upper[i]){
        if (i==1 & k==lower[i]){
          d[k]<-0
          KM.hat[k]<-1
        }
        else {
          d[k]<-round(n.hat[k]*(1-(S[k]/KM.hat[last])))
          KM.hat[k]<-KM.hat[last]*(1-(d[k]/n.hat[k]))
        }
        n.hat[k+1]<-n.hat[k]-d[k]-cen[k]
        if (d[k] != 0) last<-k
      }
      n.censor[i]<- n.censor[i]+(n.hat[lower[i+1]]-n.risk[i+1])
    }
    if (n.hat[lower[i+1]]<n.risk[i+1]) n.risk[i+1]<-n.hat[lower[i+1]]
    last.i[(i+1)]<-last
  }
}

### Time interval n.int.
if (n.int>1){
  #Assume same censor rate as average over previous time intervals.
  n.censor[n.int]<- min(round(sum(n.censor[1:(n.int-1)])*(t.S[upper[n.int]]-
                                                            t.S[lower[n.int]])/(t.S[upper[(n.int-1)]]-t.S[lower[1]])), n.risk[n.int])
}
if (n.int==1){n.censor[n.int]<-0}
if (n.censor[n.int] <= 0){
  cen[lower[n.int]:(upper[n.int]-1)]<-0
  n.censor[n.int]<-0
}
if (n.censor[n.int]>0){
  cen.t<-rep(0,n.censor[n.int])
  for (j in 1:n.censor[n.int]){
    cen.t[j]<- t.S[lower[n.int]] +
      j*(t.S[upper[n.int]]-t.S[lower[n.int]])/(n.censor[n.int]+1)
  }
  cen[lower[n.int]:(upper[n.int]-1)]<-hist(cen.t,breaks=t.S[lower[n.int]:upper[n.int]],
                                           plot=F)$counts
}

### Find no. events and no. at risk on each interval to agree with K-M estimates read from curves
n.hat[lower[n.int]]<-n.risk[n.int]
last<-last.i[n.int]
for (k in lower[n.int]:upper[n.int]){
  if(KM.hat[last] !=0){
    d[k]<-round(n.hat[k]*(1-(S[k]/KM.hat[last])))} else {d[k]<-0}
  KM.hat[k]<-KM.hat[last]*(1-(d[k]/n.hat[k]))
  n.hat[k+1]<-n.hat[k]-d[k]-cen[k]
  #No. at risk cannot be negative
  if (n.hat[k+1] < 0) {
    n.hat[k+1]<-0
    cen[k]<-n.hat[k] - d[k]
  }
  if (d[k] != 0) last<-k
}

### If total no. of events reported, adjust no. censored so that total no. of events agrees.
if (tot.events != "NA"){
  if (n.int>1){
    sumdL<-sum(d[1:upper[(n.int-1)]])
    #If total no. events already too big, then set events and censoring = 0 on all further time intervals
    if (sumdL >= tot.events){
      d[lower[n.int]:upper[n.int]]<- rep(0,(upper[n.int]-lower[n.int]+1))
      cen[lower[n.int]:(upper[n.int]-1)]<- rep(0,(upper[n.int]-lower[n.int]))
      n.hat[(lower[n.int]+1):(upper[n.int]+1)]<- rep(n.risk[n.int],(upper[n.int]+1-lower[n.int]))
    }
  }
  
  ### Otherwise adjust no. censored to give correct total no. events
  if ((sumdL < tot.events)|| (n.int==1)){
    sumd<-sum(d[1:upper[n.int]])
    while ((sumd > tot.events)||((sumd< tot.events)&&(n.censor[n.int]>0))){
      n.censor[n.int]<- n.censor[n.int] + (sumd - tot.events)
      if (n.censor[n.int]<=0){
        cen[lower[n.int]:(upper[n.int]-1)]<-0
        n.censor[n.int]<-0
      }
      if (n.censor[n.int]>0){
        cen.t<-rep(0,n.censor[n.int])
        for (j in 1:n.censor[n.int]){
          cen.t[j]<- t.S[lower[n.int]] +
            j*(t.S[upper[n.int]]-t.S[lower[n.int]])/(n.censor[n.int]+1)
        }
        cen[lower[n.int]:(upper[n.int]-1)]<-hist(cen.t,breaks=t.S[lower[n.int]:upper[n.int]],
                                                 plot=F)$counts
      }
      n.hat[lower[n.int]]<-n.risk[n.int]
      last<-last.i[n.int]
      for (k in lower[n.int]:upper[n.int]){
        d[k]<-round(n.hat[k]*(1-(S[k]/KM.hat[last])))
        KM.hat[k]<-KM.hat[last]*(1-(d[k]/n.hat[k]))
        if (k != upper[n.int]){
          n.hat[k+1]<-n.hat[k]-d[k]-cen[k]
          #No. at risk cannot be negative
          if (n.hat[k+1] < 0) {
            n.hat[k+1]<-0
            cen[k]<-n.hat[k] - d[k]
          }
        }
        if (d[k] != 0) last<-k
      }
      sumd<- sum(d[1:upper[n.int]])
    }
  }
}

### Write.table(matrix(c(t.S,n.hat[1:n.t],d,cen),ncol=4,byrow=F),paste(path,KMdatafile,sep=""),sep="\t")

############################
### Now form IPD ###
############################
### Initialize vectors
t.IPD<-rep(t.S[n.t],n.risk[1])
event.IPD<-rep(0,n.risk[1])

### Write event time and event indicator (=1) for each event, as separate row in t.IPD and event.IPD
k=1
for (j in 1:n.t){
  if(d[j]!=0){
    t.IPD[k:(k+d[j]-1)]<- rep(t.S[j],d[j])
    event.IPD[k:(k+d[j]-1)]<- rep(1,d[j])
    k<-k+d[j]
  }
}

### Write censor time and event indicator (=0) for each censor, as separate row in t.IPD and event.IPD
for (j in 1:(n.t-1)){
  if(cen[j]!=0){
    t.IPD[k:(k+cen[j]-1)]<- rep(((t.S[j]+t.S[j+1])/2),cen[j])
    event.IPD[k:(k+cen[j]-1)]<- rep(0,cen[j])
    k<-k+cen[j]
  }
}


#Output Individual Patient Data (IPD)
IPD<-matrix(c(t.IPD,event.IPD,arm),ncol=3,byrow=F)
IPD


########################################
## Curve fitting
########################################

### Exponential curve fit
ex <- flexsurvreg(Surv(IPD[,1], IPD[,2])~1, dist="exponential")
ex


### Generalized gamma curve fit
gengamma <- flexsurvreg(Surv(IPD[,1], IPD[,2])~1, dist="gengamma")
gengamma


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
plot(ex, ylim = c(0.97, 1))           ### Exponential
plot(gengamma, ylim = c(0.97, 1))     ### Generalized gamma



### These codes are based onthe survreg command
### Weibull curve
weibull.model <- survreg(Surv(IPD[,1], IPD[,2])~1, dist="weibull")
weibull.model
extractAIC(weibull.model)


### Exponential curve
exponential.model <- survreg(Surv(IPD[,1], IPD[,2])~1, dist="exponential")
exponential.model
extractAIC(exponential.model)


### T model curve?
t.model <- survreg(Surv(IPD[,1], IPD[,2])~1, dist="t")
t.model
extractAIC(t.model)




