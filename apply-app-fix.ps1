# ============================================================
# apply-app-fix.ps1 - Disclaimer + Paywall + freeBadge + Migration
# ============================================================
# Idempotent: kann mehrfach laufen, dupliziert nichts.
# Reine String.Replace(), kein Regex.
# ============================================================
# WICHTIG: Wenn dein Chat-UI beim Kopieren aus 'b.lucas.s@web.de'
# automatisch '[b.lucas.s@web.de](mailto:b.lucas.s@web.de)' macht,
# bitte die Markdown-Links im Skript-Text manuell entfernen, bevor
# du es speicherst. Nach Speichern in VS Code: Strg+F nach
# '](mailto:'  -> 0 Treffer erwartet.
# ============================================================

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Read-Utf8 ([string]$p) {
    return [IO.File]::ReadAllText($p, [Text.UTF8Encoding]::new($false))
}
function Write-Utf8 ([string]$p, [string]$c) {
    [IO.File]::WriteAllText($p, $c, [Text.UTF8Encoding]::new($false))
}

$file = 'index.html'
if (-not (Test-Path $file)) {
    Write-Host "FEHLER: $file nicht gefunden im Repo-Root" -ForegroundColor Red
    exit 1
}

$h = Read-Utf8 $file

# === 1) Disclaimer-Modal HTML ================================
$discOld = @'
  <div class="modal-overlay" id="disclaimerOverlay">
    <div class="modal">
      <h2>Wichtiger Hinweis</h2>
      <p>Frag Benjamin teilt persönliches Erfahrungswissen zu Narzissmus und toxischen Beziehungen. Diese App ersetzt keine Therapie, Rechtsberatung oder medizinische Behandlung.</p>
      <p><strong>Bei akuter Gefahr:</strong><br>
        Notruf <strong>112</strong><br>
        Telefonseelsorge <strong>0800 111 0 111</strong> (kostenlos, 24/7)
      </p>
      <button class="modal-btn" id="disclaimerOkBtn">Ich habe verstanden</button>
    </div>
  </div>
'@

$discNew = @'
  <div class="modal-overlay" id="disclaimerOverlay" role="dialog" aria-modal="true" aria-labelledby="disclaimerTitle">
    <div class="modal disclaimer-modal">
      <h2 id="disclaimerTitle">Schön, dass du hierher gefunden hast.</h2>
      <p>Frag Benjamin ist ein digitaler Begleiter, der auf den Inhalten meines Buches <em>„Narzissmus verstehen — Schild statt Schwert"</em> basiert. Er kann zuhören, einordnen helfen und Fragen beantworten — anonym, jederzeit, ohne Anmeldung.</p>
      <p><strong>Wichtig:</strong> Frag Benjamin ist kein Ersatz für eine Therapie oder professionelle Beratung. Wenn es dir gerade akut schlecht geht oder du in einer Krise steckst, ist menschlicher Beistand der richtige Weg.</p>
      <div class="disclaimer-crisis">
        <p><strong>Hilfe rund um die Uhr — kostenlos und anonym:</strong></p>
        <p>🇩🇪 <strong>Deutschland</strong> — Telefonseelsorge: <a href="tel:+498001110111">0800 111 0 111</a> · <a href="tel:+498001110222">0800 111 0 222</a> · <a href="tel:+49116123">116 123</a></p>
        <p>🇦🇹 <strong>Österreich</strong> — Telefonseelsorge: <a href="tel:+43142">142</a></p>
        <p>🇨🇭 <strong>Schweiz / Liechtenstein</strong> — Die Dargebotene Hand: <a href="tel:+41143">143</a></p>
      </div>
      <button class="modal-btn" id="disclaimerOkBtn">Ich habe verstanden →</button>
    </div>
  </div>
'@

if ($h.Contains('id="disclaimerTitle"')) {
    Write-Host "SKIP Disclaimer-HTML (bereits gepatcht)" -ForegroundColor Cyan
} elseif ($h.Contains($discOld)) {
    $h = $h.Replace($discOld, $discNew)
    Write-Host "OK   Disclaimer-HTML ersetzt" -ForegroundColor Green
} else {
    Write-Host "WARN Disclaimer-HTML alter Block nicht gefunden" -ForegroundColor Yellow
}

# === 2) Paywall-Modal HTML ===================================
# paywallBtn bleibt als hidden-Button im DOM, damit der vorhandene
# JS-Listener nicht crasht. Nutzer sieht ihn nie.
$payOld = @'
  <div class="modal-overlay paywall-modal hidden" id="paywallOverlay">
    <div class="modal">
      <h2>Dein Kontingent ist aufgebraucht</h2>
      <p>Du hast deine 5 kostenlosen Fragen genutzt. Mit dem vollständigen Zugang kannst du unbegrenzt fragen.</p>
      <div class="price">9,90 € / Monat</div>
      <ul>
        <li>Unbegrenzte Fragen</li>
        <li>Priorisierte Antworten</li>
        <li>Vollständiges Archiv</li>
        <li>Monatlich kündbar</li>
      </ul>
      <button class="modal-btn" id="paywallBtn">Jetzt freischalten</button>
      <br><br>
      <button class="clear-btn" id="paywallCloseBtn">Schließen</button>
    </div>
  </div>
