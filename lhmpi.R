library(DJL)

################################################################################

lhmi <-
  function(xdata, ydata, tm = NULL, dmu = NULL, dm = "dea", rts = "crs", g = NULL, 
           wd = NULL, ncv = NULL, env = NULL, cv = "convex"){
    
    # Initial Checks
    if(!(3 %in% c(length(dim(xdata)), length(dim(ydata)))))              stop('Data must be 3-dimensional.')
    if(dim(xdata)[length(dim(xdata))] != dim(ydata)[length(dim(ydata))]) stop('Data must be balanced.')
    if(!is.null(tm) && length(tm) != dim(xdata)[length(dim(xdata))])     stop('tm must have a length of the time horizon.')
    if(is.na(match(dm,          c("dea", "ddf", "hdf"))))                stop('dm must be "dea", "ddf", or "hdf".')
    if(is.na(match(rts,         c("crs", "vrs", "irs", "drs"))))         stop('rts must be "crs", or "vrs".')
    if(is.na(match(cv,          c("convex", "fdh"))))                    stop('cv must be "convex" or "fdh".')
    
    # Parameters
    xdata <- if(length(dim(xdata)) != 3) array(xdata, c(dim(xdata)[1], 1, dim(xdata)[2])) else as.array(xdata)
    ydata <- if(length(dim(ydata)) != 3) array(ydata, c(dim(ydata)[1], 1, dim(ydata)[2])) else as.array(ydata)
    g.exe <- paste0("array(c(", 
                    paste0("xdata[,,", 1:dim(xdata)[3], "],", "ydata[,,", 1:dim(ydata)[3], "]", collapse=","), 
                    "), c(dim(xdata)[1], dim(xdata)[2] + dim(ydata)[2], dim(xdata)[3]))")
    gv    <- if(is.null(g)) eval(parse(text = g.exe)) else as.array(g)
    n     <- dim(xdata)[1]
    m     <- dim(xdata)[2]
    s     <- dim(ydata)[2]
    wd    <- if(is.null(wd)) matrix(c(0), ncol = s) else matrix(wd, 1)
    rts   <- ifelse(cv == "fdh", "vrs", rts)
    t     <- ifelse(is.null(tm), dim(xdata)[length(dim(xdata))], length(tm))
    tm    <- if(is.null(tm)) paste0("t", 1:t) else as.vector(tm)
    
    # Model Arguments
    m.arg.i <- m.arg.o <- list()
    if(dm %in% c("dea")){
      for(i in 1:t){
        m.arg.i[[i]] <- list(rts = rts, orientation = 'i')
        m.arg.o[[i]] <- list(rts = rts, orientation = 'o')
      }
    }else if(dm == "hdf"){
      for(i in 1:t){m.arg[[i]] <- list(rts = rts, wd = wd)}
    }else{
      for(i in 1:t){m.arg[[i]] <- list(rts = rts, g = gv[,,i], wd = wd)}
    }
    
    # Inter-temporal dm
    inter <- function(t, e, f, io){
      temp.it <- vector()
      for(j in 1:n){
        temp.x  <- rbind(xdata[j,,e], as.matrix(xdata[,,t]))
        temp.y  <- rbind(ydata[j,,f], as.matrix(ydata[,,t]))
        temp.g  <- if(is.null(g)) cbind(temp.x, temp.y) else rbind(gv[j,,f], gv[,,t])
        if(dm %in% c("dea")){m.arg <- list(rts = rts, orientation = io)}
        else if       (dm == "hdf"){m.arg <- list(rts = rts, wd = wd)}
        else                       {m.arg <- list(rts = rts, g = temp.g, wd = wd)}
        temp.se <- do.call(paste0("dm.", dm), append(list(xdata = temp.x, ydata = temp.y, se = T, o = 1), m.arg))$eff[1]
        temp.no <- do.call(paste0("dm.", dm), append(list(xdata = temp.x, ydata = temp.y, se = F, o = 1), m.arg))$eff[1]
        temp.it <- c(temp.it, ifelse(round(temp.no, 5) < 1, temp.no, temp.se))
      }
      return(temp.it)
    }
    
    # Luenberger-Hicks-Moorsteen productivity Indicator
    lhm.t <- lhm.t1 <- lhm <- data.frame()
    for(i in 1:(t-1)){
      # Distance Functions
      d.t.t.t.o <- do.call(paste0("dm.", dm), append(list(xdata = xdata[,,i],     ydata = ydata[,,i]),     m.arg.o[[i]]))$eff
      d.t.t.t1.o <- inter(i, i, i + 1, 'o')
      d.t.t1.t.i <- inter(i, i + 1, i, 'i')
      d.t.t.t.i <- do.call(paste0("dm.", dm), append(list(xdata = xdata[,,i],     ydata = ydata[,,i]),     m.arg.i[[i]]))$eff
      
      d.t1.t1.t.o <- inter(i + 1, i + 1, i, 'o')
      d.t1.t1.t1.o <- do.call(paste0("dm.", dm), append(list(xdata = xdata[,,i + 1], ydata = ydata[,,i + 1]), m.arg.o[[i]]))$eff
      d.t1.t1.t1.i <- do.call(paste0("dm.", dm), append(list(xdata = xdata[,,i + 1], ydata = ydata[,,i + 1]), m.arg.i[[i]]))$eff
      d.t1.t.t1.i <- inter(i + 1, i, i + 1, 'i')
      
      # Tick mark
      temp.tm <- rep(paste0(tm[i], "-", tm[i + 1]), n)    
      
      # Transform zero-eff into one-eff
      if(dm %in% c("ddf")){
        m.0.0 <- m.0.0 + 1
        m.1.1 <- m.1.1 + 1
        m.0.1 <- m.0.1 + 1
        m.1.0 <- m.1.0 + 1
      }
      
      # LHM (t)
      temp.lhm.t <- (d.t.t.t.o - d.t.t.t1.o) - (d.t.t1.t.i - d.t.t.t.i)
      lhm.t <- rbind(lhm.t, data.frame(Period = temp.tm, DMU = factor(1:n), LHM.t = temp.lhm.t))
      
      # LHM (t + 1)
      temp.lhm.t1 <- (d.t1.t1.t.o - d.t1.t1.t1.o) - (d.t1.t1.t1.i - d.t1.t.t1.i)
      lhm.t1 <- rbind(lhm.t1, data.frame(Period = temp.tm, DMU = factor(1:n), LHM.t1 = temp.lhm.t1))
      
      # LHM
      temp.lhm <- 0.5 * (temp.lhm.t + temp.lhm.t1)
      lhm <- rbind(lhm, data.frame(Period = temp.tm, DMU = factor(1:n), LHM = round(temp.lhm,digits = 4)))
    }
    
    # Returning results object
    columns <- unique(lhm$Period)
    lhm <- reshape(lhm, idvar = "DMU", timevar = "Period", direction = "wide")
    colnames(lhm) <- c("DMU", columns)
    lhm$DMU <- dmu
    lhm.mean <- colMeans(lhm[,2:(dim(lhm)[2])])
    lhm.t <- reshape(lhm.t, idvar = "DMU", timevar = "Period", direction = "wide")
    colnames(lhm.t) <- c("DMU", columns)
    lhm.t$DMU <- dmu
    lhm.t1 <- reshape(lhm.t1, idvar = "DMU", timevar = "Period", direction = "wide")
    colnames(lhm.t1) <- c("DMU", columns)
    lhm.t1$DMU <- dmu
    
    results <- list(lhm.t = lhm.t, lhm.t1 = lhm.t1, lhm = lhm, avg.lhm = lhm.mean)
    return(results)
  }

################################################################################

dataframe.to.array <- function(data, year_col, id_col, x_col, y_col){
  z <- length(unique(data[,year_col]))
  y1 <- length(x_col)
  y2 <- length(y_col)
  x <- length(unique(data[,id_col]))
  xdata <- array(0, dim = c(x, y1, z))
  ydata <- array(0, dim = c(x, y2, z))
  for(i in 1:z){
    t <- unique(data[,year_col])[i]
    ydata[,,i] <-  data.matrix(data[data[,year_col]==t,y_col])
    xdata[,,i] <- data.matrix(data[data[,year_col]==t,x_col])
  }
  return(list(xdata = xdata, ydata = ydata))
}
