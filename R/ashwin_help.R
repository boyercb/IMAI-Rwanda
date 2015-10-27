# working directory (for ashwin)
setwd("~/Dropbox/ARCHeS/ashwin/")

library(foreign)
library(sas7bdat)
library(dplyr)
library(tidyr)
library(magrittr)
library(ggplot2)
library(grid)
library(lme4)
library(lubridate)

# read data file
patient <- read.csv("./data/IMAI_DATA_CLEAN_PER_PATIENT.csv", header = T)

# note: discovered per complaint file is not complete
# regenerating per complaint file from per patient file
complaint <- patient %>% gather(key, value, starts_with("chief_complaint")) %>% 
                         filter(value != "") %>% arrange(ID) %>% 
                         mutate(diag_agree = ifelse(key == "chief_complaint1" & classagree1 == 2, 2, 
                                             ifelse(key == "chief_complaint1" & classagree1 == 1, 1,
                                             ifelse(key == "chief_complaint1" & is.na(classagree1), NA, 
                                             ifelse(key == "chief_complaint2" & classagree2 == 2, 2, 
                                             ifelse(key == "chief_complaint2" & classagree2 == 1, 1, 
                                             ifelse(key == "chief_complaint2" & is.na(classagree2), NA,
                                             ifelse(key == "chief_complaint3" & classagree3 == 2, 2, 
                                             ifelse(key == "chief_complaint3" & classagree3 == 1, 1,
                                             ifelse(key == "chief_complaint2" & is.na(classagree3), NA, NA))))))))),
                                tx_agree = ifelse(key == "chief_complaint1" & treatagree1 == 2, 2, 
                                           ifelse(key == "chief_complaint1" & treatagree1 == 1, 1,
                                           ifelse(key == "chief_complaint1" & is.na(treatagree1), NA, 
                                           ifelse(key == "chief_complaint2" & treatagree2 == 2, 2, 
                                           ifelse(key == "chief_complaint2" & treatagree2 == 1, 1, 
                                           ifelse(key == "chief_complaint2" & is.na(treatagree2), NA,
                                           ifelse(key == "chief_complaint3" & treatagree3 == 2, 2, 
                                           ifelse(key == "chief_complaint3" & treatagree3 == 1, 1,
                                           ifelse(key == "chief_complaint2" & is.na(treatagree3), NA, NA))))))))))

# write new per complaint file
write.csv(complaint,"./complaint.csv", row.names = F, na = "")

# create data set for plotting
patient$timeperiod <- as.Date(patient$date_obs, "%m/%d/%y")
patient$timeperiod2 <- ifelse(patient$timeperiod < as.Date("2011-03-31"), "pre", "post")
ashwin <- complaint %>% select(ID, date_obs, health_center, nurseID, nurse_train_imai, trainmonth, level_educ, exp_opd, pt_age, pt_sex, diag_agree, tx_agree)

# variable recodes
ashwin$nurseID <- factor(ashwin$nurseID)
ashwin <- ashwin %>% rename(patientID = ID) %>% mutate(complaintID = 1:nrow(ashwin))
ashwin$level_educ <- ifelse(ashwin$level_educ == "A1", "A1", 
                     ifelse(ashwin$level_educ == "A2", "A2", NA))
ashwin$pt_sex <- ifelse(ashwin$pt_sex == "Female", "Female", 
                            ifelse(ashwin$pt_sex == "Male", "Male", NA))
ashwin$trainmonth <- ifelse(ashwin$trainmonth == "March", "March", 
                     ifelse(ashwin$trainmonth == "October", "October", "None"))
ashwin$trainmonth<- factor(ashwin$trainmonth, c("None", "March", "October"))
ashwin$timeperiod <- as.character(ashwin$date_obs)
ashwin$timeperiod <- as.Date(ashwin$timeperiod, "%m/%d/%y")
ashwin$timeperiod2 <- ifelse(ashwin$timeperiod < as.Date("2011-03-31"), "pre", "post")
ashwin$timeperiod3 <- ifelse(ashwin$timeperiod < as.Date("2011-03-31"), "pre", ifelse(ashwin$timeperiod > as.Date("2011-10-01"), "post", "mid"))

