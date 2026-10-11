# NFLM Collection — besloten bèta (20–50 testers)

## Veilig ontwikkelproces
- `main` = publieke website. `develop` = ontwikkelbranch. Wijzigingen aan `main` uitsluitend via gecontroleerde pull request.
- De GitHub Action `Website quality checks` voert een minimale statische controle uit. Dit is **geen** volledige browser- of beveiligingstest.
- Stel in GitHub branch protection/rulesets voor `main` in: verplichte pull requests, verplichte geslaagde quality-check, geen force pushes. Dit vereist instellingen door de repo-eigenaar.
- Gebruik voor een aparte previewomgeving een aparte deployment of project. `develop` is op zichzelf geen publiek toegankelijke previewsite.
- Test na iedere wijziging handmatig: iPhone Safari, Android Chrome, inloggen/uitloggen, collectie opslaan/herladen, binder, vrienden, packs, terugnavigatie.

## Catalogus en kaartbetrouwbaarheid
- Verzamel alle kaartnummers per set rechtstreeks uit een betrouwbare catalogusbron; valideer lokale ID, set-ID, naam en rarity.
- Behandel ontbrekende API-data als *onbekend*, niet als bewijs dat een kaart niet bestaat.
- Leg legitieme uitzonderingen (promo's, talen, reprints) vast in een versiebeheerbare uitzonderingenlijst met bron.
- Genereer een afwijkingenrapport vóór wijzigingen. Verwijder nooit automatisch gebruikersbezit.
- Scheid fysieke collectie en virtuele gamecollectie; maak expliciet welke bron van waarheid elke binder gebruikt.

## Privacy en beveiliging — blokkerend vóór uitnodigingen
- Controleer Supabase Row Level Security (RLS) voor alle tabellen en policies; test met twee verschillende testaccounts dat geen privécollectie of profieldata ongewenst uitlekt.
- Controleer dat de browser uitsluitend een publishable/anon key bevat en nooit een service_role/secret key.
- Leg dataminimalisatie, privacyverklaring, verwijderverzoek en back-up/herstel vast; controleer AVG-vereisten.
- Gebruik testaccounts en fictieve gegevens in testomgeving. Geen productiegegevens kopiëren zonder passende waarborgen.
- Review afbeeldings-, merk- en databankrechten voor publieke exploitatie.

## Testfases
**Week 1 — technische basis:** automatische checks, branchregels, database-audit, veilige preview en herstelplan.
**Week 2 — catalogus:** automatische set-/kaart-/rarity-validatie, uitzonderingen, rapportage; geen automatische deletions.
**Week 3 — functioneel:** browser-e2e-tests, performance, mobiele UX, toegankelijkheid en foutmonitoring.
**Week 4 — besloten bèta:** eerst 5 interne testers, daarna 20, maximaal 50; meldpunt voor bugs en duidelijke privacyinformatie.

## Minimale go/no-go criteria
- Geen kritieke login-, dataverlies- of privacyproblemen.
- Basisflows slagen op iOS Safari en Android Chrome.
- Cataloguscontrole geeft expliciete dekking en onopgeloste afwijkingen; geen fictieve varianten.
- Back-up en restore aantoonbaar getest.
- Foutmeldingen kunnen veilig worden verzameld zonder persoonlijke data te lekken.
- Privacy- en rechtencontrole afgerond; verantwoordelijke en contactpunt bekend.

## Niet voltooid door dit document
Geen branch protection, previewdeployment, Supabase RLS-review, externe browsertests of uitnodigingsbeheer zijn hiermee automatisch ingericht.
