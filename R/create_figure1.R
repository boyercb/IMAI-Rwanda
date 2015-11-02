setwd("~/Dropbox/ARCHeS/IMAI_Rwanda/data/clean")

library(readstata13)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(tidyr)
library(scales)
library(magrittr)
library(Cairo)


imai_data <- read.dta13("IMAI_monthly_rates.dta", convert.dates = TRUE)

imai_data <- imai_data %>% select(mdate, imai_now, tx_agree, dx_agree) %>%
                           gather(vartype, percent, -mdate, -imai_now)

Cairo(file = "~/Dropbox/ARCHeS/IMAI_Rwanda/figures/figure1_rates.png",
	  type = "png",
	  units = "in",
	  width = 6,
	  height = 5,
	  pointsize = 12,
	  dpi = 72)
ggplot(imai_data, aes(x = mdate, y = percent, color = factor(imai_now))) +
        geom_point(aes(shape = factor(imai_now)), size = 3) +
        geom_line(aes(linetype = factor(imai_now)), size = 1.25, alpha = 0.9) +
        facet_grid(~vartype) +
        scale_shape_discrete("", labels = c("IMAI trained", "Control"),solid = F) +
        scale_linetype_discrete("", labels = c("IMAI trained", "Control")) +
        scale_colour_manual("", labels = c("IMAI trained", "Control"), values = c("#F8766D", "#619CFF")) +
        scale_y_continuous(labels = percent_format()) +
        theme_tufte(base_family = "Helvetica") +
        ylab("Percentage of complaints in which nurse and mentor agree\n") +
        xlab("\nDate of observation") +
        ggtitle("Frequency of agreement in diagnosis and treatment between nurse and mentor over study period, Rwanda 2011-2012\n")
dev.off()