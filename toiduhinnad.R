

###### TOIDUHINNAD ######

#### KASUTUSJUHEND ####
# 
# E-poodide toodete hindade kammimine
# Toodete otsing tehakse vastavalt ontsingusõnale poodide lehtedel
# Sisesta peatükis OTSINGUSÕNA otsitava toote nimi, et teostada kammimine
# Jooksuta kood (NB! kasutab RSselenium paketti, vajab töötavad ChromeDriver-it, mis on töövalmis seatud)
# Luuakse CSV fail tulemustega 
# 


#### OTSINGUSÕNA ####

# otsingusõna, mille järgi kõigis poodides otsitakse tooteid

otsingusõna <- 'lõhefilee'



#### BAAS ####

# Paketid

library(tidyverse) # andmetöötluse suur pakett
library(stringr) # stringidega töötamine

library(rvest) # veebikammimine
library(RSelenium) # veebikammimine

library(this.path) # dir sättimiseks


# Avame Selenium Remote Driver-i
rem_driver <- remoteDriver(remoteServerAddr = "localhost",
                           browserName = "chrome",
                           port = 4444L)
rem_driver$open()




#### Prisma ####

## Seame browseri valmis

# Lähme lehele

rem_driver$navigate(paste0("https://www.prismamarket.ee/otsingutulemus?queryString=", otsingusõna))
Sys.sleep(10)

## vajutame kinni popup akna, mis küsib küpsiste kasutamise kohta
## ilma selle sammuta ei saa korralikult lehelt infot kätte, popup aken varjab infot ja ei saa elemente kätte enam
## tundub, et selle popup akna elemendid on peidus (Closed Shadow DOM), kasutame nupu vajutamiseks lihtsalt koordinaate

# muudame akna suurust, et nupule oleks lihtsam pihta saada
rem_driver$setWindowSize(500, 250)

# liigutame hiite õigesse kohta
rem_driver$mouseMoveToLocation(x = 250, y = 50)

# vajutame peale
rem_driver$click(buttonId = 0)

# teeme akna normaalseks suuruseks uuesti, et saaks ilusti infot sisse lugeda
rem_driver$setWindowSize(1000, 900)

# # otsime otsingu koha elemendi
# # SEDA OSA POLE VAJA PRISMA PUHUL KASUTADA, SEST OTSIMINE KÄIB URL-I MUUTMISE KAUDU
# # NB! elemendid on siiski siin õiged ja kood otsimise jaoks töötab!
# search_button <- rem_driver$findElement(using = "css selector", value = "input[id='search-input']")
# 
# # Saadame otsingu sõna ja Enter vajutuse otsingule
# search_button$sendKeysToElement(list("lõhefilee", key = "enter"))

Sys.sleep(1)




## Võtame andmed  

prev_scroll_h <- 0
andmed_välja <- c()

while (TRUE){
  
  ## kui tuleb Error (stale element), siis jätkab kerimisega ikkagi
  ## Stale Element Error pidavat vahest kerimisel juhtuma, ei saa vältida (?)
  tryCatch({
    
    # defineerime elemendi mida mööda alla kerime
    scrollable <- rem_driver$findElement(using = "xpath", value = "//html[@lang='et']")
    
    # kerime allapoole
    rem_driver$executeScript("arguments[0].scrollTop += 200;", list(scrollable))
    
    # võtame elemendid
    andmed <- rem_driver$findElements(using = "xpath", value = "//article[@data-test-id='product-card']")
    
    # teeme need andmed tekstiks
    andmed_tekst <- lapply(andmed, function(x) x$getElementText()) %>%
      unlist()
    
    # paneme listi ja jätame ainult info alles, mis ei kordu
    andmed_välja <- c(andmed_välja, andmed_tekst) %>% unique()
    
    ## kontrollime, kas kõrgus on veel muutunud, kui enam ei muutu, siis oleme lõpus ja lõpetame tsükli
    
    # vaatame praegust 
    scroll_h <- rem_driver$executeScript("return arguments[0].scrollTop;", list(scrollable))
    print(scroll_h)
    # kontrollime kas kõrgus on muutunud
    if(unlist(scroll_h) == unlist(prev_scroll_h)) break
    
    # salvestame järgmisesks loopiks selle loopi kõrguse 
    prev_scroll_h <- scroll_h
    
  }, error = function(e){
    
    print('error. retry.')
    
  })
  
}




## Andmete korrastamine

# teeme data frame-i andmete jaoks

df_prisma <- data.frame(
  Pood = rep('Prisma', length(andmed_välja)),
  Tootenimi = rep('', length(andmed_välja)),
  Hind = rep('', length(andmed_välja)),
  Hind_kg_kohta = rep('', length(andmed_välja)),
  Hind_kliendikaardiga = rep('', length(andmed_välja)))

