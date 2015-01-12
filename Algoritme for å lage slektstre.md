# Algoritme for å lage slektstre

Slektstreet er sentrert rundt et forhold (eller en enkeltperson).
Utgangspunktet er at eldre generasjoner skal plasseres oppover og yngre generasjoner skal plasseres nedover.
Algoritmen kan selvfølgelig "roteres" for å istedenfor lage et "pedigree"-diagram.

 1. Lag hver person for seg (navn, fødselsdato, dødsdato). Sett Y-posisjon til årstallet de antas å være født. Alle personer i grafen må ha et antatt fødselsår - grafen må preprosesseres for å beregne disse årene, og kan for eksempel ta hensyn til gjennsomsnittlig levealder for menn og kvinner i de gitte tidsepokene, samt gjennomsnittlig alder for mødre ved fødsel.
 2. Lag boks av alle forhold. Det vil si; legg person-boksene inntil hverandre inni en ny boks. Foretrekk å plassere mannen på venstre side og kona på høyre side. Hvis en person er i flere forhold så skal personen vises med en dempet fargetone dersom et av de andre forholdene personen har vært i er nærmere senterforholdet i grafen enn dette.
 3. Forfedre
   3.1. Plasser alle 