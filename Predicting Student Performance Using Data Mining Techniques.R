rm( list=ls() ) 
gc()

# read the data
setwd("C:/Users/Riya Murdia/Downloads")

# 'read.csv' reads in csv file
dat = read.csv('FinalData1.csv', head=T, stringsAsFactors=F, na.strings='')

dim(dat) # dimensions of the data: # of rows, # of columns
str(dat)

# checking missing values
matrix.na = is.na(dat)
pmiss = colMeans(matrix.na) # proportion of missing for each column
nmiss = rowMeans(matrix.na) # proportion of missing for each row
plot(pmiss) # a few columns with high proportion of missing. we want to exclude them.

library(Amelia)
missmap(dat) #No missing values in the data

## Encoding Categorical variables
dat$school = factor(dat$school, level = c("GP", "MS"), labels = c(1,0) )
dat$sex = factor(dat$sex, level = c("M", "F"), labels = c(1,0) )
dat$address = factor(dat$address, level = c("U", "R"), labels = c(1,0) )
dat$famsize = factor(dat$famsize, level = c("GT3", "LE3"), labels = c(1,0) )
dat$Pstatus = factor(dat$Pstatus, level = c("T", "A"), labels = c(1,0) )
dat$Mjob = factor(dat$Mjob, level = c("at_home", "health", "teacher", "services", "other"), labels = c(0,1,2,3,4) )
dat$Fjob = factor(dat$Fjob, level = c("at_home", "health", "teacher", "services", "other"), labels = c(0,1,2,3,4) )
dat$reason = factor(dat$reason, level = c("home", "reputation", "course", "other"), labels = c(0,1,2,3) )
dat$guardian = factor(dat$guardian, level = c("mother", "father", "other"), labels = c(0,1,2) )
dat$schoolsup = factor(dat$schoolsup, level = c("yes", "no"), labels = c(1,0) )
dat$famsup = factor(dat$famsup, level = c("yes", "no"), labels = c(1,0) )
dat$paid = factor(dat$paid, level = c("yes", "no"), labels = c(1,0) )
dat$activities = factor(dat$activities, level = c("yes", "no"), labels = c(1,0) )
dat$nursery = factor(dat$nursery, level = c("yes", "no"), labels = c(1,0) )
dat$higher = factor(dat$higher, level = c("yes", "no"), labels = c(1,0) )
dat$internet = factor(dat$internet, level = c("yes", "no"), labels = c(1,0) )
dat$romantic = factor(dat$romantic, level = c("yes", "no"), labels = c(1,0) )


#Converting the values of G1, G2 and G3 to 1 & 0 where any value >= 12 (60%) is specified as 1 or pass and any value <12 is specified as 0 or fail
dat$G1 <- ifelse(dat$G1 >= 12, 1, 0)
dat$G2 <- ifelse(dat$G2 >= 12, 1, 0)
dat$G3 <- ifelse(dat$G3 >= 12, 1, 0)
dat


#check the distribution of continuous variables ##remove the outliers


par(mfrow=c(1, 2)) 
hist(dat$Medu) 
boxplot(dat$Medu) 

par(mfrow=c(1, 2)) 
hist(dat$Fedu) 
boxplot(dat$Fedu)

par(mfrow=c(1, 2)) 
hist(dat$traveltime) 
boxplot(dat$traveltime)


par(mfrow=c(1, 2)) 
hist(dat$studytime) 
boxplot(dat$studytime) 


par(mfrow=c(1, 2)) 
hist(dat$goout) 
boxplot(dat$goout) 

par(mfrow=c(1, 2)) 
hist(dat$Dalc) 
boxplot(dat$Dalc)


par(mfrow=c(1, 2)) 
hist(dat$Walc) 
boxplot(dat$Walc) 

par(mfrow=c(1, 2)) 
hist(dat$famrel) 
boxplot(dat$famrel)
values_to_remove <- c(1,2)
dat <- dat[!dat$famrel %in% values_to_remove, ]
boxplot(dat$famrel )

par(mfrow=c(1, 2)) 
hist(dat$freetime) 
boxplot(dat$freetime)
values_to_remove <- c(1)
dat <- dat[!dat$freetime %in% values_to_remove, ]
boxplot(dat$freetime )


library(fastDummies) # to make categorical variables to binary 
dummy_variables = dummy_columns(dat, select_columns = c('Medu', 'Fedu','reason', 'guardian'), 
                                remove_most_frequent_dummy = T,
                                remove_selected_columns = T)

