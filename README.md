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

Appen har alle delene fra nettversjonen: Sminke, Hår, Klær, Hus, Barn, Liv og Pakke, åtte personer, mynter og lagring.

- Tegningene er de samme SVG-tegningene som i nettversjonen, tegnet med SwiftUI.
- 3D-huset i Liv er laget med SceneKit: to etasjer, trapp, venner og naboer som følger etter, barn, kjæledyr, mat, dusj, bad og søvn.
- Ute, bilturen, flyplassen, flyturen, reisemålene og dyrebutikken er tegnede scener.
- Lyd og musikk lages i appen (AVAudioEngine), som i nettversjonen.
