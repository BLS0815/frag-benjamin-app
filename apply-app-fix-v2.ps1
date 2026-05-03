# ============================================================
# apply-app-fix-v2.ps1 - Disclaimer + Paywall + freeBadge + Migration
# ============================================================
# v2: Anker-Strings nutzen ASCII-only Platzhalter (__OE__, __EM__, ...);
# Sonderzeichen werden zur Laufzeit via [char] injiziert. Damit ist
# das Skript robust gegen jedes Datei-Encoding.
# Idempotent. Ausschliesslich String.Replace().
# ============================================================

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Read-Utf8 ([string]$p) { return [IO.File]::ReadAllText($p, [Text.UTF8Encoding]::new($false)) }
function Write-Utf8 ([string]$p, [string]$c) { [IO.File]::WriteAllText($p, $c, [Text.UTF8Encoding]::new($false)) }

# --- Sonderzeichen-Tabelle ----------------------------------
$U_oe   = [char]246      # o-Umlaut
$U_ae   = [char]228      # a-Umlaut
$U_ue   = [char]252      # u-Umlaut
$U_oeUp = [char]214      # O-Umlaut
$U_ss   = [char]223      # eszett
$U_eu   = [char]8364     # euro
$U_bx   = [char]9472     # box-drawing horizontal U+2500
$U_ldq  = [char]8222     # german opening quote (low-9)
$U_rdq  = [char]8220     # german closing quote (left double)
$U_em   = [char]8212     # em-dash
$U_en   = [char]8211     # en-dash
$U_arr  = [char]8594     # right arrow
$U_mid  = [char]183      # middle dot
$U_flagDE = [char]::ConvertFromUtf32(0x1F1E9) + [char]::ConvertFromUtf32(0x1F1EA)
$U_flagAT = [char]::ConvertFromUtf32(0x1F1E6) + [char]::ConvertFromUtf32(0x1F1F9)
$U_flagCH = [char]::ConvertFromUtf32(0x1F1E8) + [char]::ConvertFromUtf32(0x1F1ED)
$U_env    = [char]::ConvertFromUtf32(0x1F4E7)

function Subst([string]$s) {
    return $s.
        Replace('__OE__',     $U_oe).
        Replace('__AE__',     $U_ae).
        Replace('__UE__',     $U_ue).
        Replace('__OEUP__',   $U_oeUp).
        Replace('__SS__',     $U_ss).
        Replace('__EU__',     $U_eu).
        Replace('__BX__',     $U_bx).
        Replace('__LDQ__',    $U_ldq).
        Replace('__RDQ__',    $U_rdq).
        Replace('__EM__',     $U_em).
        Replace('__EN__',     $U_en).
        Replace('__ARR__',    $U_arr).
        Replace('__MID__',    $U_mid).
        Replace('__FLAGDE__', $U_flagDE).
        Replace('__FLAGAT__', $U_flagAT).
        Replace('__FLAGCH__', $U_flagCH).
        Replace('__ENV__',    $U_env)
}

$file = 'index.html'
if (-not (Test-Path $file)) {
    Write-Host "FEHLER: $file nicht gefunden im Repo-Root" -ForegroundColor Red
    exit 1
}

$h = Read-Utf8 $file

