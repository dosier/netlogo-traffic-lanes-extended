#Data Preparation
library(data.table)
dataset <- read.csv("Traffic Intersection Automated experiment-diff-spreadsheet.csv", skip=13, row.names = 1, header = FALSE)
dataset <- dataset[-c(1,2,3,4,5,6,7,8),]

# #Average Wait Plot
# data_avg_wait <- dataset[,seq(1,ncol(dataset), by=3)]
# 
# avg_wait_q <- data_avg_wait[c(0:19)]
# avg_wait_q <- as.data.frame(apply(avg_wait_q, 2, as.numeric))
# names(avg_wait_q)[1] <- "avg_wait"
# 
# avg_wait_tl <- data_avg_wait[c(20:39)]
# avg_wait_tl <- as.data.frame(apply(avg_wait_tl, 2, as.numeric))
# names(avg_wait_tl)[1] <- "avg_wait"
# 
# png("mean-wait-time.png", 400, 800)
# boxplot(
#   avg_wait_tl$avg_wait, 
#   avg_wait_q$avg_wait,
#   main = "Average Wait Priority Queue time vs Traffic Lights",
#   names = c("Priority Queue", "Traffic Lights"),
#   ylab="Average Wait Time (ticks)",
#   xlab="Intersection type"
# )
# dev.off()

#Total cars Plot
data_passed_cars <- dataset[,seq(2,ncol(dataset), by=3)]

data_passed_cars_q <- data_passed_cars[c(0:19)]
data_passed_cars_q <- as.data.frame(apply(data_passed_cars_q, 2, as.numeric))
names(data_passed_cars_q)[1] <- "passed_cars"

data_passed_cars_tl <- data_passed_cars[c(20:39)]
data_passed_cars_tl <- as.data.frame(apply(data_passed_cars_tl, 2, as.numeric))
names(data_passed_cars_tl)[1] <- "passed_cars"

png("passed_cars.png", 400, 800)
boxplot(
  data_passed_cars_tl$passed_cars, 
  data_passed_cars_q$passed_cars,
  main = "Total Cars past the intersection Priority Queue time vs Traffic Lights",
  names = c("Priority Queue", "Traffic Lights"),
  ylab="Number of cars",
  xlab="Intersection type"
)
dev.off()

#variance per tick Plot
data_variance <- dataset[,seq(3,ncol(dataset), by=3)]

data_variance_q <- data_variance[c(0:19)]
data_variance_q <- as.data.frame(apply(data_variance_q, 2, as.numeric))
names(data_variance_q)[1] <- "variance_wait_time"

data_variance_tl <- data_variance[c(20:39)]
data_variance_tl <- as.data.frame(apply(data_variance_tl, 2, as.numeric))
names(data_variance_tl)[1] <- "variance_wait_time"

png("average_variance.png", 400, 800)
boxplot(
  data_variance_tl$variance_wait_time, 
  data_variance_q$variance_wait_time,
  main = "Variance between wait times Priority Queue time vs Traffic Lights",
  names = c("Priority Queue", "Traffic Lights"),
  ylab="variance between wait times (ticks)",
  xlab="Intersection type"
)
dev.off()

# Unpaired T-tests 
t_test_avg_wait <- capture.output(
  t.test(
    avg_wait_tl$avg_wait, 
    avg_wait_q$avg_wait))
writeLines(t_test_avg_wait, con = file("t_test_avg_wait.txt"))

t_test_passed_cars <- capture.output(
  t.test(
    data_passed_cars_tl$passed_cars,
    data_passed_cars_q$passed_cars))
writeLines(t_test_passed_cars, con = file("t_test_passed_cars.txt"))

t_test_variance <- capture.output(
  t.test(
    data_variance_tl$variance_wait_time, 
    data_variance_q$variance_wait_time))

writeLines(t_test_variance, con = file("t_test_variance.txt"))