# Drømmehuset

Et spill der du styler figurer, innreder huset, lager mat, får kjæledyr og barn, og reiser rundt i verden.

## Spill på iPhone og iPad

1. Åpne spillets adresse i Safari.
2. Trykk på Del-knappen.
3. Velg «Legg til på Hjem-skjerm».

Da ligger spillet på hjemskjermen som en app, åpnes i fullskjerm og virker også uten nett etter første gang.

## Filer

- `index.html` – selve spillet.
- `three.min.js` – 3D-biblioteket (three.js r128, MIT-lisens).
- `manifest.webmanifest`, `sw.js`, `icon-*.png` – gjør at spillet kan legges på hjemskjermen og virke uten nett.
- `dev/artifact.html` – samme spill, i versjonen som publiseres på claude.ai.

## iOS-appen (Swift)

Mappen `ios/` inneholder en egen iOS-app skrevet i Swift og SwiftUI.

1. Åpne `ios/Drommehuset.xcodeproj` i Xcode 16 eller nyere.
2. Velg ditt eget team under *Signing & Capabilities*.
3. Trykk Kjør.

Første versjon har Sminke, Hår, Klær, Pakke, åtte personer, mynter og lagring. Hus, Barn og Liv kommer i senere versjoner.