# Paneme andmed data frame-i

for (i in 1:length(andmed_välja)) {
  
  if (str_detect(andmed_välja[i], pattern = 'Umbes')){ # kui toote andmete juures on sõna Umbes, siis...
    
    # lööme andmetega stringi lahku
    toode <- str_split(andmed_välja[i], pattern = '\n') %>%
      unlist()
    
    if (length(toode) == 5) {  # Kui on 5 eri osa toote stringis (kilohinda pole)
      
      df_prisma$Tootenimi[i] <- toode[1]
      df_prisma$Hind[i] <- toode[4]
      
    }
    
    if (length(toode) == 7) {  # Kui on 7 eri osa toote stringis (kilohinda on kah eraldi toodud)
      
      df_prisma$Tootenimi[i] <- toode[1]
      df_prisma$Hind[i] <- toode[4]
      df_prisma$Hind_kg_kohta[i] <- toode[5]
      
    }
    
    
  } else { # kui toote andmete juures ei ole sõna Umbes, siis...
    
    # lööme andmetega stringi lahku
    toode <- str_split(andmed_välja[i], pattern = '\n') %>%
      unlist()
    
    if (length(toode) == 5) {  # Kui on 5 eri osa toote stringis
      
      df_prisma$Tootenimi[i] <- toode[1]
      df_prisma$Hind[i] <- toode[2]
      df_prisma$Hind_kg_kohta[i] <- toode[3]
      
    }
    
    if (length(toode) == 8) {  # Kui on 8 eri osa toote stringis (mingi allahindluse info on juures)
      
      df_prisma$Tootenimi[i] <- toode[1]
      df_prisma$Hind[i] <- toode[2]
      df_prisma$Hind_kg_kohta[i] <- toode[6]
      
    }
    
  }
  
}
andmed_välja
toode <- str_split(andmed_välja[8], pattern = '\n') %>%
  unlist()
toode
length(toode)

# kui tooteid ei leitud, siis teeme ühe reaga data frame-i, mis lõpus andmete puhastuse käigus eemaldatakse

nrow(df_prisma)

if (nrow(df_prisma) == 0){
  
  df_prisma <- data.frame(
    Pood = 'Prisma',
    Tootenimi =  NA,
    Hind = NA,
    Hind_kg_kohta = NA,
    Hind_kliendikaardiga = NA)
  
}

## TULEMUS: df_prisma





#### Rimi ####

## Seame browseri valmis

# Lähme lehele

rem_driver$navigate("https://www.rimi.ee/epood/ee/")
Sys.sleep(10)

# vajutame kinni popup akna, mis küsib küpsiste kasutamise kohta (ennem ei saa lehelt infot kätte)
cookie_button <- rem_driver$findElement(using = "css selector", value = "button[id='CybotCookiebotDialogBodyButtonDecline']")
rem_driver$executeScript("arguments[0].click();", list(cookie_button))

# # otsime otsingu koha elemendi
# # SEDA OSA POLE VAJA RIMI PUHUL KASUTADA, SEST OTSIMINE KÄIB URL-I MUUTMISE KAUDU
# # NB! elemendid on siiski siin õiged ja kood otsimise jaoks töötab!
# search_button <- rem_driver$findElement(using = "css selector", value = "input[id='search-input']")
# 
# # Saadame otsingu sõna ja Enter vajutuse otsingule
# search_button$sendKeysToElement(list("lõhefilee", key = "enter"))

Sys.sleep(5)




## Võtame andmed

lugeja <- 1
andmed_välja <- c()

while (TRUE) {
  
  # võtame uue lehe lahti
  rem_driver$navigate(paste0("https://www.rimi.ee/epood/ee/otsing?currentPage=", lugeja,"&pageSize=100&query=", otsingusõna))
  
  # võtame andmed sellelt lehelt
  andmed <- rem_driver$findElements(using = "css selector", value = "div[class='card__details']")
  
  # kui andmete list on tühi, siis rohkem tooteid ei ole (sellel lehel pole enam neid tooteid)
  if (length(andmed) == 0) break
  
  
  ## võtame andmed lehelt ja lisame nimekirja, et saaks tsüklist välja võtta
  # teeme need andmed tekstiks
  andmed_tekst <- lapply(andmed, function(x) x$getElementText()) %>%
                    unlist()
      
  # paneme listi 
  andmed_välja <- c(andmed_välja, andmed_tekst)
  
  
  # liidame lugejale ühe juurde, et saaksime järgnevalt uuele lehele minna  
  lugeja <- lugeja + 1
  
} 




## Andmete korrastamine