# === 1) Disclaimer-Modal HTML ================================
$discOld = Subst (@'
  <div class="modal-overlay" id="disclaimerOverlay">
    <div class="modal">
      <h2>Wichtiger Hinweis</h2>
      <p>Frag Benjamin teilt pers__OE__nliches Erfahrungswissen zu Narzissmus und toxischen Beziehungen. Diese App ersetzt keine Therapie, Rechtsberatung oder medizinische Behandlung.</p>
      <p><strong>Bei akuter Gefahr:</strong><br>
        Notruf <strong>112</strong><br>
        Telefonseelsorge <strong>0800 111 0 111</strong> (kostenlos, 24/7)
      </p>
      <button class="modal-btn" id="disclaimerOkBtn">Ich habe verstanden</button>
    </div>
  </div>
'@)

$discNew = Subst (@'
  <div class="modal-overlay" id="disclaimerOverlay" role="dialog" aria-modal="true" aria-labelledby="disclaimerTitle">
    <div class="modal disclaimer-modal">
      <h2 id="disclaimerTitle">Sch__OE__n, dass du hierher gefunden hast.</h2>
      <p>Frag Benjamin ist ein digitaler Begleiter, der auf den Inhalten meines Buches <em>__LDQ__Narzissmus verstehen __EM__ Schild statt Schwert__RDQ__</em> basiert. Er kann zuh__OE__ren, einordnen helfen und Fragen beantworten __EM__ anonym, jederzeit, ohne Anmeldung.</p>
      <p><strong>Wichtig:</strong> Frag Benjamin ist kein Ersatz f__UE__r eine Therapie oder professionelle Beratung. Wenn es dir gerade akut schlecht geht oder du in einer Krise steckst, ist menschlicher Beistand der richtige Weg.</p>
      <div class="disclaimer-crisis">
        <p><strong>Hilfe rund um die Uhr __EM__ kostenlos und anonym:</strong></p>
        <p>__FLAGDE__ <strong>Deutschland</strong> __EM__ Telefonseelsorge: <a href="tel:+498001110111">0800 111 0 111</a> __MID__ <a href="tel:+498001110222">0800 111 0 222</a> __MID__ <a href="tel:+49116123">116 123</a></p>
        <p>__FLAGAT__ <strong>__OEUP__sterreich</strong> __EM__ Telefonseelsorge: <a href="tel:+43142">142</a></p>
        <p>__FLAGCH__ <strong>Schweiz / Liechtenstein</strong> __EM__ Die Dargebotene Hand: <a href="tel:+41143">143</a></p>
      </div>
      <button class="modal-btn" id="disclaimerOkBtn">Ich habe verstanden __ARR__</button>
    </div>
  </div>
'@)

if ($h.Contains('id="disclaimerTitle"')) {
    Write-Host "SKIP Disclaimer-HTML (bereits gepatcht)" -ForegroundColor Cyan
} elseif ($h.Contains($discOld)) {
    $h = $h.Replace($discOld, $discNew)
    Write-Host "OK   Disclaimer-HTML ersetzt" -ForegroundColor Green
} else {
    Write-Host "WARN Disclaimer-HTML alter Block nicht gefunden" -ForegroundColor Yellow
}

# === 2) Paywall-Modal HTML ===================================
$payOld = Subst (@'
  <div class="modal-overlay paywall-modal hidden" id="paywallOverlay">
    <div class="modal">
      <h2>Dein Kontingent ist aufgebraucht</h2>
      <p>Du hast deine 5 kostenlosen Fragen genutzt. Mit dem vollst__AE__ndigen Zugang kannst du unbegrenzt fragen.</p>
      <div class="price">9,90 __EU__ / Monat</div>
      <ul>
        <li>Unbegrenzte Fragen</li>
        <li>Priorisierte Antworten</li>
        <li>Vollst__AE__ndiges Archiv</li>
        <li>Monatlich k__UE__ndbar</li>
      </ul>
      <button class="modal-btn" id="paywallBtn">Jetzt freischalten</button>
      <br><br>
      <button class="clear-btn" id="paywallCloseBtn">Schlie__SS__en</button>
    </div>
  </div>
'@)

$payNew = Subst (@'
  <div class="modal-overlay paywall-modal hidden" id="paywallOverlay" role="dialog" aria-modal="true" aria-labelledby="paywallTitle">
    <div class="modal">
      <h2 id="paywallTitle">Du hast deine 10 Gratisfragen aufgebraucht.</h2>
      <p>Ich freue mich, dass dir Frag Benjamin offenbar weiterhilft. Die Bezahlfunktion ist gerade im Aufbau und wird bald verf__UE__gbar sein.</p>
      <p>In der Zwischenzeit kannst du eine <strong>manuelle Freischaltung</strong> per E-Mail anfragen:</p>
      <p class="paywall-mail">__ENV__ <a href="mailto:b.lucas.s@web.de">b.lucas.s@web.de</a></p>
      <p>Schreib mir kurz, dass du gerne weiternutzen m__OE__chtest __EM__ ich melde mich zeitnah zur__UE__ck.</p>
      <p class="paywall-signature">__EM__ Benjamin</p>
      <button class="modal-btn" id="paywallCloseBtn">Schlie__SS__en</button>
      <button id="paywallBtn" hidden></button>
    </div>
  </div>
'@)

if ($h.Contains('id="paywallTitle"')) {
    Write-Host "SKIP Paywall-HTML (bereits gepatcht)" -ForegroundColor Cyan
} elseif ($h.Contains($payOld)) {
    $h = $h.Replace($payOld, $payNew)
    Write-Host "OK   Paywall-HTML ersetzt (paywallBtn bleibt als hidden)" -ForegroundColor Green
} else {
    Write-Host "WARN Paywall-HTML alter Block nicht gefunden" -ForegroundColor Yellow
}

# === 3) freeBadge ============================================
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

# === 4) Migration v2 ========================================
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

# === 5) Disclaimer-JS mit Key-Bump v2 + a11y ================
$discJsOld = Subst (@'
    // __BX____BX__ DISCLAIMER __BX____BX__
    if (!localStorage.getItem('fb_disclaimer_ok')) {
      disclaimerOverlay.classList.remove('hidden');
    } else {
      disclaimerOverlay.classList.add('hidden');
    }

    disclaimerOkBtn.addEventListener('click', () => {
      localStorage.setItem('fb_disclaimer_ok', '1');
      disclaimerOverlay.classList.add('hidden');
    });
'@)

$discJsNew = Subst (@'
    // __BX____BX__ DISCLAIMER (v2: Key-Bump zeigt aktualisiertes Modal auch Bestandsnutzern) __BX____BX__
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
'@)

if ($h.Contains('fb_disclaimer_ok_v2')) {
    Write-Host "SKIP Disclaimer-JS (bereits gepatcht)" -ForegroundColor Cyan
} elseif ($h.Contains($discJsOld)) {
    $h = $h.Replace($discJsOld, $discJsNew)
    Write-Host "OK   Disclaimer-JS ersetzt (a11y + Key-Bump v2)" -ForegroundColor Green
} else {
    Write-Host "WARN Disclaimer-JS alter Block nicht gefunden" -ForegroundColor Yellow
}

# === 6) CSS-Erweiterungen ===================================
$cssOld = Subst (@'
    .modal-btn:hover { background: var(--gold-light); }

    /* __BX____BX__ PAYWALL MODAL __BX____BX__ */
'@)

$cssNew = Subst (@'
    .modal-btn:hover { background: var(--gold-light); }

    /* __BX____BX__ DISCLAIMER MODAL __BX____BX__ */
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

    /* __BX____BX__ PAYWALL MODAL __BX____BX__ */
'@)

if ($h.Contains('.disclaimer-crisis')) {
    Write-Host "SKIP CSS-Block (bereits drin)" -ForegroundColor Cyan
} elseif ($h.Contains($cssOld)) {
    $h = $h.Replace($cssOld, $cssNew)
    Write-Host "OK   CSS-Block fuer Disclaimer + Paywall ergaenzt" -ForegroundColor Green
} else {
    Write-Host "WARN CSS-Anker (modal-btn:hover -> PAYWALL MODAL) nicht gefunden" -ForegroundColor Yellow
}

# === Schreiben ==============================================
Write-Utf8 $file $h

Write-Host ""
Write-Host "Fertig. Erwartete Ausgabe beim ersten Lauf:" -ForegroundColor Green
Write-Host "  OK Disclaimer-HTML, Paywall-HTML, freeBadge SKIP, Migration SKIP, Disclaimer-JS OK, CSS OK" -ForegroundColor Green
Write-Host ""
Write-Host "Erwartete Ausgabe beim zweiten Lauf (alles SKIP):" -ForegroundColor Green
Write-Host "  6x SKIP" -ForegroundColor Green