setwd("~/Dropbox/ARCHeS/IMAI_Rwanda/data/clean")

library(readstata13)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(tidyr)
library(scales)
library(magrittr)
library(Cairo)
library(grid)
library(lubridate)


imai_data <- read.dta13("IMAI_monthly_rates.dta", convert.dates = TRUE, convert.factors = TRUE)
imai_data$imai_ever <- -(imai_data$imai_ever)
imai_data <- imai_data %>% select(ndate, imai_ever, tx_agree, dx_agree, quarter, year) %>%
                           gather(vartype, percent, -ndate, -imai_ever, -quarter, -year) %>%
                           mutate(imai_ever = factor(imai_ever, c(-1, 0), c("IMAI", "Control")),
                                  qlab = paste0(year, " ", "Q", quarter, sep = ""))

panel_names <- list(
  'tx_agree'="Treatment",
  'dx_agree'="Diagnosis"
)

panel_labeller <- function(variable,value){
  return(panel_names[value])
}


Cairo(file = "~/Dropbox/ARCHeS/IMAI_Rwanda/figures/figure1_rates.png",
    type = "png",
	  units = "in",
	  width = 6,
	  height = 5,
	  pointsize = 10,
	  dpi = 300)
ggplot(imai_data, aes(x = ndate, y = percent, color = imai_ever)) +
        geom_point(aes(shape = imai_ever), size = 4) +
        geom_line(aes(linetype = imai_ever), size = 1.5, alpha = 0.8) +
        facet_grid(~vartype, labeller = panel_labeller) +
        scale_y_continuous(labels = percent_format()) +
        scale_colour_few() + 
        theme_hc(base_family = "Helvetica", base_size = 14) +
        theme(legend.title = element_blank()) +
        theme(panel.margin.x = unit(1, "lines")) +
        ylab("Rate of agreement between nurse and mentor\n") +
        xlab("\nDate") 
dev.off()