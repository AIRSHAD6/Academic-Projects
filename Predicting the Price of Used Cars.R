#load packages needed
install.packages("Metrics")
library(dplyr)
library(GGally)
library(MLmetrics)
library(lmtest)
library(car)
library(forecast)
library(caret)
library(Metrics)
library(tidyverse)

#load and check the data
Toyota <- read.csv("Downloads/ToyotaCorolla.csv")
head(Toyota, 10)
glimpse(Toyota)

#check and set column number of the data
p = ncol(Toyota)

#linear regression fit first attempt
fit0 <- lm(Price ~ .-Id -Model -Mfg_Month - Mfg_Year -Met_Color -CC -Cylinders -Gears -Weight -BOVAG_Guarantee -ABS -Airbag_1 
           -Airbag_2 -Boardcomputer -Central_Lock -Power_Steering -Radio -Mistlamps -Backseat_Divider -Metallic_Rim -Radio_cassette -Parking_Assistant , data = Toyota)
summary(fit0)
#drop variable Color because it is not significant

#linear regression fit second attempt without Color
fit1 <- lm(Price ~ .-Color -Id -Model -Mfg_Month - Mfg_Year -Met_Color -CC -Cylinders -Gears -Weight -BOVAG_Guarantee -ABS -Airbag_1 
           -Airbag_2 -Boardcomputer -Central_Lock -Power_Steering -Radio -Mistlamps -Backseat_Divider -Metallic_Rim -Radio_cassette -Parking_Assistant , data = Toyota)
summary(fit1)
#drop variable Airco which is not significant

#create dummy variables for fuel_type
n <- nrow(Toyota)
Fuel_TypeDiesel <- rep(0, n)
Fuel_TypePetrol <- rep(0, n)
Fuel_TypeDiesel[Toyota$Fuel_Type == "Diesel"] <- 1
Fuel_TypePetrol[Toyota$Fuel_Type == "Petrol"] <- 1

#add dummy variables to data
Toyota$Fuel_TypeDiesel <- Fuel_TypeDiesel
Toyota$Fuel_TypePetrol <- Fuel_TypePetrol

#select variables will be used and create new dataframe
vars <- c("Price", "Age_08_04", "KM", "Fuel_TypeDiesel", "Fuel_TypePetrol", "HP", 
          "Automatic", "Doors", "Quarterly_Tax", "Mfr_Guarantee", "Guarantee_Period", 
          "Automatic_airco", "CD_Player", "Powered_Windows", "Sport_Model", "Tow_Bar")  
data2 <- Toyota[, vars]

#drop all rows with missing values
car <- data2[complete.cases(data2), ]

#use graph to check correlation between variables
ggcorr(car, label = TRUE, label_size = 2.5, hjust = 1, layout.exp = 5)

hist(car$Price,  xlab="Price",xlim=c(4000, 25000), ylim=c(0, 600),
     main="Figure 1: Histogram of Prices of used cars")

#data split
set.seed(123)
train.index <- sample(row.names(car), floor(0.8*nrow(car)))  
test.index <- setdiff(row.names(car), train.index) 

train.df <- car[train.index, ]  
test.df <- car[test.index, ]

#model 1 with the strongest correlation from graph above
model1 <-lm(formula = Price ~ Age_08_04 + KM + Automatic_airco + CD_Player,data = train.df)
summary(model1)

model1.pred <- predict(model1, test.df)

MSE1 <- mean((model1.pred - test.df$Price)^2)
RMSE1 <- sqrt(MSE1)
print(RMSE1)
#RMSE = 1350.203, Adjusted R-squared: 0.8352

#model 2 with all varibales
model2 <-lm(formula = Price ~ .,data = train.df)
summary(model2)
model2.pred <- predict(model2, test.df)
MSE2 <- mean((model2.pred - test.df$Price)^2)
RMSE2 <- sqrt(MSE2)
print(RMSE2)
#RMSE = 1157.23,Adjusted R-squared:0.8828


#model3 without weak correlation variable from graph above
model3 <-lm(formula = Price ~Age_08_04 +KM +HP +Doors+ Quarterly_Tax 
            + Mfr_Guarantee + Automatic_airco+CD_Player+Powered_Windows+Tow_Bar+ Sport_Model,data = train.df)
summary(model3)
model3.pred <- predict(model3, test.df)
MSE3 <- mean((model3.pred - test.df$Price)^2)
RMSE3 <- sqrt(MSE3)
print(RMSE3)
#RMSE = 1193.85, Adjusted R-squared:0.875

#model without the two strongest correlation predictors
model4 <-lm(formula = Price ~HP +Doors+ Quarterly_Tax 
            + Mfr_Guarantee + Automatic_airco+CD_Player+Powered_Windows+Tow_Bar+ Sport_Model+ Fuel_TypeDiesel + Fuel_TypePetrol
            +Automatic+Guarantee_Period ,data = train.df)
summary(model4)
model4.pred <- predict(model4, test.df)
MSE4 <- mean((model4.pred - test.df$Price)^2)
RMSE4 <- sqrt(MSE4)
print(RMSE4)
#RMSE = 2245.915, Adjusted R-squared：0.6226

print(c(RMSE1,RMSE2,RMSE3,RMSE4))
#model 2 with all variables is the best for predicting

## Final model will be used to predict Price
data2 <- Toyota[, vars]

## remove those rows containing missing values
car <- data2[complete.cases(data2), ]
set.seed(123)

train.index <- sample(row.names(car), floor(0.8*nrow(car)))  
test.index <- setdiff(row.names(car), train.index) 

train.df <- car[train.index, ]  
test.df <- car[test.index, ]

full.df = rbind(train.df, test.df)
mod.final <- lm(Price ~ .,data = full.df)
summary(mod.final)

mod.final.pred<- predict(mod.final, full.df)
MSE.final <- mean((mod.final.pred - full.df$Price)^2)
RMSE.final <- sqrt(MSE.final)
print(RMSE.final)
#Adjusted R-squared: 0.8879, RMSE = 1207.788

head(mod.final.pred,10)
