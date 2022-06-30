cat("\014")
rm(list=ls())
library(readxl)
source("/Users/msaharan96/Library/CloudStorage/OneDrive-NATIONALINSTITUTEOFINDUSTRIALENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/lhmpi.R")
options(scipen = 999)
setwd("/Users/msaharan96/OneDrive - NATIONAL INSTITUTE OF INDUSTRIAL ENGINEERING/Project 'Labour Productivity in Indian Industry'/Data/Industry-wise Data")

address <- c("Chemicals & chemical products/Chemicals & chemical products_.xls", "Construction materials/Construction materials_.xls","Consumer goods/Consumer goods_.xls","Food & agro-based products/Food & agro-based products_.xls","Machinery/Machinery_.xls","Metals & metal products/Metals & metal products_.xls","Textiles/Textiles_.xls","Transport equipment/Transport equipment_.xls")
folder <- c("Chemicals & chemical products/","Construction materials/","Consumer goods/","Food & agro-based products/","Machinery/","Metals & metal products/","Textiles/","Transport equipment/")

for(i in 1:length(address)){
  if(i == 1){t0 <- Sys.time()}
  data <- read_xls(address[i])
  data1 <- subset(data, select = c('CompanyName', 'year'))
  data2 <- subset(data, select = c('output', "input1", "input2", "input3", "input4", "input5", "input6", "input7"))
  data1$year <- format(data1$year, format="%Y")
  data <- cbind(data1, round(data2, digits = 4))
  data <- data.frame(data)
  temp <- dataframe.to.array(data = data, year_col = 2, id_col = 1, x_col = 4:10, y_col = 3)
  xdata <- temp$xdata
  ydata <- temp$ydata
  rm("data1", "data2", "temp")
  dmu <- unique(data$CompanyName)
  
  pi1 <- lhmi(xdata = xdata, ydata = ydata, rts = 'vrs', tm = unique(data$year), dmu = unique(data$CompanyName))
  pi2 <- roc.malmquist(xdata = xdata, ydata = ydata, tm = unique(data$year), dm = 'dea', rts = 'vrs', orientation = 'i')
  
  columns <- unique(pi2$mi$Period)
  avg.lhm <- data.frame(matrix(c(DMU = "Average",round(pi1$avg.lhm, digits = 4)), nrow = 1))
  colnames(avg.lhm) <- c("DMU", columns)
  lhm <- rbind(pi1$lhm,avg.lhm)
  mi <- reshape(pi2$mi, idvar = "DMU", timevar = "Period", direction = "wide")
  colnames(mi) <- c("DMU", columns)
  mi$DMU <- dmu
  mi.mean <- matrix(0, nrow = 1, ncol = (length(colnames(mi))-1))
  colnames(mi.mean) <- columns
  for(col in 2:length(colnames(mi))){
    mi.mean[1,(col-1)] = exp(mean(log(mi[,col])))
  }
  mi.mean <- data.frame(t(mi.mean))
  mi <- rbind(mi,t(rbind(DMU = "Average", mi.mean)))
  tec <- reshape(pi2$cu, idvar = "DMU", timevar = "Period", direction = "wide")
  colnames(tec) <- c("DMU", columns)
  tec$DMU <- dmu
  tec.mean <- matrix(0, nrow = 1, ncol = (length(colnames(tec))-1))
  colnames(tec.mean) <- columns
  for(col in 2:length(colnames(tec))){
    tec.mean[1,(col-1)] = exp(mean(log(tec[,col])))
  }
  tec.mean <- data.frame(t(tec.mean))
  tec <- rbind(tec,t(rbind(DMU = "Average", tec.mean)))
  fs <- reshape(pi2$fs, idvar = "DMU", timevar = "Period", direction = "wide")
  colnames(fs) <- c("DMU", columns)
  fs$DMU <- dmu
  fs.mean <- matrix(0, nrow = 1, ncol = (length(colnames(fs))-1))
  colnames(fs.mean) <- columns
  for(col in 2:length(colnames(fs))){
    fs.mean[1,(col-1)] = exp(mean(log(fs[,col])))
  }
  fs.mean <- data.frame(t(fs.mean))
  fs <- rbind(fs,t(rbind(DMU = "Average", fs.mean)))
  
  xlsx::write.xlsx(lhm, file = paste(folder[i], "Productivity Indicator.xlsx", sep = ""), sheetName = "LHM", append = F, row.names = F)
  xlsx::write.xlsx(mi, file = paste(folder[i], "Productivity Indicator.xlsx", sep = ""), sheetName = "MI", append = T, row.names = F)
  xlsx::write.xlsx(tec, file = paste(folder[i], "Productivity Indicator.xlsx", sep = ""), sheetName = "TEC", append = T, row.names = F)
  xlsx::write.xlsx(fs, file = paste(folder[i], "Productivity Indicator.xlsx", sep = ""), sheetName = "FS", append = T, row.names = F)
  
  if(i == length(address)){t1 <- Sys.time()}
}
print(t1 - t0)