# teeme data frame-i andmete jaoks

df_rimi <- data.frame(
  Pood = rep('Rimi', length(andmed_välja)),
  Tootenimi = rep('', length(andmed_välja)),
  Hind = rep('', length(andmed_välja)),
  Hind_kg_kohta = rep('', length(andmed_välja)),
  Hind_kliendikaardiga = rep('', length(andmed_välja)))

# Käime andmed üle ja paneme tabelisse õigesse kohta 

if (length(andmed_välja) == 0) { # kui tooteid ei leitud, siis teeme ühe reaga data Frame-i, mis lõpus andmete puhastamise käigus eemaldatakse
  
  df_rimi <- data.frame(
    Pood = 'Rimi',
    Tootenimi = NA,
    Hind = NA,
    Hind_kg_kohta = NA,
    Hind_kliendikaardiga = NA)
  
} else {
  
  for (i in 1:length(andmed_välja)) {
    
    # kui andme stringis on kirjas "Ei ole saadaval", siis jätame toote vahele
    if (str_detect(andmed_välja[i], pattern = 'Ei ole saadaval')) next
    
    # teeme toote stringi juppideks
    toode <- str_split(andmed_välja[i], pattern = '\n') %>%
      unlist()
    
    if (length(toode) == 7){ # kui allahindlus on, siis tuleb õiged väärtused nii võtta
      
      # paneme data frame-i toote nime
      df_rimi$Tootenimi[i] <- toode[1]
      
      # paneme data frame-i toote hinna
      df_rimi$Hind[i] <- paste0(toode[2], '.', toode[3], toode[4])
      
      # paneme data frame-i toote hinna
      df_rimi$Hind_kg_kohta[i] <- toode[6] 
      
    } else { # kui allahindlust pole, siis tuleb nii võtta
      
      # paneme data frame-i toote nime
      df_rimi$Tootenimi[i] <- toode[1]
      
      # paneme data frame-i toote hinna
      df_rimi$Hind[i] <- paste0(toode[2], '.', toode[3], toode[4])
      
      # paneme data frame-i toote hinna
      df_rimi$Hind_kg_kohta[i] <- toode[5]  
      
    }
    
  }
  
}

# tooted, mis on 'Ei ole saadaval' tekitavad hetkel tühjad read data frame-i
# võtme need ära

df_rimi <- df_rimi[df_rimi$Tootenimi != '',]

## TULEMUS: df_rimi






#### Selver ####

### Paneme browseri valmis

rem_driver$navigate(paste0("https://www.selver.ee/search?q=", otsingusõna))

# NB! Selveri lehel sõltub mingitel hetkedel lehe sisu sellest, mis sinu eelmine leht oli!
# Näiteks: 
    # kui kopeerin siit URL-i, siis annab mulle 12 toodet lõhefilee otsingule, see on õige kogus (kui otsing teha, siis annab kah 12 toodet)
    # kui aga kopeerida URL pärast seda kui oled juba otsingu lehel ja uues aknas see URL kleepida ja sinna minna, siis annab 8 toodet!

Sys.sleep(5)

# vajutame nupule "keeldu", et saada eest ära küpsiste kohta küsiv popup akna
cookie_button <- rem_driver$findElement(using = "css selector", value = "button[id='CybotCookiebotDialogBodyButtonDecline']")
rem_driver$executeScript("arguments[0].click();", list(cookie_button))




### Võtame andmed välja

## Võtame kõikide toodete URL-id, sest me peame minema iga toote oma lehele, et kätte saada Partnerkaardi allahindlusega hinda

URL_list <- list()
lugeja <- 1

while (TRUE){
  
  ## Scroll-imine ei ole vajalik. leht tundub laadivat ära kõik tooted ühel lehel
  # # defineerime elemendi mida mööda alla kerime
  # scrollable <- rem_driver$findElement(using = "xpath", value = "//html[@lang='ET']")
  # # kerime allapoole
  # rem_driver$executeScript("arguments[0].scrollTop += 500;", list(scrollable))
  
  # lähme õigele lehele
  rem_driver$navigate(paste0("https://www.selver.ee/search?q=", otsingusõna, "&page=", lugeja))
  
  Sys.sleep(3)
  
  # võtame elemendid
  andmed <- rem_driver$findElements(using = 'class', value='ProductCard__link')
  
  # kui listi andmed pikkus on 0, siis lehel pole enam tooteid ja seega võib tsükli lõpetada 
  if (length(andmed) == 0) break
  
  # võtame elementidest URL-id
  URL_list_leht <- lapply(andmed, function(x) x$getElementAttribute('href')) %>%
                      unlist() %>%
                      unique()
  
  # paneme URL-id listi
  URL_list <- c(URL_list, URL_list_leht) %>% unlist
    
  # liidame lugejale 1 juurde
  lugeja = lugeja +1
  break
}
URL_list





