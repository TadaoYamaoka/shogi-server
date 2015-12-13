args <- commandArgs(TRUE)
file1<- args[1]
file2 <- args[2]
title <- args[3]

print(file)

d1 <- read.csv(file1, header=F)
d2 <- read.csv(file2, header=F)

sink(file="summary1.txt", split=T)
summary(d1)
sink()

con <- file("summary1.txt")
open(con)
summary_text <- readLines(con)
close(con)

sink(file="summary2.txt", split=T)
summary(d2)
sink()

con <- file("summary2.txt")
open(con)
summary_text <- readLines(con)
close(con)


png(sprintf("%s.png", file1))

library(MASS)
par(mar = c(4.5, 4.5, 4.5, 5.5))

max <- 60

truehist(d1$V1, xlim=c(0,max), col="#66ff6640", border="#66ff66", axes = FALSE, xlab = "", ylab = "", prob=FALSE)
axis(side = 1)                                          # x axis
axis(side = 2, col.axis = "#66ff66", col = "#66ff66")   # left y axis
mtext("floodgate-900-0", side = 2, line=3)

par(new = TRUE)

truehist(d2$V1, xlim=c(0,max), col="#6699ff40", border="#6699ff", axes = FALSE, xlab = "", ylab = "", prob=FALSE) 
axis(side = 4, col.axis = "#6699ff", col = "#6699ff")   # right y axis
mtext("floodgate-600-0", side = 4, line=3)

mtext(title, side=1, line=3)

dev.off()
q()


