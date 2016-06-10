#!/usr/bin/env Rscript

require("ggplot2")
require("reshape2")
args <- commandArgs(trailingOnly = TRUE)

df <- read.table(paste(args[1],"/scheduler.csv",sep=""), sep=";", quote="\"", header=T)
df$duration <- (df$core + df$spe + df$solving) / 1000;
df$vms <- df$ratio * 5;
#clean the useless columns
df <- df[c("label","duration","vms","kind")];
p <- ggplot(df, aes(x=vms,y=duration, colour=kind))
p <- p + stat_summary(aes(group=kind), fun.y=mean, geom="line")
p <- p + xlab("Virtual machines (x 1,000)") + ylab("Time (sec)")
p <- p + theme_bw()
ggsave(paste(args[1],"/core-durations.pdf",sep=""), height=3, width=5);
ggsave(paste(args[1],"/core-durations.png",sep=""), height=3, width=5);