#Correlation check

dat_numeric1 <- dat[sapply(dat, is.numeric)]
dat_numeric = subset(dat_numeric1, select = -c(G1, G2))


# Identify variables with zero variance
zero_variance_vars <- names(dat_numeric)[apply(dat_numeric, 2, sd) == 0]

# Remove variables with zero variance
dat_numeric <- dat_numeric[, !names(dat_numeric) %in% zero_variance_vars]

# Calculate the correlation matrix using the numeric part of the dataframe
correlation_matrix <- cor(dat_numeric, method = "pearson")

# Print the correlation matrix
print(correlation_matrix)

# To identify any pairs with a high degree of collinearity, you can find pairs with correlation > 0.8 or < -0.8.
highly_correlated_pairs <- which(abs(correlation_matrix) > 0.8 & correlation_matrix != 1, arr.ind = TRUE)
print(highly_correlated_pairs)

library(corrplot)
corrplot(correlation_matrix, method = "number", number.cex = 0.7)


#correlation between G1, G2, G3

dat1 = subset(dat, select = c(G1, G2, G3))

install.packages("car")
library(car)
model <- lm(G3 ~ G1 + G2, data = dat1)

vif_values <- vif(model)
print(vif_values)
table(dat$school)
table(dat$sex)
table(dat$address)
table(dat$famsize)
table(dat$Pstatus) 
table(dat$Mjob)
table(dat$Fjob) 
table(dat$reason) 
table(dat$guardian) 
table(dat$schoolsup) 
table(dat$famsup) 
table(dat$paid) 
table(dat$activities)
table(dat$nursery) 
table(dat$higher) 
table(dat$internet) 
table(dat$romantic)
table(dat$G1)
table(dat$G2)
table(dat$G3)
# check the frequency table of categorical variables and data is balanced or not




head(dat)
class(dat)

# Logistic Regression (forward)

d1 = subset(dummy_variables)


# without G1, G2 use this command first
#d1 = subset(dat, select = -c(G2, G1))


set.seed(1)
id.train <- sample(1:nrow(d1), nrow(d1)*0.6)
id.test <- setdiff(1:nrow(d1), id.train)
d1.train <- d1[id.train, ]
d1.test <- d1[id.test, ]

# Build the minimal and maximal models
min.model <- glm(G3 ~ 1, data = d1.train, family = 'binomial')
max.model <- glm(G3 ~ ., data = d1.train, family = 'binomial')
max.formula <- formula(max.model)


# Perform stepwise model selection starting from the minimal model
library(MASS)  # Load MASS package for stepAIC if not already loaded
obj <- stepAIC(min.model, direction = 'forward', scope = list(lower = formula(min.model), upper = max.formula))

# Summarize the final model
summary(obj)

# Predict on the test dataset
yhat <- predict(obj, newdata = d1.test, type = 'response')
hist(yhat)

# Function to convert probabilities to binary outcome based on cutoff
dichotomize <- function(yhat, cutoff = 0.5) {
  ifelse(yhat > cutoff, 1, 0)
}

# Applying the cutoff  (as per your example)
yhat.class <- dichotomize(yhat, 0.5)
err = mean(yhat.class != d1.test$G3) # misclassification error rate
err # Misclassification error rate


# Create a confusion matrix
table(yhat.class, d1.test$G3)

# Calculate sensitivity and specificity
sen <- function(ytrue, yhat) {
  ind.true1 <- which(ytrue == 1)
  mean(yhat[ind.true1] == 1)
}

spe <- function(ytrue, yhat) {
  ind.true0 <- which(ytrue == 0)
  mean(yhat[ind.true0] == 0)
}

sensitivity <- sen(d1.test$G3, yhat.class)
specificity <- spe(d1.test$G3, yhat.class)

# Print sensitivity and specificity
print(paste("Sensitivity: ", sensitivity))
print(paste("Specificity: ", specificity))

## backward selection

set.seed(1)
id.train <- sample(1:nrow(d1), nrow(dat)*0.6)
id.test <- setdiff(1:nrow(d1), id.train)
d1.train <- d1[id.train, ]
d1.test <- d1[id.test, ]

# Build the minimal and maximal models
min.model <- glm(G3 ~ 1, data = d1.train, family = 'binomial')
max.model <- glm(G3 ~ ., data = d1.train, family = 'binomial')
max.formula <- formula(max.model)


# Perform stepwise model selection starting from the minimal model
library(MASS)  # Load MASS package for stepAIC if not already loaded
obj1 <- stepAIC(max.model, direction = 'backward', scope = list(lower = formula(min.model), upper = max.formula))