'@

$payNew = @'
  <div class="modal-overlay paywall-modal hidden" id="paywallOverlay" role="dialog" aria-modal="true" aria-labelledby="paywallTitle">
    <div class="modal">
      <h2 id="paywallTitle">Du hast deine 10 Gratisfragen aufgebraucht.</h2>
      <p>Ich freue mich, dass dir Frag Benjamin offenbar weiterhilft. Die Bezahlfunktion ist gerade im Aufbau und wird bald verfügbar sein.</p>
      <p>In der Zwischenzeit kannst du eine <strong>manuelle Freischaltung</strong> per E-Mail anfragen:</p>
      <p class="paywall-mail">📧 <a href="mailto:b.lucas.s@web.de">b.lucas.s@web.de</a></p>
      <p>Schreib mir kurz, dass du gerne weiternutzen möchtest — ich melde mich zeitnah zurück.</p>
      <p class="paywall-signature">— Benjamin</p>
      <button class="modal-btn" id="paywallCloseBtn">Schließen</button>
      <button id="paywallBtn" hidden></button>
    </div>
  </div>
'@

if ($h.Contains('id="paywallTitle"')) {
    Write-Host "SKIP Paywall-HTML (bereits gepatcht)" -ForegroundColor Cyan
} elseif ($h.Contains($payOld)) {
    $h = $h.Replace($payOld, $payNew)
    Write-Host "OK   Paywall-HTML ersetzt (paywallBtn bleibt als hidden)" -ForegroundColor Green
} else {
    Write-Host "WARN Paywall-HTML alter Block nicht gefunden" -ForegroundColor Yellow
}

# === 3) freeBadge: 5 gratis -> 10 gratis =====================
$badgeOld = '<div class="free-badge" id="freeBadge">5 gratis</div>'
$badgeNew = '<div class="free-badge" id="freeBadge">10 gratis</div>'
if ($h.Contains($badgeNew)) {
    Write-Host "SKIP freeBadge (bereits 10)" -ForegroundColor Cyan
} elseif ($h.Contains($badgeOld)) {
    $h = $h.Replace($badgeOld, $badgeNew)
    Write-Host "OK   freeBadge auf 10 gesetzt" -ForegroundColor Green
} else {
    Write-Host "WARN freeBadge: weder alte (5) noch neue (10) Form gefunden" -ForegroundColor Yellow
}

# === 4) Migration v2 vor freieFragen-Init ====================
$migOld = "    let freieFragen = parseInt(localStorage.getItem('fb_freie_fragen') ?? MAX_FREE, 10);"
$migNew = @'
    // Migration v2: Bestandsnutzer (frueheres Limit 5) einmalig auf neues MAX_FREE anheben.
    if (!localStorage.getItem('fb_migrated_v2')) {
      const _stored = parseInt(localStorage.getItem('fb_freie_fragen') ?? MAX_FREE, 10);
      if (_stored < MAX_FREE) {
        localStorage.setItem('fb_freie_fragen', MAX_FREE);
      }
      localStorage.setItem('fb_migrated_v2', '1');
    }
    let freieFragen = parseInt(localStorage.getItem('fb_freie_fragen') ?? MAX_FREE, 10);
'@

if ($h.Contains('fb_migrated_v2')) {
    Write-Host "SKIP Migration v2 (bereits drin)" -ForegroundColor Cyan
} elseif ($h.Contains($migOld)) {
    $h = $h.Replace($migOld, $migNew)
    Write-Host "OK   Migration v2 vor freieFragen-Init eingefuegt" -ForegroundColor Green
} else {
    Write-Host "WARN Migration: freieFragen-Init-Zeile nicht gefunden" -ForegroundColor Yellow
}

# === 5) Disclaimer-Logik mit Key-Bump v2 + a11y ==============
$discJsOld = @'
    // ── DISCLAIMER ──
    if (!localStorage.getItem('fb_disclaimer_ok')) {
      disclaimerOverlay.classList.remove('hidden');
    } else {
      disclaimerOverlay.classList.add('hidden');
    }

    disclaimerOkBtn.addEventListener('click', () => {
      localStorage.setItem('fb_disclaimer_ok', '1');
      disclaimerOverlay.classList.add('hidden');
    });
'@

