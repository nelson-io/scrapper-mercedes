library(tidyverse)
library(janitor)
library(xlsx)
library(rio)

#import data


clean_elec <- function(path){
  dfelec <-  path %>%
    read_csv() %>% 
    select(-1) %>% 
    clean_names()  %>% 
    filter(
      # str_detect(agrupacion_politica, 'VOTOS', negate = T),
           str_detect(agrupacion_politica, 'TOTAL', negate = T))
   
  return(dfelec)
}

votaciones <- map(list.files('out/data', full.names = T), clean_elec) %>% 
  set_names(list.files('out/data') %>% make_clean_names())


# summary stats

summarise_lv1 <- function(df){
  dfsumm <- df %>% 
    select(-mesa) %>% 
    group_by(circuito,nro, agrupacion_politica) %>% 
    summarise_if(is.numeric,~sum(., na.rm = T)) %>% 
    ungroup()
  
  return(dfsumm)
  
}

summarise_lv2 <- function(df){
  dfsumm <- df %>% 
    select(-nro) %>% 
    group_by(circuito) %>% 
    summarise_if(is.numeric,~ sum(.,na.rm =  T))
  
  return(dfsumm)
}





votaciones_summ_1 <- map(votaciones, summarise_lv1)

votaciones_summ_2 <- map(votaciones_summ_1, summarise_lv2)



export(votaciones, 'advances/votaciones.xlsx')
export(votaciones_summ_1, 'advances/votaciones_summ_1.xlsx')
export(votaciones_summ_2, 'advances/votaciones_summ_2.xlsx')




#generamos color amarillo


agrupaciones <- map(votaciones,~ .x %>% pull(agrupacion_politica) %>% unique()) %>% 
  do.call('c', .) %>% as.character() %>% unique()

amarillas <- c('ALIANZA CAMBIEMOS BUENOS AIRES', 'CAMBIEMOS BUENOS AIRES', 'AZA.JUNTOS',
               'CAMBIEMOS BUENOS AIRES', 'LISTA 1A-AMARILLO', 'JUNTOS POR EL CAMBIO',
               'LISTA CAMBIANDO JUNTOS', 'AZA. CAMBIEMOS', "LISTA 1A AMARILLO", 'AZA.JUNTOS')


# sumamos flag amarillo

votaciones <- map(votaciones, ~ .x %>% mutate(flg_amarillo = if_else(agrupacion_politica %in% amarillas,1,0)))
votaciones_summ_1 <- map(votaciones_summ_1, ~ .x %>% mutate(flg_amarillo = if_else(agrupacion_politica %in% amarillas,1,0)))



#vemos pcts a distintos niveles

add_totals <- function(x){
  x %>% 
    filter(!(str_detect(agrupacion_politica, 'VOTOS'))) %>% 
    select(-nro, - agrupacion_politica, -flg_amarillo) %>% 
    group_by(eleciones, circuito,mesa ) %>%
    summarise_all(~sum(.x, na.rm = T)) %>% 
    mutate(flg_amarillo = 9) %>% 
    select(setdiff(names(x), c('nro', 'agrupacion_politica')))
}


pct_amarillo <- function(x){
  x %>% 
    filter(!(str_detect(agrupacion_politica, 'VOTOS'))) %>% 
    select(-nro, - agrupacion_politica) %>% 
    group_by(eleciones, circuito,mesa, flg_amarillo) %>% 
    summarise_all(~sum(.x, na.rm = T)) %>% 
    rbind(x %>% add_totals() %>% select(names(.))) %>% 
    filter(flg_amarillo %in% c(1,9)) %>%
    arrange(flg_amarillo) %>% 
    group_by(eleciones, circuito,mesa) %>% 
    summarise_all(~first(.x)/last(.x)) %>% 
    select(-flg_amarillo)
}




add_totals_c <- function(x){
  x %>% 
    filter(!(str_detect(agrupacion_politica, 'VOTOS'))) %>% 
    select(-nro, - agrupacion_politica, -flg_amarillo) %>% 
    group_by( circuito ) %>%
    summarise_all(~sum(.x, na.rm = T)) %>% 
    mutate(flg_amarillo = 9) %>% 
    select(setdiff(names(x), c('nro', 'agrupacion_politica')))
}