# Summarize the final model
summary(obj1)

# Predict on the test dataset
yhat1 <- predict(obj1, newdata = d1.test, type = 'response')
hist(yhat1)

# Function to convert probabilities to binary outcome based on cutoff
dichotomize <- function(yhat1, cutoff = 0.3) {
  ifelse(yhat1 > cutoff, 1, 0)
}

# Applying the cutoff (as per your example)
yhat1.class <- dichotomize(yhat1, 0.3)
err = mean(yhat1.class != d1.test$G3) # misclassification error rate
err # Misclassification error rate


# Create a confusion matrix
table(yhat1.class, d1.test$G3)

# Calculate sensitivity and specificity

sen <- function(ytrue, yhat1) {
  ind.true1 <- which(ytrue == 1)
  mean(yhat1[ind.true1] == 1)
}

spe <- function(ytrue, yhat1) {
  ind.true0 <- which(ytrue == 0)
  mean(yhat1[ind.true0] == 0)
}

sensitivity <- sen(d1.test$G3, yhat1.class)
specificity <- spe(d1.test$G3, yhat1.class)

# Print sensitivity and specificity
print(paste("Sensitivity: ", sensitivity))
print(paste("Specificity: ", specificity))

#stepwise

set.seed(1)
id.train <- sample(1:nrow(d1), nrow(dat)*0.6)
id.test <- setdiff(1:nrow(d1), id.train)
d1.train <- d1[id.train, ]
d1.test <- d1[id.test, ]

# Build the minimal and maximal models
min.model <- glm(G3 ~ 1, data = d1.train, family = 'binomial')
max.model <- glm(G3 ~ ., data = d1.train, family = 'binomial')
max.formula <- formula(max.model)


# Perform stepwise model selection starting from the minimal model
library(MASS)  # Load MASS package for stepAIC if not already loaded
obj3 <- stepAIC(min.model, direction = 'both', scope = list(lower = formula(min.model), upper = max.formula))


# Summarize the final model
summary(obj3)

# Predict on the test dataset
yhat2 <- predict(obj3, newdata = d1.test, type = 'response')
hist(yhat2)

# Function to convert probabilities to binary outcome based on cutoff
dichotomize <- function(yhat2, cutoff = 0.3) {
  ifelse(yhat2 > cutoff, 1, 0)
}

# Applying the cutoff (as per your example)
yhat2.class <- dichotomize(yhat2, 0.3)
err = mean(yhat2.class != d1.test$G3) # misclassification error rate
err # Misclassification error rate


# Create a confusion matrix
table(yhat2.class, d1.test$G3)

# Calculate sensitivity and specificity
sen <- function(ytrue, yhat2) {
  ind.true1 <- which(ytrue == 1)
  mean(yhat2[ind.true1] == 1)
}


spe <- function(ytrue, yhat2) {
  ind.true0 <- which(ytrue == 0)
  mean(yhat2[ind.true0] == 0)
}


sensitivity <- sen(d1.test$G3, yhat2.class)
specificity <- spe(d1.test$G3, yhat2.class)

# Print sensitivity and specificity
print(paste("Sensitivity: ", sensitivity))
print(paste("Specificity: ", specificity))
##################################### KNN #####################################

get.prob = function(x) {
  prob = attr(x, 'prob')
  ind = which(x == 0)
  prob[ind] = 1 - prob[ind]
  return(prob)
}

knn.bestK = function(train, test, y.train, y.test, k.grid = 1:20, ct = .5) {
  # browser()
  fun.tmp = function(x) {
    y.tmp = knn(train, test, y.train, k = x, prob=T) # run knn for each k in k.grid
    prob = get.prob(y.tmp)
    y.hat = as.numeric( prob > ct )
    return( sum(y.hat != as.numeric(y.test)) )
  }
  ## create a temporary function (fun.tmp) that we want to apply to each value in k.grid
  error = unlist(lapply(k.grid, fun.tmp))
  names(error) = paste0('k=', k.grid)
  ## it will return a list so I need to unlist it to make it to be a vector
  out = list(k.optimal = k.grid[which.min(error)], 
             error.min = min(error)/length(y.test),
             error.all = error/length(y.test))
  return(out)
}

sen_knn = function(ytest, ypred) {
  ind1 = which(ytest == 1)
  mean(ytest[ind1] == ypred[ind1])
} # Sensitivity 