## Andmete korrastamine

if (length(URL_list) == 0) { # kui tooteid ei ole olemas
  
  # teeme data frame-i
  
  df_selver <- data.frame(
    Pood = 'Selver',
    Tootenimi = NA,
    Hind = NA,
    Hind_kg_kohta = NA,
    Hind_kliendikaardiga = NA)
  
} else {  # kui tooted on olemas: käime kõik URL-id läbi, võtame sealt andmed ja paneme need data frame-i
  
  # teeme data frame-i
  
  df_selver <- data.frame(
    Pood = rep('Selver', length(URL_list)),
    Tootenimi = rep('', length(URL_list)),
    Hind = rep('', length(URL_list)),
    Hind_kg_kohta = rep('', length(URL_list)),
    Hind_kliendikaardiga = rep('', length(URL_list)))
  
  
  # käime kõik lehed läbi, võtame andmed ja paneme data frame-i
  
  for (i in 1:length(URL_list)){
    
    # NB! Ainult sellelt lehelt elementidele vajutades saab toote lehele, kus on allanhinduse info olekas tekstina!
    # Kui kasutada lihtsalt URL-i selle toote lehele, siis allahindlust lehele ei kuvata!
    
    # Lähme toodete nimekirjaga lehele 
    rem_driver$navigate(paste0('https://www.selver.ee/search?q=', otsingusõna))
    
    # Ootame igaks juhuks, et ilusti ära laeks lehe
    # NB! katsetuse käigus: 1 sekundi peale ei tohi panna! tekivad Error-id!
    Sys.sleep(2)
    
    # Leiame elemendi selle URL-iga, kuhu me vajutada tahame; elemendi otsime URL-i järgi, mis on elemendi href-is kirjas
    URL_cut <- str_remove(URL_list[i], 'https://www.selver.ee')
    temp_link <- rem_driver$findElement(using = "xpath", value = paste0("//a[@href='", URL_cut,"']"))
    
    # vajutame sellele elemendile, kus on õige URL
    rem_driver$executeScript("arguments[0].click();", list(temp_link))
    
    # Ootame igaks juhuks, et ilusti ära laeks lehe
    # NB! katsetuse käigus: 2 sekundi peale ei tohi panna! tekivad Error-id!
    Sys.sleep(5)
    
    
    ## Toote nimi
    
    # Võtame toote nime ja paneme data frame-i
    temp <- rem_driver$findElements(using = 'class', value='ProductName')
    df_selver$Tootenimi[i] <- temp[[1]]$getElementText() %>%
      unlist()
    
    ## Võtame toote hinna ja hinna kg kohta
    
    # võtame elemendi, kus on see info
    temp <- rem_driver$findElements(using = 'class', value='ProductPrice')
    
    # teeme osadeks
    df_selver$Hind[i] <- temp[[1]]$getElementText() %>%
      str_split(pattern = '\n')
    
    # split-iga tehtud listi teine osa on hind kg kohta
    df_selver$Hind_kg_kohta[i] <- df_selver$Hind[[i]][2] %>% 
      unlist()
    
    # splitiga tehtud stringi esimene osa on toote hind
    df_selver$Hind[i] <- df_selver$Hind[[i]][1] 
    
    
    ## võtame allahindlusega hinna välja
    
    # leiame elemendi infog ja võtame sealt teksti
    
    temp <- rem_driver$findElements(using = "xpath", value = "//td[@class='ProductAttributes__value p0 pr30']")
    temp_sh <- lapply(temp[1], function(x) x$getElementText())
    
    # Kui temp_sh sisaldab sümbolit €, siis see on toote hind allahindlusega ja paneme selle df_selver tabelisse; kui pole € on see minig muu info ja  paneme tabelisse ''
    if (str_detect(unlist(temp_sh), '€')) {
      
      df_selver$Hind_kliendikaardiga[i] <- temp_sh
      
    } else {
      
      df_selver$Hind_kliendikaardiga[i] <- ''
      
    }
    
  }
  
}

## TULEMUS: df_selver






#### Barbora ####

## Seame browseri valmis

# Lähme lehele

rem_driver$navigate("https://barbora.ee/")
Sys.sleep(5)

# vajutame kinni popup akna, mis küsib küpsiste kasutamise kohta (ennem ei saa lehelt infot kätte)
cookie_button <- rem_driver$findElement(using = "css selector", value = "button[id='CybotCookiebotDialogBodyButtonDecline']")
rem_driver$executeScript("arguments[0].click();", list(cookie_button))

