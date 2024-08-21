# Load CSV Files --------------------------------- 
rm(list=ls(all=T))

tickers<-c('VIVO','VBIV','VOD','INFO','IEHC','IEP','QTS','QUMU','QMCO','MGRC','MAT','MANH','ROLL','RP','RLGT','SP500TR')

setwd("C:/Users/abdur/Downloads")

# Connect to PostgreSQL ---------------------------------------------------
require(RPostgres) # did you install this package?
require(DBI)
conn <- dbConnect(RPostgres::Postgres()
                  ,user="stockmarketproj"
                  ,password="read123"
                  ,host="localhost"
                  ,port=5432
                  ,dbname="stockmarketproject"
)

#custom calendar
qry<-"SELECT * FROM custom_calendar WHERE date BETWEEN '2015-12-31' AND '2021-12-31' ORDER by date"
ccal<-dbGetQuery(conn,qry)

#eod prices and indices
qry1="SELECT symbol,eod_indices.date,adj_close FROM eod_indices INNER JOIN custom_calendar ON eod_indices.date = custom_calendar.date WHERE eod_indices.date BETWEEN '2015-12-31' AND '2021-03-26'"
qry2="SELECT ticker,eod_quotes.date,adj_close FROM eod_quotes INNER JOIN custom_calendar ON eod_quotes.date = custom_calendar.date WHERE eod_quotes.date BETWEEN '2015-12-31' AND '2021-03-26'"
eod<-dbGetQuery(conn,paste(qry1,'UNION',qry2))
dbDisconnect(conn)
rm(conn)

#Explore
head(ccal)
tail(ccal)
nrow(ccal)

head(eod)
tail(eod)
nrow(eod)

head(eod[which(eod$symbol=='SP500TR'),])

eod_row<-data.frame(symbol='SP500TR',date=as.Date('2015-12-31'),adj_close=3821.60)
eod<-rbind(eod,eod_row)
tail(eod)

eod<-eod[which(eod$symbol %in% tickers),]

# Use Calendar --------------------------------------------------------

tdays<-ccal[which(ccal$trading==1),,drop=F]
head(tdays)
tail(tdays)
nrow(tdays)-1 #trading days between 2015 and 2020

# Completeness ----------------------------------------------------------
# Percentage of completeness
pct<-table(eod$symbol)/(nrow(tdays)-1)
selected_symbols_daily<-names(pct)[which(pct>=0.99)]
eod_complete<-eod[which(eod$symbol %in% selected_symbols_daily),,drop=F]

#check
head(eod_complete)
tail(eod_complete)
nrow(eod_complete)

# Transform (Pivot) -------------------------------------------------------

require(reshape2) #did you install this package?
eod_pvt<-dcast(eod_complete, date ~ symbol,value.var='adj_close',fun.aggregate = mean, fill=NULL)
#check
eod_pvt[1:10,1:5] #first 10 rows and first 5 columns 
tail(eod_pvt)
ncol(eod_pvt) # column count
nrow(eod_pvt)

# Merge with Calendar -----------------------------------------------------
eod_pvt_complete<-merge.data.frame(x=tdays[,'date',drop=F],y=eod_pvt,by='date',all.x=T)

#check
eod_pvt_complete[1:10,1:5] #first 10 rows and first 5 columns 
ncol(eod_pvt_complete)
nrow(eod_pvt_complete)

#use dates as row names and remove the date column
rownames(eod_pvt_complete)<-eod_pvt_complete$date
eod_pvt_complete$date<-NULL #remove the "date" column

#re-check
eod_pvt_complete[1:10,1:5] #first 10 rows and first 5 columns 
ncol(eod_pvt_complete)
nrow(eod_pvt_complete)

# Missing Data Imputation -----------------------------------------------------
# We can replace a few missing (NA or NaN) data items with previous data
# Let's say no more than 3 in a row...
require(zoo)
eod_pvt_complete<-na.locf(eod_pvt_complete,na.rm=F,fromLast=F,maxgap=3)
#re-check
eod_pvt_complete[1:10,1:5] #first 10 rows and first 5 columns 
ncol(eod_pvt_complete)
nrow(eod_pvt_complete)