################################################################################

data <- read_xls("Chemicals & chemical products/Chemicals & chemical products_.xls")
data1 <- subset(data, select = c('CompanyName', 'year'))
data2 <- subset(data, select = c('output', "input1", "input2", "input3", "input4", "input5", "input6", "input7"))
data1$year <- format(data1$year, format="%Y")
data <- cbind(data1, round(data2, digits = 4))
data <- data.frame(data)
temp <- dataframe.to.array(data = data, year_col = 2, id_col = 1, x_col = 4:10, y_col = 3)
xdata <- temp$xdata
ydata <- temp$ydata
rm("data1", "data2", "temp")
dmu <- unique(data$CompanyName)

pi1 <- lhmi(xdata = xdata, ydata = ydata, tm = unique(data$year), rts = 'vrs', dmu = unique(data$CompanyName))
pi2 <- roc.malmquist(xdata = xdata, ydata = ydata, tm = unique(data$year), rts = 'vrs', dm = 'dea', orientation = 'i')

columns <- unique(pi2$mi$Period)
avg.lhm <- data.frame(matrix(c(DMU = "Average",pi1$avg.lhm), nrow = 1))
colnames(avg.lhm) <- c("DMU", columns)
lhm <- rbind(pi1$lhm,avg.lhm)
mi <- reshape(pi2$mi, idvar = "DMU", timevar = "Period", direction = "wide")
colnames(mi) <- c("DMU", columns)
mi$DMU <- dmu
mi.mean <- matrix(0, nrow = 1, ncol = (length(colnames(mi))-1))
colnames(mi.mean) <- columns
for(col in 2:length(colnames(mi))){
  mi.mean[1,(col-1)] = exp(mean(log(mi[,col])))
}
mi.mean <- data.frame(t(mi.mean))
mi <- rbind(mi,t(rbind(DMU = "Average", mi.mean)))
tec <- reshape(pi2$cu, idvar = "DMU", timevar = "Period", direction = "wide")
colnames(tec) <- c("DMU", columns)
tec$DMU <- dmu
tec.mean <- matrix(0, nrow = 1, ncol = (length(colnames(tec))-1))
colnames(tec.mean) <- columns
for(col in 2:length(colnames(tec))){
  tec.mean[1,(col-1)] = exp(mean(log(tec[,col])))
}
tec.mean <- data.frame(t(tec.mean))
tec <- rbind(tec,t(rbind(DMU = "Average", tec.mean)))
fs <- reshape(pi2$fs, idvar = "DMU", timevar = "Period", direction = "wide")
colnames(fs) <- c("DMU", columns)
fs$DMU <- dmu
fs.mean <- matrix(0, nrow = 1, ncol = (length(colnames(fs))-1))
colnames(fs.mean) <- columns
for(col in 2:length(colnames(fs))){
  fs.mean[1,(col-1)] = exp(mean(log(fs[,col])))
}
fs.mean <- data.frame(t(fs.mean))
fs <- rbind(fs,t(rbind(DMU = "Average", fs.mean)))

xlsx::write.xlsx(lhm, file = "/Users/msaharan96/Downloads/output.xlsx", sheetName = "LHM", append = F, row.names = F)
xlsx::write.xlsx(mi, file = "/Users/msaharan96/Downloads/output.xlsx", sheetName = "MI", append = T, row.names = F)
xlsx::write.xlsx(tec, file = "/Users/msaharan96/Downloads/output.xlsx", sheetName = "TEC", append = T, row.names = F)
xlsx::write.xlsx(fs, file = "/Users/msaharan96/Downloads/output.xlsx", sheetName = "FS", append = T, row.names = F)
