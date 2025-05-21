# Toiduainete hindade veebikammimine ja analüüs

Meie perele meeldib süüa lõhet ja forelli, kuid nende hinnad kõiguvad oluliselt ning võivad olla üllatavalt kõrged. 
Sellest tekkis küsimus: **kus poes ja mis kategoorias leidub kõige odavamaid tooteid**?

Sellele vastuse leidmiseks töötasin välja R-põhise veebikammimisprogrammi, mis kogub erinevate e-poodide andmeid ja võimaldab teha hindade analüüsi. Pärast andmete kogumist analüüsiti hindu Excelis.

## Projekti sisu

Veebikammimise programm võimaldab:
- Sisestada programmi otsingusõna (nt *lõhe*)
- Otsingusõna järgi tehakse e-poodidest otsing
- Otsingust leitud toodete kohta võetakse nimetused ja hinnad
- Leitud tulemused salvestatakse CSV faili nimega `otsingusõna_kuupäev.csv`, näiteks `lõhe_2025-05-18.csv`.

Kogutud andmed analüüsitakse Excelis (`hinnaanalüüs.xlsx`).

## Tehnoloogia

Veebikammimine on tehtud R-is, kasutades:
- `RSelenium` (selenium-server-standalone-3.5.3)
- `ChromeDriver` (chromedriver-win64)
- Chrome brauserit

Analüüs viidi läbi Excelis, kasutades järgmisi tööriistu::
- _Power Query_'t andmete Excelisse laadimiseks ning tabelite kombineerimiseks
- _Data Validation_ tööriista andmete kodeerimiseks
- _VLOOKUP_ funktsiooni andmetele koodide andmiseks
- _Pivor Table_ ja _Pivot Chart_ tööriistu, et analüüsida ja visualiseerida andmeid

### CSV faili veerud:

- `Pood`
- `Tootenimi`
- `Hind (€)`
- `Hind (€/kg)` *(NB! olenevalt tootest võib €/kg kohta tähendada näiteks €/L või €/tk)*

## Kammimise allikad

Andmeid kogutakse järgmistest poodidest:
- Prisma e-pood
- Rimi e-pood
- Selveri e-pood
- Barbora (Maxima e-pood)
- Bolt Market Soola (Tartu)
- Wolt Market Karlova (Tartu)

Selle analüüsi jaoks koguti andmeid 01.05 kuni 16.05.2025 (andmed asuvad kasutas `/andmed`).

## Peamised järeldused

- **Parim tootegatekooria:** värske lõhe ja kuumsuitsulõhe, kuna nende toodete hinna ja kvaliteedi suhe on parim
- **Parimad poed:** Barbora ja Rimi - nendes poodides olid antud kategooria tooted kõige soodsama hinnaga võrreldes teiste e-poodidega

## Kuidas kasutada

1. Installi vajalikud paketid ja Selenium server
2. Käivita veebikammimisprogramm R-is
3. Sisesta otsingusõna
4. Vaata väljundfaili ja tee analüüs

## Litsents

Projekt on avalikuks kasutamiseks (MIT litsents, vt. faili `LISENCE`). Jaga ja kohanda vastavalt oma vajadustele!

---

*See projekt sündis praktilisest vajadusest, aga võib olla kasulik ka teistele, kes soovivad võrrelda hindasid e-poodides ja valida nutikamalt, kust oma toidukraam osta.*