$discJsNew = @'
    // ── DISCLAIMER (v2: Key-Bump zeigt aktualisiertes Modal auch Bestandsnutzern) ──
    let _disclaimerLastFocus = null;
    function openDisclaimer() {
      _disclaimerLastFocus = document.activeElement;
      disclaimerOverlay.classList.remove('hidden');
      setTimeout(function () { disclaimerOkBtn.focus(); }, 0);
    }
    function closeDisclaimer() {
      localStorage.setItem('fb_disclaimer_ok_v2', '1');
      disclaimerOverlay.classList.add('hidden');
      if (_disclaimerLastFocus && _disclaimerLastFocus.focus) {
        _disclaimerLastFocus.focus();
      }
    }
    if (!localStorage.getItem('fb_disclaimer_ok_v2')) {
      openDisclaimer();
    } else {
      disclaimerOverlay.classList.add('hidden');
    }

    disclaimerOkBtn.addEventListener('click', closeDisclaimer);

    // Esc-Taste blockieren + einfacher Fokus-Trap solange Disclaimer offen ist
    document.addEventListener('keydown', function (e) {
      if (disclaimerOverlay.classList.contains('hidden')) return;
      if (e.key === 'Escape') { e.preventDefault(); return; }
      if (e.key === 'Tab') {
        e.preventDefault();
        disclaimerOkBtn.focus();
      }
    });
'@

if ($h.Contains('fb_disclaimer_ok_v2')) {
    Write-Host "SKIP Disclaimer-JS (bereits gepatcht)" -ForegroundColor Cyan
} elseif ($h.Contains($discJsOld)) {
    $h = $h.Replace($discJsOld, $discJsNew)
    Write-Host "OK   Disclaimer-JS ersetzt (a11y + Key-Bump v2)" -ForegroundColor Green
} else {
    Write-Host "WARN Disclaimer-JS alter Block nicht gefunden" -ForegroundColor Yellow
}

# === 6) CSS-Erweiterungen fuer Disclaimer + Paywall ==========
$cssOld = @'
    .modal-btn:hover { background: var(--gold-light); }

    /* ── PAYWALL MODAL ── */
'@

$cssNew = @'
    .modal-btn:hover { background: var(--gold-light); }

    /* ── DISCLAIMER MODAL ── */
    .disclaimer-modal h2 { font-size: 1.25rem; line-height: 1.4; }
    .disclaimer-crisis {
      margin-top: 1.5rem;
      padding-top: 1.25rem;
      border-top: 1px solid var(--gold-dim);
    }
    .disclaimer-crisis p { font-size: 0.9rem; margin-bottom: 0.5rem; line-height: 1.6; }
    .disclaimer-crisis a {
      color: var(--gold);
      text-decoration: none;
      font-weight: bold;
    }
    .disclaimer-crisis a:hover { text-decoration: underline; }
    .paywall-mail {
      background: var(--bg);
      border: 1px solid var(--gold-dim);
      border-radius: 8px;
      padding: 0.75rem 1rem;
      text-align: center;
      margin: 1rem 0 !important;
    }
    .paywall-mail a {
      color: var(--gold);
      text-decoration: none;
      font-weight: bold;
    }
    .paywall-mail a:hover { text-decoration: underline; }
    .paywall-signature {
      color: var(--text-muted);
      font-style: italic;
      text-align: right;
      margin-top: 1rem !important;
    }

    /* ── PAYWALL MODAL ── */
'@

if ($h.Contains('.disclaimer-crisis')) {
    Write-Host "SKIP CSS-Block (bereits drin)" -ForegroundColor Cyan
} elseif ($h.Contains($cssOld)) {
    $h = $h.Replace($cssOld, $cssNew)
    Write-Host "OK   CSS-Block für Disclaimer + Paywall ergänzt" -ForegroundColor Green
} else {
    Write-Host "WARN CSS-Anker (modal-btn:hover -> PAYWALL MODAL) nicht gefunden" -ForegroundColor Yellow
}

# === Schreiben ===============================================
Write-Utf8 $file $h

Write-Host ""
Write-Host "Fertig. Test-Checkliste:" -ForegroundColor Green
Write-Host ""
Write-Host "A) Inkognito-Browser (frischer localStorage):"
Write-Host "   1. Disclaimer mit Buchtitel kursiv + DACH-Notrufen sichtbar?"
Write-Host "   2. Telefonnummern als Gold-Links anklickbar?"
Write-Host "   3. Esc-Taste schliesst NICHT?"
Write-Host "   4. Klick auf Hintergrund schliesst NICHT?"
Write-Host "   5. 'Ich habe verstanden ->' schliesst Modal?"
Write-Host "   6. Hard-Reload: Modal NICHT mehr da?"
Write-Host "   7. 'gratis'-Badge zeigt 10?"
Write-Host ""
Write-Host "B) Normaler Browser (Bestandsnutzer mit altem Disclaimer):"
Write-Host "   1. Modal erscheint trotz frueherer Bestaetigung (Key-Bump v2)?"
Write-Host "   2. 'gratis'-Badge: bei Bestandswert <10 jetzt 10?"
Write-Host ""
Write-Host "C) Paywall testen (DevTools Console):"
Write-Host "   localStorage.setItem('fb_freie_fragen','0'); location.reload();"
Write-Host "   1. Send-Button zeigt 'Limit erreicht'."
Write-Host "   2. Frage stellen -> Paywall mit neuem Text + mailto-Link?"
Write-Host "   3. Schliessen-Button funktioniert?"
Write-Host ""
Write-Host "D) Aufraeumen (DevTools Console):"
Write-Host "   localStorage.clear(); location.reload();"