# # otsime otsingu koha elemendi
# # SEDA OSA POLE VAJA RIMI PUHUL KASUTADA, SEST OTSIMINE KÄIB URL-I MUUTMISE KAUDU
# # NB! elemendid on siiski siin õiged ja kood otsimise jaoks töötab!
# search_button <- rem_driver$findElement(using = "css selector", value = "input[id='search-input']")
# 
# # Saadame otsingu sõna ja Enter vajutuse otsingule
# search_button$sendKeysToElement(list("lõhefilee", key = "enter"))

Sys.sleep(3)




## Võtame andmed

lugeja <- 1
andmed_välja <- c()

while (TRUE) {
  
  # võtame uue lehe lahti
  rem_driver$navigate(paste0("https://barbora.ee/otsing?q=", otsingusõna, "&page=", lugeja))
  
  # võtame andmed sellelt lehelt
  andmed <- rem_driver$findElements(using = "css selector", value = "li[data-testid^='product-card-']")
  
  # kui andmete list on tühi, siis rohkem tooteid ei ole (sellel lehel pole enam neid tooteid)
  if (length(andmed) == 0) break
  
  
  ## võtame andmed lehelt ja lisame nimekirja, et saaks tsüklist välja võtta
  # teeme need andmed tekstiks
  andmed_tekst <- lapply(andmed, function(x) x$getElementText()) %>%
                    unlist()
  
  # paneme listi 
  andmed_välja <- c(andmed_välja, andmed_tekst)
  
  
  # liidame lugejale ühe juurde, et saaksime järgnevalt uuele lehele minna  
  lugeja <- lugeja + 1
  
} 


## Andmete korrastamine

if (length(andmed_välja) == 0) { # kui ühtegi toodet ei leitud
  
  df_barbora <- data.frame(
    Pood = 'Barbora',
    Tootenimi = 'toode puudub',
    Hind = NA,
    Hind_kg_kohta = NA,
    Hind_kliendikaardiga = NA)
  
} else { # kui vähemalt üks toode on olemas
  
  # Teeme tabeli, kuhu hakkame andmeid panema
  
  df_barbora <- data.frame(
    Pood = rep('Barbora', length(andmed_välja)),
    Tootenimi = rep('', length(andmed_välja)),
    Hind = rep('', length(andmed_välja)),
    Hind_kg_kohta = rep('', length(andmed_välja)),
    Hind_kliendikaardiga = rep('', length(andmed_välja)))
  
  
  # Käime andmed üle ja paneme tabelisse õigesse kohta 
  
  for (i in 1:length(andmed_välja)) {
    
    # kui andme stringis on kirjas "Ei ole saadaval", siis jätame toote vahele
    if (str_detect(andmed_välja[i], pattern = 'Hetkel toodet kahjuks ei ole.')) next
    
    # kui andme stringis on kirjas "Kõik tooted selles pakkumises", siis jätame toote vahele 
    # (see tundub olevat osadel kassitoitudel)
    if (str_detect(andmed_välja[i], pattern = 'Kõik tooted selles pakkumises')) next
    
    # teeme toote stringi juppideks
    toode <- str_split(andmed_välja[i], pattern = '\n') %>%
      unlist()
    
    if (str_detect(toode[1], '^–?(100|[1-9][0-9]?)%$')) { # kui on allahindlusega toode, siis esimene element on allahindluse %; sellisel juhul paneme andmed tabelisse nii:
      
      # paneme data frame-i toote nime
      df_barbora$Tootenimi[i] <- toode[2]
      
      # paneme data frame-i toote hinna
      df_barbora$Hind[i] <- paste0(toode[3], toode[4], toode[5])
      
      # paneme data frame-i toote hinna
      df_barbora$Hind_kg_kohta[i] <- toode[7]
      
      
    } else { # Kui ei ole allahindlust, siis ei ole % esimene ja andmed pannakse tabelisse nii:
      
      # paneme data frame-i toote nime
      df_barbora$Tootenimi[i] <- toode[1]
      
      # paneme data frame-i toote hinna
      df_barbora$Hind[i] <- paste0(toode[2], toode[3], toode[4])
      
      # paneme data frame-i toote hinna
      df_barbora$Hind_kg_kohta[i] <- toode[6]
      
    }
    
  }
  
  # võta tühjad read ära
  
  df_barbora <- df_barbora[df_barbora$Tootenimi != '',]
  
}


## TULEMUS: df_barbora




#### Bolt Market Soola ####

## Seame Browseri valmis

# lähme lehele
rem_driver$navigate("https://food.bolt.eu/et-EE/2-tartu/p/25658-bolt-market-soola")

Sys.sleep(7)


