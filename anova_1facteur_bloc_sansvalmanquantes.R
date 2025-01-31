
##############################################################
################ INITIALISATION PROJECT ######################
##############################################################

# S'il s'agit de la première fois que vous ouvrez ce projet :
#   - lancer renv::status()
#   - Si des packages ne sont pas installer, lancer renv::restore()
#   - Si vous améliorez ce projet, pensez à faire renv::snapshot()


###############################################################
############ APPEL des libraries nécessaires ##################
###############################################################

## libraries -------------------------------------
library(tidyverse)
library(ggpubr)
library(rstatix)

###############################################################
########## Gestion chemins et importation csv #################
###############################################################

# path -------------------------------------
path_main = getwd()
path_data = paste(path_main,"data",sep="/")
path_output = paste(path_main,"output",sep="/")

# importer csv et traitement dataframe -------------------------------------
path_csv = paste(path_data,"bdd_anova.csv",sep="/")
df_anova <- read.table(path_csv,sep=";",header=T)

# plateforme 4 uniquement -------------------------------------
df_anova = df_anova %>% 
           filter(N_plateforme == 4)

df_anova[c(1:5,7)] <- lapply(df_anova[c(1:5,7)], factor) 
str(df_anova)


###############################################################
########## ANOVA analyse stats  #################
###############################################################

levels(df_anova$id_var)
levels(df_anova$REP)

## stats descriptives -------------------------------------
df_anova %>%
  group_by(id_var) %>%
  get_summary_stats(MS_etuve, type = "mean_sd")

df_anova %>%
  group_by(id_var) %>%
  get_summary_stats(MS_NIRS, type = "mean_sd")


## visualisation boxplot -------------------------------------

boxplot_etuve <- ggplot(data=df_anova, aes(x=id_var, y=MS_etuve, colour=id_var, fill=id_var))
boxplot_etuve <- boxplot_etuve + geom_boxplot(alpha=0.5, outlier.alpha=0)
boxplot_etuve <- boxplot_etuve + geom_jitter(width=0.25)
boxplot_etuve <- boxplot_etuve + theme_classic()
boxplot_etuve <- boxplot_etuve + labs(title="Boxplot MS_etuve selon la variété")
boxplot_etuve <- boxplot_etuve + theme(plot.title = element_text(hjust = 0.5, color="red", size=18, face="bold", margin=margin(t=5,b=10))) 
boxplot_etuve <- boxplot_etuve + labs(x="Variétés", y="MS (t/ha)")
boxplot_etuve


## vérification des hypothèses -------------------------------------

# valeurs aberrantes -------------------------------------

df_outliers = df_anova %>% 
              identify_outliers(MS_etuve)
# retirer les 2 dernière colonnes
# starwars %>%
#   select(-(name:mass)) %>%        # the range of columns from 'name' to 'mass'
#   select(-contains('color')) %>%  # any column name that contains 'color'
#   select(-starts_with('bi')) %>%  # any column name that starts with 'bi'
#   select(-ends_with('er')) %>%    # any column name that ends with 'er'
#   select(-matches('^f.+s$')) %>%  # any column name matching the regex pattern
#   select_if(~!is.list(.)) %>%     # not by column name but by data type
#   head(2)

df_outliers = df_outliers %>% select (-c(is.outlier, is.extreme))

# on enlève les valeurs aberrantes -------------------------------------
df_anova_new = setdiff(df_anova, df_outliers)

# normalité -------------------------------------
# Construire le modèle linéaire
model  <- lm(MS_etuve ~ id_var + REP, data = df_anova_new )
# Créer un QQ plot des résidus
ggqqplot(residuals(model))

# shapiro test
df_shapiro = shapiro_test(residuals(model))

# homogénéité variances -------------------------------------
plot(model, 1)
# autre option
df_anova_new %>% levene_test(MS_etuve ~ id_var + REP)


### ANOVA -----------------------------------------
#res.aov <- df_anova_new %>% anova_test(MS_etuve ~ id_var + REP)
#res.aov

anova_result = anova(model)

anova_coeff = coef(model)   # coefficients du modèle

anova_residus = residuals(model) #résidus

df_anova_new["MS_etuve_residus"]= residuals(model)

fitted(model) #Valeurs estimées avec le modèle => residuals(res_lm)+fitted(res_lm)= valeurs observées


# comp par paires-------------
# Comparaisons par paires
pwc <- df_anova_new %>% tukey_hsd(MS_etuve ~ id_var + REP)
pwc

# dunnett
library(DescTools)
DunnettTest(x=df_anova_new$MS_etuve, g=df_anova_new$id_var)
