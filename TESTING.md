# TESTING - Trinkgeld-Modell

Branch: `feature/trinkgeld-modell`

## Vorbereitung

1. Server starten: `node server.js`
2. Browser offnen: `http://localhost:8080`
3. Browser-DevTools offnen: F12 → Tab "Application" → "Local Storage"
4. Vor jedem Testblock localStorage komplett leeren:
   DevTools → Application → Local Storage → Rechtsklick → "Clear"

---

## T01 - Initialisierung (neuer Nutzer)

**Ziel:** Beim ersten Besuch werden alle neuen Keys korrekt gesetzt und alte Keys geloscht.

**Schritte:**
1. localStorage leeren
2. Seite neu laden

**Erwartetes Ergebnis:**
- `trinkgeld_initialized` = `"true"`
- `trinkgeld_question_count` = `"0"`
- `trinkgeld_last_donate_click` = `"0"`
- `fb_freie_fragen` ist NICHT vorhanden
- `fb_migrated_v2` ist NICHT vorhanden
- Badge im Header zeigt "kostenlos"

---

## T02 - Initialisierung (Bestandsnutzer mit alten Keys)

**Ziel:** Harter Schnitt - alte Keys werden geloscht, Bestandsnutzer starten bei 0.

**Schritte:**
1. localStorage leeren
2. Manuell setzen: `fb_freie_fragen = "3"`, `fb_migrated_v2 = "1"`
3. Seite neu laden

**Erwartetes Ergebnis:**
- `trinkgeld_initialized` = `"true"`
- `trinkgeld_question_count` = `"0"` (NICHT aus fb_freie_fragen ubernommen)
- `fb_freie_fragen` ist NICHT mehr vorhanden
- `fb_migrated_v2` ist NICHT mehr vorhanden

---

## T03 - Zaehler: nur nach erfolgreicher API-Antwort

**Ziel:** `trinkgeld_question_count` wird nur hochgezahlt, wenn die API eine Antwort liefert.

**Schritte (Erfolgsfall):**
1. Frischen Zustand herstellen (T01)
2. Eine Frage stellen, auf Antwort warten

**Erwartetes Ergebnis:**
- `trinkgeld_question_count` = `"1"` nach Antwort
- Wahrend des Ladens (Loading-Dots sichtbar) ist der Wert noch `"0"`

**Schritte (Fehlerfall):**
1. Server stoppen (`Strg+C`)
2. Eine Frage stellen

**Erwartetes Ergebnis:**
- `trinkgeld_question_count` bleibt `"0"` - kein Inkrement bei Fehler

---

## T04 - Trigger bei Frage 7

**Ziel:** Pop-up erscheint nach der 7. erfolgreichen Antwort.

**Schritte:**
1. Frischen Zustand herstellen (T01)
2. Manuell setzen: `trinkgeld_question_count = "6"`
3. Eine Frage stellen, auf Antwort warten

**Erwartetes Ergebnis:**
- Pop-up erscheint nach der Antwort
- `trinkgeld_question_count` = `"7"`
- Pop-up zeigt zwei Buttons: "Spendieren (PayPal)" und "Vielleicht spater"
- Kein Schliessen-X sichtbar

---

## T05 - Trigger: kein Pop-up bei Frage 6 und 8

**Ziel:** Pop-up erscheint NUR bei Vielfachen von 7, nicht dazwischen.

**Schritte:**
1. `trinkgeld_question_count = "5"` setzen, Frage stellen → kein Pop-up (count wird 6)
2. `trinkgeld_question_count = "7"` setzen, Frage stellen → kein Pop-up (count wird 8)

**Erwartetes Ergebnis:** Kein Pop-up bei Frage 6 oder 8.

---

## T06 - "Vielleicht spater" ohne Cooldown

**Ziel:** Klick auf "Vielleicht spater" schliesst das Pop-up, setzt keinen Cooldown.