ashwin$diag_agree <- ifelse(ashwin$diag_agree == 1, "Yes", ifelse(ashwin$diag_agree == 2, "No", NA))
ashwin$diag_agree2 <- ifelse(ashwin$diag_agree == "Yes", 1, ifelse(ashwin$diag_agree == "No", 0, NA))
ashwin$imai_train <- ifelse(ashwin$nurse_train_imai == "Yes", 1, 
                     ifelse(ashwin$nurse_train_imai == "No", 0, NA))
ashwin$tx_agree <- ifelse(ashwin$tx_agree == 1, "Yes", ifelse(ashwin$tx_agree == 2, "No", NA))
ashwin$tx_agree2 <- ifelse(ashwin$tx_agree == "Yes", 1, ifelse(ashwin$tx_agree == "No", 0, NA))


# turn a date into a 'monthnumber' relative to an origin
monnb <- function(d) { lt <- as.POSIXlt(as.Date(d, origin="1900-01-01"));
lt$year*12 + lt$mon }

# compute a month difference as a difference between two monnb's
mondf <- function(d1, d2) { monnb(d2) - monnb(d1) }
ashwin$time <- mondf( as.Date("2011-01-01"), ashwin$timeperiod)


# create variable representing the number of times exposed to mentoring
tbl <- ashwin %>% select(nurseID, date_obs) %>% group_by(nurseID, date_obs)  %>% summarise(nobs = n()) %>% group_by(nurseID) %>% summarise(nobs2 = n())
ashwin <- left_join(ashwin, tbl)
ashwin %>% select(patientID, time, nobs2) %>% rename(ID = patientID, nobs=nobs2) %>% write.csv("./aa.csv")
ashwin$nobs <- ifelse(ashwin$nobs2 >= 20, "20+", "< 20")
list <- c()


### plots
ash_plot <- read.csv("./data/plot.csv", header = T)
ash_plot$date <- as.Date(paste(ash_plot$date, "-01", sep=""), "%y-%b-%d")
png(file = "agreement_trend_plot.png", width = 3000, height = 1800, res = 300)
ash_plot %<>% select(date, p_diag_agree, p_tx_agree) %>% gather(type, percent, -date) %>% mutate(percent = percent *100)
ash_plot %>% ggplot(aes(x = date, y = percent, color = type)) + 
  geom_point(aes(shape = type), size = 3) + geom_line(aes(linetype = type)) + 
  theme_bw(base_size = 12) + scale_shape_discrete("Decision type", labels = c("Diagnosis", "Treatment"),solid = F) + scale_linetype_discrete("Decision type", labels = c("Diagnosis", "Treatment")) +
  scale_colour_discrete("Decision type", labels = c("Diagnosis", "Treatment")) + ylab("Percent agreement") + xlab("Date") + 
  ggtitle("Effect of time on frequency of agreement in diagnosis and treatment between nurse and mentor\n") + 
  geom_segment(aes(x = as.Date(c("2011-03-01")), y = 39, xend = as.Date(c("2011-03-01")), yend = 44), colour = "black", size=1, arrow = arrow(length = unit(0.5, "cm"))) + 
  geom_segment(aes(x = as.Date(c("2011-10-01")), y = 44, xend = as.Date(c("2011-10-01")), yend = 49), colour = "black", size=1, arrow = arrow(length = unit(0.5, "cm"))) +
  annotate("text", x = as.Date(c("2011-03-01")), y = 37, label = "March training", size = 5) +
  annotate("text", x = as.Date(c("2011-10-01")), y = 42, label = "October training", size = 5)
dev.off()

ash_plot2 <- ashwin %>% mutate(month = floor_date(as.Date(as.character(date_obs), format = "%m/%d/%y"), unit =  "month"),
                               nurse_grp = ifelse(imai_train == 1, "trained", "untrained")) %>%
                        group_by(month, nurse_grp) %>%
                        summarise(dx_agree = sum(diag_agree2, na.rm = T),
                                  tx_agree = sum(tx_agree2, na.rm = T),
                                  count = n()) %>%
                        mutate(p_dx_agree = dx_agree/count,
                               p_tx_agree = tx_agree/count) %>%
                        select(month, nurse_grp, p_dx_agree, p_tx_agree) %>%
                        gather(type, percent, -month, -nurse_grp)

