# Toiduainete hindade kammimine e-poodidest ja hindade analüüs

Meie perele meeldib süüa lõhet ja forelli. Aga nende hinnad kõiguvad oluliselt ning võivad olla väga kallid. 
Seega on küsimus - mis tooteid osta? ja mis poest neid tasub osta?

Kasutamine veebikammimise programmi, mis käib läbi e-poed, ja kammib kokku toitude hinnad. Programmi saab sisestada otsingusõna, mille järgi otsitakse kõik tooted nendes e-poodides ja pannakse tabelisse. Otsingu teostamiseks sisestatakse otsingusõna e-poe oma otsingusse ning saadud tulemused kammitakse.

Programm kasutab RSelenium paketti (selenium-server-standalone-3.5.3), ChromeDriverit (chromedriver-win64) ja Chrome brauserit.

Tulemused pannakse kasuda andmed faili nimega [otsingusõna]_[kuupäev].CSV

Tulemuseks saab tabeli järgnevate veergudega: 
* Pood
* Tootenimi
* Hind,€
* Hind,€/kg
* Kliendikaardiga,€

NB! Hind,€/kg antud väärtust ei pruugi olla €/kg vaid ka näiteks €/L või €/tk, olenevalt tootest.

Poed, kust kammitakse: 
* Prisma e-pood
* Rimi e-pood
* Selveri e-pood
* Barbora (Maxima e-pood)
* Bolt Market Soola (Tartu)
* Wolt Market Karlova (Tartu)

Pärast kammimist analüüsitakse saadud tulemusi Excelis, failis hinnaanalüüs.XLSX

## Tulemus lühidalt:

Tasub osta värsket lõhe või kuumsuitsutatud lõhe. Nende toodete hind ja kvaliteet tunduvad kõige paremad olevat.
Neid tooteid tasub vaadata Barborast ja Rimist, sest neil on madalaimad hinnad nendes kategooriates.