# otsime ja vajutame otsingu nupule
search_button <- rem_driver$findElement(using = "css selector", value = "div.css-175oi2r.r-1awozwy.r-13awgt0.r-18u37iz")

rem_driver$executeScript("arguments[0].click();", list(search_button))

Sys.sleep(3)

# Saadame otsingu sõna ja Enter vajutuse otsingule

rem_driver$sendKeysToActiveElement(list(otsingusõna, key = "enter"))

Sys.sleep(3)





## Võtame andmed

# leiame elemendi, kus saab allapoole kerida
# NB! kui Boltis pole seda toodet üldse, siis pannakse null_toote_kontroll <- TRUE ja edasi jäetakse kõik muud sammud ära 
# + df_boltmarket salvestatakse nii, et on üks rida ja Hind =  NA, mis eemaldatakse hiljem viimases andmete puhastamsie etapis

null_toote_kontroll <- FALSE

scrollable_div <- tryCatch({
  rem_driver$findElement(using = "xpath", value = "//div[@data-testid='screens.Provider.GridMenu.dishesList']")
}, error = function(e) {
  null_toote_kontroll <<- TRUE  # Set flag indicating the element was not found.
  return(NULL)
})


# See script tehakse, kui scrollable_div leiakse üles ja seega on vähemalt üks toode lehel, mida näidata
if (null_toote_kontroll == FALSE) {
  
  ## teeme tsükli, mis kerib mööda otsingu elementi vaikselt allapoole, võtab uued tulnud toodete elemendid ja paneb listi
  
  prev_scroll_h <- 0
  andmed_välja <- c()
  
  while (TRUE){
    
    # kerime allapoole
    rem_driver$executeScript("arguments[0].scrollTop += 320;", list(scrollable_div))
    
    # võtame elemendid
    andmed <- rem_driver$findElements(using = "css selector", value = "div.css-175oi2r.r-18u37iz.r-f4gmv6.r-ytbthy.r-cxgwc0")
    
    # teeme need andmed tekstiks
    andmed_tekst <- lapply(andmed, function(x) x$getElementText()) %>%
      unlist()
    
    # paneme listi ja jätame ainult info alles, mis ei kordu
    andmed_välja <- c(andmed_välja, andmed_tekst)
    
    ## kontrollime, kas kõrgus on veel muutunud, kui enam ei muutu, siis oleme lõpus ja lõpetame tsükli
    
    # vaatame praegust 
    scroll_h <- rem_driver$executeScript("return arguments[0].scrollTop;", list(scrollable_div))
    print(scroll_h)
    # kontrollime kas kõrgus on muutunud
    if(unlist(scroll_h) == unlist(prev_scroll_h)) break
    
    # salvestame järgmisesks loopiks selle loopi kõrguse 
    prev_scroll_h <- scroll_h
  }
  
  
  
  
  ## Andmete korrastamine
  
  # kaotame listi tasemed, jätame alles ainult unikaalsed read
  andmed <- andmed_välja %>%
    unique() %>%
    unlist()
  
  # eemaldame sõnad 'Populaarne', 'Hooajaline', 'Uus'
  
  andmed <- andmed %>%
    str_remove_all('Populaarne') %>%
    str_remove_all('Hooajaline') %>%
    str_remove_all('Uus')
  
  # lööme tooted lahku, eraldame sümboli "\n" baasil
  
  andmed <- andmed %>%
    str_split('\n') %>%
    unlist()
  
  
  # eemalda kui on 'Hetkel otsas'
  bool <- str_detect(andmed, 'Hetkel otsas')
  andmed <- andmed[!bool]
  
  # eemaldame tühjad elemendid
  andmed <- andmed[andmed != '']
  
  andmed
  
  ## Paneme andmed tabelisse
  # Teeme tabeli, kuhu hakkame andmeid panema
  
  df_boltmarket <- data.frame(
    Pood = rep('Bolt Market Soola', length(andmed)),
    Tootenimi = rep('', length(andmed)),
    Hind = rep('', length(andmed)),
    Hind_kg_kohta = rep('', length(andmed)),
    Hind_kliendikaardiga = rep('', length(andmed)))
  
  # käime listi 'andmed' üle ja paneme tooted tabelisse
  
  temp_andmed <- c()
  
  for (i in 1:length(andmed)) {
    
    # lääme elemendis asjad stringid lahku sümboli "\n" koha pealt
    temp_andmed <- str_split(andmed[i], pattern = '\n') %>%
                      unlist()
    
    # võtame ära '' elemendid
    temp_andmed <- temp_andmed[temp_andmed != '']
    
    # paneme andmed tabelisse
    df_boltmarket$Tootenimi[i] <- temp_andmed[2]
    df_boltmarket$Hind[i] <- temp_andmed[1]
    df_boltmarket$Hind_kg_kohta[i] <- temp_andmed[3]
    
  }

} else { # Kui tooteid ei ole
  
  df_boltmarket <- data.frame(
    Pood = 'Bolt Market Soola',
    Tootenimi = NA,
    Hind = NA,
    Hind_kg_kohta = NA,
    Hind_kliendikaardiga = NA)
  
}