misc <- data.frame(month = as.Date(c("2011-03-01", "2011-03-01")),
                   nurse_grp = c("trained", "trained"),
                   type = factor(c("p_dx_agree", "p_tx_agree")),
                   percent = c(0.3148789, 0.2941176))

ash_plot2 <- rbind(ash_plot2, misc)
ash_plot2 %<>% mutate(label = ifelse(type == "p_dx_agree", "Diagnosis", "Treatment"))
pos <- data.frame(ymin_m = c(0.22,0.22), 
                  ymin_o = c(0.22,0.22),
                  ymax_m = c(0.27,0.27),
                  ymax_o = c(0.27,0.27),
                  text_m = c(0.20,0.20),
                  text_o = c(0.20,0.20),
                  type = c("p_dx_agree", "p_tx_agree"))
ashwin %>% filter(nurse_train_imai == "No") %>% 
              ggplot(aes(x = timeperiod2, y = diag_agree2)) + 
              stat_smooth(method = "lm", aes(group = 1))
ashwin %>% filter(nurse_train_imai == "No") %>% 
  ggplot(aes(x = timeperiod2, y = tx_agree2)) + 
  stat_smooth(method = "lm", aes(group = 1))
png(file = "agreement_trend_plot2.png", width = 3500, height = 1800, res = 300)
p <- ash_plot2 %>% ggplot(aes(x = month, y = percent, color = nurse_grp)) + 
                   geom_point(aes(shape = nurse_grp), size = 3) + 
                   geom_line(aes(linetype = nurse_grp), size = 1.25, alpha = 0.9) + 
                   facet_grid(~label) +
                   scale_shape_discrete("Nurse Cadre", labels = c("IMAI trained", "untrained"),solid = F) + 
                   scale_linetype_discrete("Nurse Cadre", labels = c("IMAI trained", "untrained")) +
                   scale_colour_manual("Nurse Cadre", labels = c("IMAI trained", "untrained"), values = c("#F8766D", "#619CFF")) +
                   scale_y_continuous(labels = percent_format()) +
                   ylab("Percentage of complaints in which nurse and mentor agree\n") +
                   xlab("\nDate of Observation") + 
                   ggtitle("Effect of time on frequency of agreement in diagnosis and treatment between nurse and mentor\n") +
                   theme_bw(base_size = 12, base_family = "Palatino")
p + geom_segment(aes(x = as.Date(c("2011-03-01")), y = ymin_m, xend = as.Date(c("2011-03-01")), yend = ymax_m), 
                   colour = "black", size = 0.5, data = pos, arrow = arrow(length = unit(0.25, "cm"))) + 
    geom_segment(aes(x = as.Date(c("2011-10-01")), y = ymin_o, xend = as.Date(c("2011-10-01")), yend = ymax_o), 
               colour = "black", size = 0.5, data = pos, arrow = arrow(length = unit(0.25, "cm"))) +
    annotate("text", x = as.Date(c("2011-03-01")), y = c(0.20,0.20), label = "March training", size = 2.5, family = "Palatino") +
    annotate("text", x = as.Date(c("2011-10-01")), y = c(0.20,0.20), label = "October training", size = 2.5, family = "Palatino")
dev.off()

# calculate average overall improvement per complaint
ash_plot %<>% mutate(period = ifelse(date < as.Date("2011-04-01"), "pre",
                              ifelse(date >= as.Date("2011-10-01"), "post", NA)))

ash_plot %>% group_by(period, type) %>% summarise(mu_agree = mean(percent))

nurse_d <- ashwin %>% select(timeperiod2, nurseID, diag_agree2, tx_agree2) %>% 
           gather(type, agree, -timeperiod2, -nurseID) %>%
           group_by(nurseID, timeperiod2, type) %>%
           summarise(agree = sum(agree, na.rm=T),
                     count = n()) %>%
           mutate(p_agree = agree/count,
                  timeperiod = factor(timeperiod2, c('pre', 'post'))) %>% 
           ungroup()