spe_knn = function(ytest, ypred) {
  ind1 = which(ytest == 0)
  mean(ytest[ind1] == ypred[ind1])
} # Specificity 

fpr_knn = function(ytest, ypred) {
  ind1 = which(ytest == 0)
  mean(ytest[ind1] != ypred[ind1])
} # false positive rate 

fnr_knn = function(ytest, ypred) {
  ind1 = which(ytest == 1)
  mean(ytest[ind1] != ypred[ind1])
} # false negative rate 

performance = function(ytest, ypred) {
  measures = c(mean(ytest == ypred),
               sen_knn(ytest, ypred),
               spe_knn(ytest, ypred),
               fpr_knn(ytest, ypred),
               fnr_knn(ytest, ypred))
  names(measures) = c('Accuracy', 'Sensitivity', 'Specificity', 'FPR', 'FNR')
  return(measures)
} # To get performance(accuracy, sen , spe , fnr ,fpr )


#______________for all variables(considering G1 and G2 as categorical)_________

library(fastDummies) # to make categorical variables to binary 
dummy_variables_knn = dummy_columns(dat, select_columns = c('Medu', 'Fedu','reason', 'guardian'), 
                                remove_most_frequent_dummy = T,
                                remove_selected_columns = T)
set.seed(1)
n.train = floor( nrow(dummy_variables_knn)*0.60)
ind.train = sample(1:nrow(dummy_variables_knn), n.train)
ind.test = setdiff(1:nrow(dummy_variables_knn), ind.train)

require(class)
Xtrain = dummy_variables_knn[ind.train,-which(names(dummy_variables_knn)=="G3")]
Xtest = dummy_variables_knn[ind.test,-which(names(dummy_variables_knn)=="G3")]
ytrain = dummy_variables_knn[ind.train,which(names(dummy_variables_knn)=="G3")]
ytest = dummy_variables_knn[ind.test,which(names(dummy_variables_knn)=="G3")]

# Finding Best K 
obj1_knn = knn.bestK(Xtrain, Xtest, ytrain, ytest, seq(1, nrow(dummy_variables_knn), 1), .5)
obj1_knn

## run with the best k
ypred1 = knn(Xtrain, Xtest, ytrain, k=obj1_knn$k.optimal, prob=T)
table(ytest, ypred1)
# evaluate performance 
performance(ytest, ypred1)

#______________Removing G1 and G2 because they are dominating the result ______________________

dominating_variables <- c("G1","G2")
dat_dv <- dat[,!names(dat) %in% dominating_variables]
library(fastDummies) # to make categorical variables to binary 
dummy_variables1 = dummy_columns(dat_dv, select_columns = c('Medu', 'Fedu','reason', 'guardian'), 
                                 remove_most_frequent_dummy = T,
                                 remove_selected_columns = T)
set.seed(1)
n.train = floor( nrow(dummy_variables1)*0.60)
ind.train = sample(1:nrow(dummy_variables1), n.train)
ind.test = setdiff(1:nrow(dummy_variables1), ind.train)

require(class)
Xtrain_dv = dummy_variables1[ind.train,-which(names(dummy_variables1)=="G3")]
Xtest_dv = dummy_variables1[ind.test,-which(names(dummy_variables1)=="G3")]
ytrain_dv = dummy_variables1[ind.train,which(names(dummy_variables1)=="G3")]
ytest_dv = dummy_variables1[ind.test,which(names(dummy_variables1)=="G3")]

# Finding Best K 
obj2_knn = knn.bestK(Xtrain_dv, Xtest_dv, ytrain_dv, ytest_dv, seq(1, nrow(dummy_variables1), 1), .5)
obj2_knn

## rerun with the best k
ypred2 = knn(Xtrain_dv, Xtest_dv, ytrain_dv, k=obj2_knn$k.optimal, prob=T)
table(ytest_dv, ypred2)
# evaluate performance 
performance(ytest_dv, ypred2)

#______________With Significant Variables ______________________


significant_variables <- c("studytime", "failures", "reason", "higher", "school", "traveltime", "schoolsup", "G1", "G2", "G3") # add G3
dat_sv <- dat[,names(dat) %in% significant_variables]
dummy_variables_sv = dummy_columns(dat_sv, select_columns = c('reason','higher','school', 'schoolsup'), 
                                 remove_most_frequent_dummy = T,
                                 remove_selected_columns = T)
set.seed(1)
n.train = floor( nrow(dummy_variables_sv)*0.60)
ind.train = sample(1:nrow(dummy_variables_sv), n.train)
ind.test = setdiff(1:nrow(dummy_variables_sv), ind.train)