# Calculating Returns -----------------------------------------------------
require(PerformanceAnalytics)
eod_ret<-CalculateReturns(eod_pvt_complete)

#check
eod_ret[1:10,1:3] #first 10 rows and first 3 columns 
ncol(eod_ret)
nrow(eod_ret)

#remove the first row
eod_ret<-tail(eod_ret,-1) #use tail with a negative value
#check
eod_ret[1:10,1:3] #first 10 rows and first 3 columns 
ncol(eod_ret)
nrow(eod_ret)

# Check for extreme returns -------------------------------------------
# There is colSums, colMeans but no colMax so we need to create it
colMax <- function(data) sapply(data, max, na.rm = TRUE)
# Apply it
max_daily_ret<-colMax(eod_ret)
max_daily_ret[1:10] #first 10 max returns
# And proceed just like we did with percentage (completeness)
selected_symbols_daily<-names(max_daily_ret)[which(max_daily_ret<=1.00)]
length(selected_symbols_daily)

#subset eod_ret
eod_ret<-eod_ret[,which(colnames(eod_ret) %in% selected_symbols_daily),drop=F]
#check
eod_ret[1:10,1:3] #first 10 rows and first 3 columns 
ncol(eod_ret)
nrow(eod_ret)

# Tabular Return Data Analytics -------------------------------------------

# We will select 'SP500TR' and 15 RANDOM TICKERS

# We need to convert data frames to xts (extensible time series)
#Ra<-as.xts(eod_ret[,c('VIVO','VTXPF','VNRFY','INFO','IEHC','IEP','QTS','QUMU','QMCO','MGRC','MAT','MANH','RSPI','RP','RLGT'),drop=F])


Ra<-as.xts(eod_ret[,setdiff(tickers,'SP500TR'),drop=F])
Rb<-as.xts(eod_ret[,'SP500TR',drop=F]) #benchmark

# MV Portfolio Optimization -----------------------------------------------

# withhold the last 61 trading days
Ra_training<-head(Ra,-61)
Rb_training<-head(Rb,-61)

# use the last 61 trading days for testing
Ra_testing<-tail(Ra,61)
Rb_testing<-tail(Rb,61)

# trick fix
Ra_testing<-head(Ra_testing,-3)
Rb_testing<-head(Rb_testing,-3)

#1 Cumulative return chart for Project Range #1 (2016-2020) for stock tickers selected by your team
acc_Ra_training<-Return.cumulative(Ra_training);acc_Ra_training
chart.CumReturns(Ra_training, legend.loc = 'topleft', main = 'Cumulative Returns for stock tickers')

#optimize the MV (Markowitz 1950s) portfolio weights based on training
table.AnnualizedReturns(Rb_training)
mar<-mean(Rb_training) #we need daily minimum acceptable return

require(PortfolioAnalytics)
require(ROI) # make sure to install it
require(ROI.plugin.quadprog)  # make sure to install it
pspec<-portfolio.spec(assets=colnames(Ra_training))
pspec<-add.objective(portfolio=pspec,type="risk",name='StdDev')
pspec<-add.constraint(portfolio=pspec,type="full_investment")
pspec<-add.constraint(portfolio=pspec,type="return",return_target=mar)

#optimize portfolio
opt_p<-optimize.portfolio(R=Ra_training,portfolio=pspec,optimize_method = 'ROI')

#2 Weights of your optimized portfolio and the sum of these weights based on Project Range #1
#extract weights (negative weights means shorting)
opt_w<-opt_p$weights; opt_w
sum_opt_w<-sum(opt_w); sum_opt_w

#apply weights to test returns
Rp<-Rb_testing # easier to apply the existing structure
#define new column that is the dot product of the two vectors
Rp$ptf<-Ra_testing %*% opt_w

#3 Cumulative return chart for your optimized portfolio and SP500TR index for Project Range #2
Return.cumulative(Rp)
chart.CumReturns(Rp, legend.loc = 'bottomright', main = 'Cumulative Returns for Optimized Portfolio and SP500TR')

#4 Annualized returns for your portfolio and SP500TR index for Project Range #2
table.AnnualizedReturns(Rp)