pct_amarillo_c <- function(x){
  x %>% 
    filter(!(str_detect(agrupacion_politica, 'VOTOS'))) %>% 
    select(-nro, - agrupacion_politica) %>% 
    group_by( circuito, flg_amarillo) %>% 
    summarise_all(~sum(.x, na.rm = T)) %>% 
    rbind(x %>% add_totals_c() %>% select(names(.))) %>% 
    filter(flg_amarillo %in% c(1,9)) %>%
    arrange(flg_amarillo) %>% 
    group_by( circuito) %>% 
    summarise_all(~first(.x)/last(.x)) %>% 
    select(-flg_amarillo)
}




votaciones_amarillo <- map(votaciones, pct_amarillo)

votaciones_summ_1_amarillo <- map(votaciones_summ_1, pct_amarillo_c)



export(votaciones_amarillo, 'advances/votaciones_pct.xlsx')
export(votaciones_summ_1_amarillo, 'advances/votaciones_summ_1_pct.xlsx')

export(votaciones_amarillo, 'advances/votaciones_pct_2.xlsx')
export(votaciones_summ_1_amarillo, 'advances/votaciones_summ_1_pct_2.xlsx')


#importamos metadata de participación

meta_part <- function(x){
  x %>% 
    read_csv() %>% 
    set_names(c('is_pct','tot','particip','mesa','elecciones','circuito')) %>% 
    select(-is_pct) %>% 
    spread(tot, particip) %>% 
    clean_names() %>% 
    mutate(votantes = (votantes %>% str_extract('\\d+\\.\\d{2}') %>% as.numeric())/100,
           votantes_zscore = (votantes - mean(votantes))/sd(votantes)) %>% 
    arrange(votantes_zscore)
}



meta_vot <- map(list.files('out/meta', full.names = T), meta_part)





#Histogramas participacion por mesa
iter <- 0
for(i in 1:7){
  ggplot(meta_vot[[i]])+
    geom_histogram(aes(x = votantes), col = 'white', fill = 'steelblue', binwidth = .007)+
    theme_minimal()+
    scale_x_continuous(labels = scales::percent_format(accuracy = 1),n.breaks = 10)+
    ylab('Mesas')+
    xlab('Participación')+ 
    ggtitle(paste0('PARTICIPACIÓN EN ', meta_vot[[i]]$elecciones[1]))
  
  ggsave(paste0('plots/participacion_', iter , ".png"))
  iter <- iter + 1
}


#Histogramas participacion por mesa faceteados

iter <- 0
for(i in 1:7){
  ggplot(meta_vot[[i]])+
    geom_density(aes(x = votantes), col = 'black', fill = 'steelblue', alpha = .3)+
    theme_minimal()+
    scale_x_continuous(labels = scales::percent_format(accuracy = 1),n.breaks = 6)+
    ylab('Mesas')+
    xlab('Participación')+ 
    ggtitle(paste0('PARTICIPACIÓN EN ', meta_vot[[i]]$elecciones[1]))+
    facet_wrap(~circuito, scales = 'free_y')
  
  ggsave(paste0('plots/participacion_facet_', iter , ".png"))
  iter <- iter + 1
}


#  voto amarillo

for(i in 1:7){
  for(j in setdiff(names(votaciones_amarillo[[i]]), c('eleciones', 'circuito', 'mesa'))){
    
    ggplot(votaciones_amarillo[[i]], aes(x = as.factor(circuito), y = get(j) ))+
      geom_boxplot()+
      geom_jitter(width = .3, alpha = .5, aes(col = as.factor(circuito)))+
      theme_bw()+
      coord_flip()+
      scale_y_continuous(labels = scales::percent_format(accuracy = 1),n.breaks = 10) +
      ggtitle(paste0('% VOTO AMARILLO EN MESAS POR CIRCUITO  ', votaciones_amarillo[[i]]$eleciones[1]))+
      xlab('Circuito')+
      ylab(j) +
      theme(legend.title = element_blank()) + 
      theme(legend.position = "none")
    
    ggsave(paste0('plots/voto_amarillo_boxplots_',i,'_',j,'.png'),width = 12)
  }
  
}








export(meta_vot,'advances/particip_votaciones.xlsx')
export(votaciones_amarillo,'advances/part.xlsx')



