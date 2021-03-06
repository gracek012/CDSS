install.packages('pROC')

library(tidyverse)
library(pROC)

#my_data <- select(data_7.9.20, Needs_Neph_Consult, Num_Neph_Consults_Actual)
#df <- data.frame(my_data)
#df$Any_Neph_Actual <- ifelse(df$Num_Neph_Consults_Actual > 1, 1, 0)
#df1 <- select(df, Needs_Neph_Consult, Any_Neph_Actual)
#roc1 <- roc(df1$Any_Neph_Actual, df1$Needs_Neph_Consult)
#plot(roc1)
#auc(roc1)

my_data2 <- select(data_7.9.20, KFRE_Score, Num_Neph_Consults_Actual)
df2 <- data.frame(my_data2)
df2$Any_Neph_Actual <- ifelse(df2$Num_Neph_Consults_Actual > 1, 1, 0)
df3 <- select(df2, KFRE_Score, Any_Neph_Actual)
roc2 <- roc(df3$Any_Neph_Actual, df3$KFRE_Score)
auc(roc2)
plot(roc2, print.auc=TRUE)

##