## TULEMUS: df_boltmarket






#### Wolt Market Karlova ####

## Seame browseri valmis

# Lähme lehele

rem_driver$navigate("https://wolt.com/et/est/tartu/venue/wolt-market-karlova")
Sys.sleep(5)

# vajutame kinni popup akna, mis küsib küpsiste kasutamise kohta (ennem ei saa lehelt infot kätte)
cookie_button <- rem_driver$findElement(using = "css selector", value = "button[data-test-id='decline-button']")
rem_driver$executeScript("arguments[0].click();", list(cookie_button))

# otsime otsingu koha elemendi
search_button <- rem_driver$findElement(using = "css selector", value = "input[data-test-id='menu-search-input']")

# Saadame otsingu sõna ja Enter vajutuse otsingule
search_button$sendKeysToElement(list(otsingusõna, key = "enter"))

Sys.sleep(3)




## Võtame andmed

# kerime mööda lehekülge allapoole et võtta kõik andmed leheküljelt välja
prev_scroll_h <- 0
andmed_välja <- c()

while (TRUE){
  
  ## kui tuleb Error (stale element), siis jätkab kerimisega ikkagi
  ## Stale Element Error pidavat vahest kerimisel juhtuma, ei saa vältida (?)
  tryCatch({ 
     
    # defineerime elemendi mida mööda alla kerime
    scrollable <- rem_driver$findElement(using = "xpath", value = "//html")
      
    # kerime allapoole
    # NB! katsetes, kus kasutasin += 500 tundus, et mõned tooted jäid vahele!
    rem_driver$executeScript("arguments[0].scrollTop += 150;", list(scrollable))
      
    # võtame elemendid
    andmed <- rem_driver$findElements(using = "css selector", value = "div.cfwvv0d")
      
    # teeme need andmed tekstiks
    andmed_tekst <- lapply(andmed, function(x) x$getElementText()) %>%
      unlist()
      
    # paneme listi ja jätame ainult info alles, mis ei kordu
    andmed_välja <- c(andmed_välja, andmed_tekst) %>% unique()
      
    ## kontrollime, kas kõrgus on veel muutunud, kui enam ei muutu, siis oleme lõpus ja lõpetame tsükli
      
    # vaatame praegust 
    scroll_h <- rem_driver$executeScript("return arguments[0].scrollTop;", list(scrollable))
    print(scroll_h)
    # kontrollime kas kõrgus on muutunud
    if(unlist(scroll_h) == unlist(prev_scroll_h)) break
      
    # salvestame järgmisesks loopiks selle loopi kõrguse 
    prev_scroll_h <- scroll_h
  
  }, error = function(e){
    
    print('error. retry.')
    
  })  
    
}


## Andmete korrastamine

# teeme data frame-i andmete jaoks

df_woltmarket <- data.frame(
  Pood = rep('Wolt Market Karlova', length(andmed_välja)),
  Tootenimi = rep('', length(andmed_välja)),
  Hind = rep('', length(andmed_välja)),
  Hind_kg_kohta = rep('', length(andmed_välja)),
  Hind_kliendikaardiga = rep('', length(andmed_välja)))


# Käime andmed üle ja paneme tabelisse õigesse kohta 

for (i in 1:length(andmed_välja)) {
  
  # teeme toote stringi juppideks
  toode <- str_split(andmed_välja[i], pattern = '\n') %>%
              unlist()
  
  # kui toode on pärast split-i 4 pikkune, siis ei ole tootel allahindlust
  if (length(toode) == 4){
    
    df_woltmarket$Tootenimi[i] <- toode[2]
    df_woltmarket$Hind[i] <- toode[1]
    df_woltmarket$Hind_kg_kohta[i] <- toode[4]
    
  }
  
  # kui toode on pärast split-i 5 pikkune, siis on tootel allahindlust
  if (length(toode) == 5){
    
    df_woltmarket$Tootenimi[i] <- toode[3]
    df_woltmarket$Hind[i] <- toode[1]
    df_woltmarket$Hind_kg_kohta[i] <- toode[5]
    
  }
  
  # kui toode on pärast split-i 6 pikkune, siis on tootel allahindlust ja sõna 'Nädala %'
  if (length(toode) == 6){
    
    df_woltmarket$Tootenimi[i] <- toode[4]
    df_woltmarket$Hind[i] <- toode[1]
    df_woltmarket$Hind_kg_kohta[i] <- toode[6]
    
  }
  
}

