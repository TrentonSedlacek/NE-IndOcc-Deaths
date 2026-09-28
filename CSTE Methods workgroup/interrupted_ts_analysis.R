library(DT)
library(nlme)
library(AICcmodavg)

df<-tibble(
  Time = 1:100,
  Intervention = c(rep(0,50),rep(1,50)),
  Post.intervention.time = c(rep(0,50),1:50),
  quantity.x = c(sort(sample(200:300,size = 50, replace = T), decreasing = T) + 
                   sample(-20:20,50, replace = T), c(sort(sample(20:170, size = 50, replace = T), decreasing = T) +
                                                     sample(-40:40,50, replace = T)))
)

datatable(df,options = list(pageLength = 100, scrollY = "200px"))

model.a = gls(quantity.x ~ Time + Intervention + Post.intervention.time, data = df,method="ML")

# Show a summary of the model
summary(model.a)

df <- df |> mutate(
  model.a.predictions = predictSE.gls(model.a, df, se.fit=T)$fit,
  model.a.se = predictSE.gls(model.a, df, se.fit=T)$se
)


ggplot(df,aes(Time,quantity.x)) +
  geom_ribbon(aes(ymin = model.a.predictions - (1.96*model.a.se), ymax = model.a.predictions + (1.96*model.a.se)), fill = "lightgreen")+
  geom_line(aes(Time,model.a.predictions),color="black",lty=1)+
  geom_point(alpha=0.3)


mod.1 = quantity.x ~ Time + Intervention + Post.intervention.time

fx = function(pval,qval){summary(gls(mod.1, data = df, correlation= corARMA(p=pval,q=qval, form = ~ Time),method="ML"))$AIC}


p = summary(gls(mod.1, data = df,method="ML"))$AIC
message(str_c ("AIC Uncorrelated model = ", p))

autocorrel = expand.grid(pval = 0:2, qval = 0:2)


for(i in 2:nrow(autocorrel)){p[i] = try(summary(gls(mod.1, data = df, correlation= corARMA(p=autocorrel$pval[i],q=autocorrel$qval[i], form = ~ Time),method="ML"))$AIC)}

autocorrel <- autocorrel %>%
  mutate(AIC = as.numeric(p)) %>%
  arrange(AIC)


autocorrel

model.b = gls(quantity.x ~ Time + Intervention + Post.intervention.time, data = df,method="ML", correlation= corARMA(p=2,q=2, form = ~ Time))

coefficients(model.a)

coefficients(model.b)

df<- df %>% 
  mutate(
    model.b.predictions = predictSE.gls (model.b, df, se.fit=T)$fit,
    model.b.se = predictSE.gls (model.b, df, se.fit=T)$se
  )

df2<-filter(df,Time<51)
model.c = gls(quantity.x ~ Time, data = df2, correlation= corARMA(p=1, q=1, form = ~ Time),method="ML")

coefficients(model.a)

coefficients(model.c)

df<-df %>% mutate(
  model.c.predictions = predictSE.gls (model.c, newdata = df, se.fit=T)$fit,
  model.c.se = predictSE.gls (model.c, df, se.fit=T)$se
)

ggplot(df,aes(Time,quantity.x))+
  geom_ribbon(aes(ymin = model.c.predictions - (1.96*model.c.se), ymax = model.c.predictions + (1.96*model.c.se)), fill = "pink")+
  geom_line(aes(Time,model.c.predictions),color="red",lty=2)+
  geom_ribbon(aes(ymin = model.b.predictions - (1.96*model.b.se), ymax = model.b.predictions + (1.96*model.b.se)), fill = "lightgreen")+
  geom_line(aes(Time,model.b.predictions),color="black",lty=1)+
  geom_point(alpha=0.3)


format(df$model.b.predictions-df$model.c.predictions,scientific = F)[c(1,50,51,100)]