require(class)
Xtrain = dummy_variables_sv[ind.train,-which(names(dummy_variables_sv)=="G3")]
Xtest = dummy_variables_sv[ind.test,-which(names(dummy_variables_sv)=="G3")]
ytrain = dummy_variables_sv[ind.train,which(names(dummy_variables_sv)=="G3")]
ytest = dummy_variables_sv[ind.test,which(names(dummy_variables_sv)=="G3")]


# Finding Best K 
obj3_knn = knn.bestK(Xtrain, Xtest, ytrain, ytest, seq(1, nrow(dummy_variables_sv), 1), .5)
obj3_knn

## rerun with the best k
ypred1 = knn(Xtrain, Xtest, ytrain, k=obj3_knn$k.optimal, prob=T)
table(ytest, ypred1)
# evaluate performance 
performance(ytest, ypred1)



##################################### CART #####################################

#Import libraries
library(rpart)
library(rpart.plot)
library(ROSE)
library(caret)
library(dplyr)

# To get plots one at a time
par(mfrow=c(1, 1)) 

# Data in G3
table(dat$G3)

#Train, Test dataset
train = round(nrow(dat) * 0.7, 0)
train = sample(nrow(dat), train)
df_train = dat[train, ]
df_test = dat[-train, ]

#Including every variable except G1 & G2 
K=10
#set.seed(3)
fit = rpart(formula = G3 ~ sex + age + famsize + Pstatus + Medu + Fedu + 
              Mjob + Fjob + reason + guardian + traveltime + studytime + 
              failures + schoolsup + famsup + paid + activities + nursery + 
              higher + internet + romantic + famrel + freetime + goout + 
              Dalc + Walc + health + absences, data = df_train, method = "class", 
            minsplit = 5, xval = K, cp = 0.0001)

#Min-Error Tree
me = prune(fit, cp = fit$cptable[which.min(fit$cptable[,"xerror"]),"CP"])
rpart.plot(me, main = 'Min Error Tree')

printcp(x = me)

#Error on df_test dat on Min Error
yhat = predict(me, df_test, type = "class")
err.me = mean(yhat != df_test$G3)
#err.bp
cat("\nAccuraccy:",1-err.me)

#Best Pruned Tree
ind = which.min(fit$cptable[,"xerror"])
se1 = fit$cptable[ind,"xstd"]/sqrt(K)
xer1 = min(fit$cptable[,"xerror"]) + se1
ind0 = which.min(abs(fit$cptable[1:ind,"xerror"] - xer1))
bestpruned = prune(fit, cp = fit$cptable[ind0,"CP"])
rpart.plot(bestpruned, main = 'Best Pruned Tree')

printcp(x = bestpruned)


#Error on df_test dat on Best Pruned
yhat = predict(bestpruned, df_test, type = "class")
err.bp = mean(yhat != df_test$G3)
#err.bp
cat("\nAccuraccy:",1-err.bp)


#cutoff results
cut_offs = c(0.5,0.4,0.3)

# Function to evaluate performance and setting cutoffs
performance = function(ytest, ypred, ct,method) {
  measures = c(
    Method=method,
    Cutoff = ct,
    ErrorRate = mean(ytest != ypred),
    Sensitivity = mean(ytest[ytest == 1] == ypred[ytest == 1]),
    Specificity = mean(ytest[ytest == 0] == ypred[ytest == 0]),
    Accuracy = mean(ytest == ypred)
  )
  
  return(measures)
}

performance_table_CART = function(cart_model ,cart_type){
  cart_table <- data.frame()
  for (cut_off in cut_offs) {
    prob1 = predict(cart_model, df_test, type = "prob")[,2]
    ypred = as.numeric(prob1 > cut_off)
    ytest = as.numeric(df_test$G3)
    performance_result = performance(ytest, ypred, cut_off,cart_type)
    # Combine results into a data frame
    result_row <- data.frame(t(performance_result))
    cart_table <- rbind(cart_table, result_row)
  }
  colnames(cart_table) <- c("Method", "Cutoff", "ErrorRate", "Sensitivity", "Specificity", "Accuracy")
  return(cart_table)
}

cart_me_table = performance_table_CART(me,"CART-ME Tree")
cart_bestpruned_table = performance_table_CART(bestpruned,"CART-BP Tree")
#CART results
cart_table = rbind(cart_me_table, cart_bestpruned_table)
cart_table