nurse_d %>% group_by(nurseID, timeperiod, type) %>% 
            summarise(mu_agree = mean(p_agree)*100) %>%
            spread(type, mu_agree) %>%
            spread(timeperiod, tx_agree2) %>% 
            group_by(nurseID) %>%
            filter(nurseID %in% list) %>%
            summarise(delta = sum(post, na.rm = T) - sum(pre, na.rm = T)) %$%
            mean(delta)

tmp <- nurse_d %>% filter(type == "diag_agree2") 
list <- tmp$nurseID[duplicated(tmp$nurseID)]
tmp2 <- nurse_d %>% filter(nurseID %in% list) %>% 
  select(nurseID, type, timeperiod, p_agree) %>% 
  spread(key = timeperiod, value = p_agree) %>% 
  mutate(inc = ifelse(pre < post, 0, 1)) %>% 
  select(nurseID, type, inc)

nurse_plot <- left_join(nurse_d, tmp2) %>%
           filter(nurseID %in% list) %>%
           mutate(inc = ordered(inc, c(0,1), c("increased", "decreased")),
                  type = factor(type, c("diag_agree2", "tx_agree2"), c("diagnosis", "treatment")),
                  nurseID = factor(nurseID),
                  p_agree = p_agree*100,
                  pos = ifelse(timeperiod == "pre", 1, 0),
                  q_count = cut(count, breaks = c(-Inf,20,40,60,Inf), c("0 - 19", "20 - 39", "40 - 59", "60+"))) %>%
           arrange(timeperiod)

png(file = "second.png", width = 3000, height = 1800, res = 300)
nurse_plot %>% ggplot(aes(x = timeperiod, y = p_agree, label = count)) + 
            geom_line(aes(group = nurseID, colour = "myline1"), alpha = 0.3,  linetype = 7)  + 
            facet_grid( ~ type) + stat_smooth(method = "lm", aes(group = 1, colour = "myline2"), se = F, size = 1.5, alpha = 0.6) +
            geom_point(aes(size = count)) +
            ylab("Agreement (%)") + xlab("Time Period") + theme_bw() + 
            scale_size_continuous("Observations") + scale_colour_manual("", label = c("Nurse ID", "Regression"), values = c(myline1 = "grey20", myline2 = "blue"))
dev.off()

png(file = "secondALT.png", width = 3000, height = 1800, res = 300)
nurse_plot %>% ggplot(aes(x = timeperiod, y = p_agree, label = count, colour = nurseID)) + 
  geom_line(aes(group = nurseID), alpha = 0.3,  linetype = 7)  + 
  facet_grid( ~ type) + stat_smooth(method = "lm", aes(group = 1), se = F, size = 1.5, alpha = 0.6) +
  geom_point(aes(size = count)) +
  ylab("Agreement (%)") + xlab("Time Period") + theme_bw() + 
  scale_size_continuous("Observations")
dev.off()

tmp3 <- nurse_d %>% filter(nurseID %in% list) %>% 
  select(nurseID, type, timeperiod, p_agree) %>% 
  spread(key = timeperiod, value = p_agree) %>% 
  mutate(delta = post-pre)
train <- ashwin %>% select(nurseID, nurse_train_imai) %>% group_by(nurseID) %>% summarise(train = median(nurse_train_imai))
plot2 <- left_join(tmp3, tbl)
plot2 <- left_join(plot2, train)

png(file = "third.png", width = 3000, height = 1800, res = 300)
plot2 %>% ggplot(aes(x = nobs2, y = delta)) + geom_point() + facet_wrap(~ type)
dev.off()

table <- ashwin %>% group_by(nurseID) %>% summarise(imai_train = max(imai_train))

ashwin <- ashwin %>% mutate(imai = ifelse(nurseID %in% c(201, 305, 401, 501, 502, 503, 602, 704, 804), "Cohort1", 
                                   ifelse(nurseID %in% c(102, 103, 203, 204, 306, 508, 606, 803, 806), "Cohort2",
                                          "No"))) %>%
                     mutate(imai = factor(imai, c("No", "Cohort1", "Cohort2")),
                            timeperiod3 = factor(timeperiod3, c('pre', 'mid', 'post')),
                            timeperiod2 = factor(timeperiod2, c('pre', 'post')))