**Schritte:**
1. Pop-up offnen (T04)
2. "Vielleicht spater" klicken
3. `trinkgeld_last_donate_click` prufen
4. `trinkgeld_question_count = "13"` setzen, Frage stellen

**Erwartetes Ergebnis:**
- `trinkgeld_last_donate_click` = `"0"` (unverandert)
- Pop-up erscheint erneut bei Frage 14 (nachstes Vielfaches von 7)

---

## T07 - "Spendieren": Cooldown von 14 Fragen

**Ziel:** Nach Klick auf "Spendieren" erscheint das Pop-up fur 14 Fragen nicht.

**Schritte:**
1. Pop-up offnen (T04, count = 7)
2. "Spendieren (PayPal)" klicken
3. `trinkgeld_last_donate_click` prufen
4. `trinkgeld_question_count = "13"` setzen, Frage stellen (count wird 14)
5. `trinkgeld_question_count = "20"` setzen, Frage stellen (count wird 21)

**Erwartetes Ergebnis:**
- `trinkgeld_last_donate_click` = `"7"` nach Klick
- PayPal offnet sich in neuem Tab
- Bei Frage 14: kein Pop-up (14 - 7 = 7, kleiner als Cooldown 14)
- Bei Frage 21: Pop-up erscheint (21 - 7 = 14, Cooldown abgelaufen)

---

## T08 - ESC schliesst Pop-up NICHT

**Ziel:** ESC-Taste hat keine Wirkung, solange das Trinkgeld-Pop-up offen ist.

**Schritte:**
1. Pop-up offnen (T04)
2. ESC-Taste drucken

**Erwartetes Ergebnis:** Pop-up bleibt offen.

---

## T09 - Klick auf Overlay schliesst Pop-up NICHT

**Ziel:** Klick auf den dunklen Hintergrund hat keine Wirkung.

**Schritte:**
1. Pop-up offnen (T04)
2. Auf den dunklen Bereich ausserhalb der Modal-Box klicken

**Erwartetes Ergebnis:** Pop-up bleibt offen.

---

## T10 - Multi-Tab-Synchronisation

**Ziel:** Zaehler bleibt zwischen mehreren offenen Tabs konsistent.

**Schritte:**
1. App in Tab A und Tab B offnen (beide frischer Zustand)
2. In Tab A: 6 Fragen stellen (count = 6)
3. Tab B im Hintergrund lassen (nicht neu laden)
4. In Tab A: 7. Frage stellen (count = 7, Pop-up erscheint in Tab A)
5. Tab B aktiv machen

**Erwartetes Ergebnis:**
- `trinkgeld_question_count` in Tab B zeigt `"7"` (via storage-Event synchronisiert)
- Wird in Tab B eine weitere Frage gestellt, erscheint das Pop-up erst bei Frage 14

---

## T11 - PayPal-URL prufen

**Ziel:** Der "Spendieren"-Button offnet die richtige URL.

**Schritte:**
1. Pop-up offnen
2. "Spendieren (PayPal)" klicken
3. URL des neuen Tabs prufen

**Erwartetes Ergebnis:** `https://paypal.me/Schildstattschwert`

---

## T12 - Sende-Button immer "Frage stellen"

**Ziel:** Der Button zeigt nie mehr "Limit erreicht".

**Schritte:**
1. Beliebig viele Fragen stellen

**Erwartetes Ergebnis:**
- Button-Text ist immer "Frage stellen →"
- Badge im Header zeigt immer "kostenlos"

---

## T13 - Archiv und Disclaimer unverandert

**Ziel:** Bestehende Funktionen wurden nicht beschadigt.

**Schritte:**
1. Disclaimer-Modal beim ersten Besuch prufen → erscheint, "Ich habe verstanden" schliesst es
2. Fragen stellen, Archiv-Eintraege prufen
3. "Archiv loschen" prufen
4. Impressum und Datenschutz prufen

**Erwartetes Ergebnis:** Alle bestehenden Funktionen laufen wie zuvor.