# Juhul kui tooteid ei leitud teeme eraldi data frame-i

if (nrow(df_woltmarket) == 0) { 
  
  df_woltmarket <- data.frame(
    Pood = 'Wolt Market Karlova',
    Tootenimi = NA,
    Hind = NA,
    Hind_kg_kohta = NA,
    Hind_kliendikaardiga = NA)
  
}

# TULEMUS: df_woltmarket






#### ANDMETE KORRASTAMINE TABELIKS ####

# korrastame data frame, et oleks tabelid võimalik kokku panna

df_selver$Hind <- unlist(df_selver$Hind)
df_selver$Hind_kliendikaardiga <- unlist(df_selver$Hind_kliendikaardiga)


# paneme andmed kokku üheks dataframe-iks

df_tulemus <- bind_rows(df_selver, df_rimi, df_prisma, df_barbora, df_boltmarket, df_woltmarket)
df_tulemus

# võta € ja €/kg ja muud sümbolid ära hindade veergudes ja muudame väärtused numbriteks

df_tulemus$Hind <- str_replace_all(df_tulemus$Hind, ',', '.') %>%
                      str_remove_all('€') %>%
                      str_remove_all('~') %>%
                      str_remove_all('/tk') %>%
                      str_trim() %>%
                      as.numeric()

df_tulemus$Hind_kg_kohta <- str_replace_all(df_tulemus$Hind_kg_kohta, ',', '.') %>%
                              str_remove_all('€') %>%
                              str_remove_all('/kg') %>%
                              str_trim() %>%
                              as.numeric()

df_tulemus$Hind_kliendikaardiga <- str_replace_all(df_tulemus$Hind_kliendikaardiga, ',', '.') %>%
                                    str_remove_all('€') %>%
                                    str_remove_all('~') %>%
                                    str_remove_all('/tk') %>%
                                    str_trim() %>%
                                    as.numeric()

# Eemaldame tooted, kus Tootenimi on NA
# See juhtub, kui selles poes ei ole sellist toodet

bool <- is.na(df_tulemus$Tootenimi)
df_tulemus <- df_tulemus[!bool, ]


# paneme allahindluse ainukeseks hinnaks ning arvutame välja kilohinna 
# veebilehelt allahindluse kilohinda otse ei ole, kuid toote kaalu saab arvutada tavahinna ning tava-kilohinna järgi
# NB! see on hetkel vajalik ainult Selveri puhul!

for (i in 1:nrow(df_tulemus)){
  
  if (!is.na(df_tulemus$Hind_kliendikaardiga[i])){
    
    # defineerime (loetavuse jaoks) muutujad
    
    hind <- df_tulemus$Hind[i]
    kg_hind <- df_tulemus$Hind_kg_kohta[i]
    alla_hind <- df_tulemus$Hind_kliendikaardiga[i]
    
    
    # paneme allahindluse hinna pärishinnaks
    
    df_tulemus$Hind[i] <- df_tulemus$Hind_kliendikaardiga[i]
    
    
    # arvutame allahinnatud toote kilohinna: 
    # hind / kg_hind --> annab toote kilod
    # alla_hind * (hind / kg_hind) --> annab toote kilohinna
    
    df_tulemus$Hind_kg_kohta[i] <- alla_hind / (hind / kg_hind)
    
  }
  
}


# Paneme ridade nimed uuesti paika

rownames(df_tulemus) <- NULL

# Muudame veergude nimed ära - lisa hinnale € märk ja Hind_kg_kohta lisa €/kg 

colnames(df_tulemus) <- c('Pood', 'Tootenimi', 'Hind,€', 'Hind, €/kg', 'Kliendikaardiga,€')

# Kustutame veeru 'Kliendikaardiga,€' df_tulemus tabelist ära, sest see info on juba kantud hinna veergu

df_tulemus <- df_tulemus[,1:4]


# Kui ühtegi toodet ei leitud, siis paneme selle kohta märkme

if (nrow(df_tulemus) == 0) {
  
  df_tulemus <- data.frame(
    Pood = '',
    Tootenimi = 'Toode puudub kõigist poodidest',
    `Hind,€` = '',
    `Hind,€/kg` = '',
    `Kliendikaardiga,€` = '')
  
}



#### SULGEME BROWSERI ####

## Sulgeme browseri akna

rem_driver$close()



#### PANEME ANDMED CSV FAILI ####

# Salvestame CSV faili andmetega df_tulemus

write.csv(df_tulemus, paste0(here(), "/andmed/", otsingusõna, "_", Sys.Date(), ".csv"))








